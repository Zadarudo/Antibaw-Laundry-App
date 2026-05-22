import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'tambah_transaksi_screen.dart';

const _primary = Color(0xFF8B2E6E);

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.of(_all)
          : _all.where((t) {
              return (t['nomor_invoice'] as String? ?? '')
                      .toLowerCase()
                      .contains(q) ||
                  (t['nama_pelanggan'] as String? ?? '')
                      .toLowerCase()
                      .contains(q) ||
                  ((t['pelanggan'] as Map?)?['nama'] as String? ?? '')
                      .toLowerCase()
                      .contains(q);
            }).toList();
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getTransaksi();
      if (mounted) {
        setState(() { _all = data; _isLoading = false; });
        _filter();
      }
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); _showError('$e'); }
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));

  Future<void> _delete(String id, String invoice) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: Text('Hapus transaksi $invoice?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SupabaseService().deleteTransaksi(id);
      _load();
    } catch (e) { _showError('Gagal menghapus: $e'); }
  }

  void _showDetail(Map<String, dynamic> trx) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransaksiDetailScreen(trxId: trx['id'].toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Transaksi'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Transaksi Baru'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahTransaksiScreen()),
          );
          _load();
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari invoice atau pelanggan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final t = _filtered[i];
                            return _TransaksiCard(
                              item: t,
                              onTap: () => _showDetail(t),
                              onDelete: () => _delete(
                                  t['id'].toString(),
                                  t['nomor_invoice'] ?? ''),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada transaksi',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Tap tombol di bawah untuk transaksi baru',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
}

// ── Transaction Card ──────────────────────────────────────────

class _TransaksiCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransaksiCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pelangganNama = (item['pelanggan'] as Map?)?['nama'] as String? ??
        item['nama_pelanggan'] as String? ?? 'Umum';
    final totalBayar = (item['total_bayar'] as num?)?.toInt() ?? 0;
    final rawDate = item['created_at'] as String?;
    String dateStr = '-';
    if (rawDate != null) {
      try {
        dateStr = DateFormat('d MMM yyyy, HH:mm', 'id')
            .format(DateTime.parse(rawDate).toLocal());
      } catch (_) {}
    }
    final status = item['status'] as String? ?? 'selesai';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: const BoxDecoration(
                  color: _primary,
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nomor_invoice'] ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Row(children: [
                              Icon(Icons.person_outline,
                                  size: 13,
                                  color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(pelangganNama,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13)),
                            ]),
                            const SizedBox(height: 2),
                            Text(dateStr,
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _fmtRp(totalBayar),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _primary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'selesai'
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: status == 'selesai'
                                      ? Colors.green.shade300
                                      : Colors.orange.shade300),
                            ),
                            child: Text(
                              status[0].toUpperCase() + status.substring(1),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: status == 'selesai'
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onDelete,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtRp(int v) {
  final f = NumberFormat('#,##0', 'id');
  return 'Rp ${f.format(v).replaceAll(',', '.')}';
}

// ════════════════════════════════════════════════════════════
// TRANSACTION DETAIL SCREEN
// ════════════════════════════════════════════════════════════

class TransaksiDetailScreen extends StatefulWidget {
  final String trxId;
  const TransaksiDetailScreen({super.key, required this.trxId});

  @override
  State<TransaksiDetailScreen> createState() => _TransaksiDetailScreenState();
}

class _TransaksiDetailScreenState extends State<TransaksiDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await SupabaseService().getTransaksiDetail(widget.trxId);
      if (mounted) setState(() { _data = d; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_data == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Transaksi'),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    final d = _data!;
    final items = (d['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final pelangganNama = (d['pelanggan'] as Map?)?['nama'] as String? ??
        d['nama_pelanggan'] as String? ?? 'Umum';
    final rawDate = d['created_at'] as String?;
    String dateStr = '-';
    if (rawDate != null) {
      try {
        dateStr = DateFormat('d MMMM yyyy, HH:mm', 'id')
            .format(DateTime.parse(rawDate).toLocal());
      } catch (_) {}
    }
    final totalHarga = (d['total_harga'] as num?)?.toInt() ?? 0;
    final diskon = (d['diskon_jumlah'] as num?)?.toInt() ?? 0;
    final totalBayar = (d['total_bayar'] as num?)?.toInt() ?? 0;
    final diskonPersen = (d['diskon_persen'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice header card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(d['nomor_invoice'] ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _primary)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: Colors.green.shade300),
                          ),
                          child: Text('Selesai',
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _infoRow(Icons.person_outline, 'Pelanggan', pelangganNama),
                    const SizedBox(height: 4),
                    _infoRow(Icons.calendar_today, 'Tanggal', dateStr),
                    if ((d['catatan'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      _infoRow(Icons.notes, 'Catatan', d['catatan']),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Items
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Item',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const Divider(),
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['nama_produk'] ?? '-',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    Text(
                                      '${item['quantity']} ${item['satuan']} × ${_fmtRp((item['harga'] as num?)?.toInt() ?? 0)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _fmtRp((item['subtotal'] as num?)?.toInt() ?? 0),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )),
                    const Divider(),
                    _summaryRow('Subtotal', totalHarga),
                    if (diskon > 0)
                      _summaryRow(
                          'Diskon ($diskonPersen%)', -diskon,
                          color: Colors.red),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bayar',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(_fmtRp(totalBayar),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      );

  Widget _summaryRow(String label, int amount, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            Text(
              amount < 0
                  ? '- ${_fmtRp(-amount)}'
                  : _fmtRp(amount),
              style: TextStyle(
                  fontSize: 13,
                  color: color ?? Colors.black87,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
}

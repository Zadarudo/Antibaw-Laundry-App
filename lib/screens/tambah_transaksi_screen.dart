import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

const _primary = Color(0xFF8B2E6E);

// ── Cart item model ───────────────────────────────────────────

class _CartItem {
  final String produkId;
  final String nama;
  final int harga;
  final String satuan;
  double quantity;

  _CartItem({
    required this.produkId,
    required this.nama,
    required this.harga,
    required this.satuan,
  }) : quantity = 1;

  int get subtotal => (harga * quantity).round();
}

// ════════════════════════════════════════════════════════════
// TAMBAH TRANSAKSI SCREEN  —  POS
// ════════════════════════════════════════════════════════════

class TambahTransaksiScreen extends StatefulWidget {
  const TambahTransaksiScreen({super.key});

  @override
  State<TambahTransaksiScreen> createState() => _TambahTransaksiScreenState();
}

class _TambahTransaksiScreenState extends State<TambahTransaksiScreen> {
  // data
  List<Map<String, dynamic>> _produkAll = [];
  List<Map<String, dynamic>> _produkFiltered = [];
  List<Map<String, dynamic>> _pelangganList = [];
  List<Map<String, dynamic>> _promoList = [];

  // cart
  final List<_CartItem> _cart = [];

  // form
  final _searchProdukCtrl = TextEditingController();
  final _namaPelangganCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  String? _selectedPelangganId;
  Map<String, dynamic>? _selectedPromo;
  int _diskonManual = 0; // percent
  bool _useManualDiskon = false;

  bool _loadingProduk = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchProdukCtrl.addListener(_filterProduk);
  }

  @override
  void dispose() {
    _searchProdukCtrl.dispose();
    _namaPelangganCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final produk = await SupabaseService().getProdukLayanan();
      final pelanggan = await SupabaseService().getPelanggan();
      final promo = await SupabaseService().getPromo();
      if (mounted) {
        setState(() {
          _produkAll = produk;
          _produkFiltered = produk;
          _pelangganList = pelanggan;
          _promoList = promo
              .where((p) =>
                  (p['is_active'] as bool? ?? false) && !_isPromoExpired(p))
              .toList();
          _loadingProduk = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingProduk = false);
    }
  }

  bool _isPromoExpired(Map<String, dynamic> p) {
    final raw = p['tanggal_selesai'] as String?;
    if (raw == null) return false;
    try {
      final d = DateTime.parse(raw);
      final today = DateTime.now();
      return d.isBefore(DateTime(today.year, today.month, today.day));
    } catch (_) {
      return false;
    }
  }

  void _filterProduk() {
    final q = _searchProdukCtrl.text.toLowerCase();
    setState(() {
      _produkFiltered = q.isEmpty
          ? _produkAll
          : _produkAll.where((p) {
              return (p['nama'] as String? ?? '').toLowerCase().contains(q) ||
                  ((p['kategori_layanan'] as Map?)?['nama'] as String? ?? '')
                      .toLowerCase()
                      .contains(q);
            }).toList();
    });
  }

  // ── Cart logic ──────────────────────────────────────────────

  void _addToCart(Map<String, dynamic> produk) {
    final id = produk['id'].toString();
    final existing = _cart.indexWhere((c) => c.produkId == id);
    setState(() {
      if (existing >= 0) {
        _cart[existing].quantity += 1;
      } else {
        _cart.add(_CartItem(
          produkId: id,
          nama: produk['nama'] ?? '-',
          harga: (produk['harga'] as num?)?.toInt() ?? 0,
          satuan: produk['satuan'] ?? 'pcs',
        ));
      }
    });
  }

  void _removeFromCart(int index) =>
      setState(() => _cart.removeAt(index));

  void _updateQty(int index, double qty) {
    if (qty <= 0) {
      _removeFromCart(index);
    } else {
      setState(() => _cart[index].quantity = qty);
    }
  }

  // ── Totals ──────────────────────────────────────────────────

  int get _subtotal =>
      _cart.fold(0, (s, c) => s + c.subtotal);

  int get _effectiveDiskonPersen {
    if (_useManualDiskon) return _diskonManual;
    if (_selectedPromo != null) {
      return (_selectedPromo!['diskon'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  int get _diskonJumlah =>
      (_subtotal * _effectiveDiskonPersen / 100).round();

  int get _total => _subtotal - _diskonJumlah;

  // ── Save ────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu item')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final items = _cart
          .map((c) => {
                'produk_id': c.produkId,
                'nama_produk': c.nama,
                'harga': c.harga,
                'quantity': c.quantity,
                'satuan': c.satuan,
                'subtotal': c.subtotal,
              })
          .toList();

      final namaPelanggan = _namaPelangganCtrl.text.trim().isNotEmpty
          ? _namaPelangganCtrl.text.trim()
          : null;

      final invoice = await SupabaseService().createTransaksi(
        pelangganId: _selectedPelangganId,
        namaPelanggan: namaPelanggan,
        items: items,
        diskonPersen: _effectiveDiskonPersen,
        catatan: _catatanCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaksi $invoice berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Baru'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loadingProduk
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Pilih Produk'),
                        const SizedBox(height: 8),
                        _produkPicker(),
                        const SizedBox(height: 20),
                        _sectionTitle('Keranjang'),
                        const SizedBox(height: 8),
                        _cartSection(),
                        const SizedBox(height: 20),
                        _sectionTitle('Pelanggan'),
                        const SizedBox(height: 8),
                        _pelangganSection(),
                        const SizedBox(height: 20),
                        _sectionTitle('Diskon'),
                        const SizedBox(height: 8),
                        _diskonSection(),
                        const SizedBox(height: 20),
                        _sectionTitle('Catatan'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _catatanCtrl,
                          decoration: _dec('Catatan (opsional)'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        _summaryCard(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                _bottomBar(),
              ],
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));

  // ── Product picker ──────────────────────────────────────────

  Widget _produkPicker() => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchProdukCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 8),
              if (_produkFiltered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Tidak ada produk',
                      style: TextStyle(color: Colors.grey.shade500)),
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _produkFiltered.length,
                    itemBuilder: (_, i) {
                      final p = _produkFiltered[i];
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        title: Text(p['nama'] ?? '-',
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          _fmtRp((p['harga'] as num?)?.toInt() ?? 0) +
                              ' / ${p['satuan']}',
                          style: const TextStyle(
                              fontSize: 12, color: _primary),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: _primary),
                          onPressed: () => _addToCart(p),
                        ),
                        onTap: () => _addToCart(p),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );

  // ── Cart ─────────────────────────────────────────────────────

  Widget _cartSection() {
    if (_cart.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text('Keranjang kosong — tambahkan produk di atas',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
      );
    }
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _cart.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => _CartTile(
          item: _cart[i],
          onRemove: () => _removeFromCart(i),
          onQtyChanged: (q) => _updateQty(i, q),
        ),
      ),
    );
  }

  // ── Pelanggan ─────────────────────────────────────────────

  Widget _pelangganSection() => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedPelangganId,
                decoration: _dec('Pilih dari daftar pelanggan'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Pelanggan Umum')),
                  ..._pelangganList.map((p) => DropdownMenuItem(
                        value: p['id'].toString(),
                        child: Text(p['nama'] ?? '-'),
                      )),
                ],
                onChanged: (v) {
                  setState(() {
                    _selectedPelangganId = v;
                    if (v != null) {
                      final pel = _pelangganList
                          .firstWhere((p) => p['id'].toString() == v);
                      _namaPelangganCtrl.text = pel['nama'] ?? '';
                    } else {
                      _namaPelangganCtrl.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _namaPelangganCtrl,
                decoration: _dec('Atau ketik nama pelanggan'),
              ),
            ],
          ),
        ),
      );

  // ── Diskon ────────────────────────────────────────────────

  Widget _diskonSection() => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _useManualDiskon = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_useManualDiskon
                              ? _primary
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text('Pakai Promo',
                            style: TextStyle(
                                color: !_useManualDiskon
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _useManualDiskon = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _useManualDiskon
                              ? _primary
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text('Diskon Manual',
                            style: TextStyle(
                                color: _useManualDiskon
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_useManualDiskon) ...[
                if (_promoList.isEmpty)
                  Text('Tidak ada promo aktif',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13))
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPromo?['id']?.toString(),
                    decoration: _dec('Pilih Promo'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Tanpa Promo')),
                      ..._promoList.map((p) => DropdownMenuItem(
                            value: p['id'].toString(),
                            child: Text(
                                '${p['nama']} (${p['diskon']}%)'),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedPromo = v == null
                            ? null
                            : _promoList.firstWhere(
                                (p) => p['id'].toString() == v);
                      });
                    },
                  ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _diskonManual.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        activeColor: _primary,
                        onChanged: (v) =>
                            setState(() => _diskonManual = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 54,
                      child: Text(
                        '$_diskonManual%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: _primary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  // ── Summary card ──────────────────────────────────────────

  Widget _summaryCard() => Card(
        color: _primary.withValues(alpha: 0.05),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _summaryRow('Subtotal', _subtotal),
              if (_effectiveDiskonPersen > 0)
                _summaryRow(
                    'Diskon ($_effectiveDiskonPersen%)', -_diskonJumlah,
                    red: true),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Bayar',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_fmtRp(_total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _primary)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _summaryRow(String label, int amount, {bool red = false}) =>
      Padding(
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
                  color: red ? Colors.red : Colors.black87),
            ),
          ],
        ),
      );

  // ── Bottom bar ────────────────────────────────────────────

  Widget _bottomBar() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_cart.length} item',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    Text(_fmtRp(_total),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _primary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_saving || _cart.isEmpty) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Transaksi',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      );
}

// ── Cart Tile ─────────────────────────────────────────────────

class _CartTile extends StatefulWidget {
  final _CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<double> onQtyChanged;

  const _CartTile({
    required this.item,
    required this.onRemove,
    required this.onQtyChanged,
  });

  @override
  State<_CartTile> createState() => _CartTileState();
}

class _CartTileState extends State<_CartTile> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: _fmt(widget.item.quantity));
  }

  @override
  void didUpdateWidget(_CartTile old) {
    super.didUpdateWidget(old);
    if (old.item.quantity != widget.item.quantity) {
      _ctrl.text = _fmt(widget.item.quantity);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.nama,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  '${_fmtRp(widget.item.harga)} / ${widget.item.satuan}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // qty controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: _primary, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () =>
                    widget.onQtyChanged(widget.item.quantity - 1),
              ),
              SizedBox(
                width: 44,
                child: TextField(
                  controller: _ctrl,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                      border: InputBorder.none, isDense: true),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  onSubmitted: (v) {
                    final d = double.tryParse(v);
                    if (d != null) widget.onQtyChanged(d);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: _primary, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () =>
                    widget.onQtyChanged(widget.item.quantity + 1),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // subtotal
          SizedBox(
            width: 80,
            child: Text(
              _fmtRp(widget.item.subtotal),
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _primary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.red, size: 20),
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}

String _fmtRp(int v) {
  final f = NumberFormat('#,##0', 'id');
  return 'Rp ${f.format(v).replaceAll(',', '.')}';
}

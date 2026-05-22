import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

const _primary = Color(0xFF8B2E6E);

class PengeluaranScreen extends StatefulWidget {
  const PengeluaranScreen({super.key});

  @override
  State<PengeluaranScreen> createState() => _PengeluaranScreenState();
}

class _PengeluaranScreenState extends State<PengeluaranScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = false;
  String _filterKategori = 'Semua';
  final _searchCtrl = TextEditingController();

  static const _kategoriList = [
    'Semua', 'listrik', 'air', 'sabun', 'gaji', 'maintenance', 'lain-lain',
  ];

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
      _filtered = _all.where((e) {
        final matchK = _filterKategori == 'Semua' ||
            e['kategori'] == _filterKategori;
        final matchQ = q.isEmpty ||
            (e['nama'] as String? ?? '').toLowerCase().contains(q) ||
            (e['keterangan'] as String? ?? '').toLowerCase().contains(q);
        return matchK && matchQ;
      }).toList();
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getPengeluaran();
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

  void _openSheet({Map<String, dynamic>? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PengeluaranSheet(item: item, onSaved: _load),
    );
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: const Text('Yakin ingin menghapus data ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SupabaseService().deletePengeluaran(id);
      _load();
    } catch (e) { _showError('Gagal menghapus: $e'); }
  }

  int get _totalFiltered => _filtered.fold(
      0, (s, e) => s + ((e['jumlah'] as num?)?.toInt() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        onPressed: () => _openSheet(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search + filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari pengeluaran...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _kategoriList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final k = _kategoriList[i];
                      final selected = k == _filterKategori;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _filterKategori = k);
                          _filter();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? _primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: selected
                                    ? _primary
                                    : Colors.grey.shade300),
                          ),
                          child: Text(
                            k[0].toUpperCase() + k.substring(1),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  selected ? Colors.white : Colors.grey.shade700,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Total summary bar
          if (_filtered.isNotEmpty)
            Container(
              color: _primary.withValues(alpha: 0.06),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_filtered.length} data',
                      style: TextStyle(color: Colors.grey.shade600)),
                  Text(
                    'Total: ${_fmtRp(_totalFiltered)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _primary),
                  ),
                ],
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
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final e = _filtered[i];
                            return _PengeluaranCard(
                              item: e,
                              onEdit: () => _openSheet(item: e),
                              onDelete: () => _delete(e['id'].toString()),
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
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada pengeluaran',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Tap + untuk mencatat pengeluaran',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
}

String _fmtRp(int v) {
  final f = NumberFormat('#,##0', 'id');
  return 'Rp ${f.format(v).replaceAll(',', '.')}';
}

String _fmtDate(String? raw) {
  if (raw == null) return '-';
  try {
    return DateFormat('d MMM yyyy', 'id').format(DateTime.parse(raw));
  } catch (_) {
    return raw;
  }
}

// ── Card ──────────────────────────────────────────────────────

class _PengeluaranCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PengeluaranCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  static const _categoryColors = {
    'listrik': Colors.orange,
    'air': Colors.blue,
    'sabun': Colors.cyan,
    'gaji': Colors.green,
    'maintenance': Colors.purple,
    'lain-lain': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final kategori = item['kategori'] as String? ?? 'lain-lain';
    final color = _categoryColors[kategori] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12)),
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
                          Text(item['nama'] ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 1),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                kategori[0].toUpperCase() +
                                    kategori.substring(1),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_fmtDate(item['tanggal'] as String?),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500)),
                          ]),
                          if ((item['keterangan'] as String?)?.isNotEmpty ==
                              true)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(item['keterangan'],
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _fmtRp((item['jumlah'] as num?)?.toInt() ?? 0),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.red),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (v) {
                            if (v == 'edit') onEdit();
                            if (v == 'delete') onDelete();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
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
    );
  }
}

// ── Bottom Sheet ──────────────────────────────────────────────

class _PengeluaranSheet extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  const _PengeluaranSheet({this.item, required this.onSaved});

  @override
  State<_PengeluaranSheet> createState() => _PengeluaranSheetState();
}

class _PengeluaranSheetState extends State<_PengeluaranSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _jumlah;
  late final TextEditingController _keterangan;
  late String _kategori;
  late DateTime _tanggal;
  bool _saving = false;

  static const _kategoriOptions = [
    'listrik', 'air', 'sabun', 'gaji', 'maintenance', 'lain-lain',
  ];

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.item?['nama'] ?? '');
    _jumlah = TextEditingController(
        text: (widget.item?['jumlah'] ?? '').toString());
    _keterangan =
        TextEditingController(text: widget.item?['keterangan'] ?? '');
    _kategori = widget.item?['kategori'] ?? _kategoriOptions.first;
    final raw = widget.item?['tanggal'] as String?;
    _tanggal = raw != null ? DateTime.tryParse(raw) ?? DateTime.now() : DateTime.now();
  }

  @override
  void dispose() {
    _nama.dispose();
    _jumlah.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final jumlahVal = int.parse(
          _jumlah.text.trim().replaceAll('.', '').replaceAll(',', ''));
      if (widget.item == null) {
        await SupabaseService().addPengeluaran(
          nama: _nama.text.trim(),
          kategori: _kategori,
          jumlah: jumlahVal,
          tanggal: _tanggal,
          keterangan: _keterangan.text.trim(),
        );
      } else {
        await SupabaseService().updatePengeluaran(
          id: widget.item!['id'].toString(),
          data: {
            'nama': _nama.text.trim(),
            'kategori': _kategori,
            'jumlah': jumlahVal,
            'tanggal': _tanggal.toIso8601String().split('T').first,
            'keterangan': _keterangan.text.trim(),
          },
        );
      }
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final dateFmt = DateFormat('d MMM yyyy', 'id');
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              )),
              Text(isEdit ? 'Edit Pengeluaran' : 'Tambah Pengeluaran',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nama,
                decoration: _dec('Nama / Keterangan'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _kategori,
                decoration: _dec('Kategori'),
                items: _kategoriOptions.map((k) => DropdownMenuItem(
                  value: k,
                  child: Text(k[0].toUpperCase() + k.substring(1)),
                )).toList(),
                onChanged: (v) => setState(() => _kategori = v ?? _kategori),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jumlah,
                decoration: _dec('Jumlah (Rp)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(
                      v?.trim().replaceAll('.', '').replaceAll(',', '') ?? '');
                  if (n == null || n <= 0) return 'Masukkan jumlah yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today,
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 10),
                    Text(dateFmt.format(_tanggal)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keterangan,
                decoration: _dec('Keterangan (opsional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambah'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}

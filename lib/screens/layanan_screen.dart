import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

const _primary = Color(0xFF8B2E6E);

// ════════════════════════════════════════════════════════════
// LAYANAN SCREEN  —  Category list
// ════════════════════════════════════════════════════════════

class LayananScreen extends StatefulWidget {
  const LayananScreen({super.key});

  @override
  State<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends State<LayananScreen> {
  List<Map<String, dynamic>> _kategori = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getKategoriLayanan();
      if (mounted) setState(() { _kategori = data; _isLoading = false; });
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
      builder: (_) => _KategoriSheet(item: item, onSaved: _load),
    );
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: const Text(
            'Semua produk dalam kategori ini juga akan terhapus. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SupabaseService().deleteKategoriLayanan(id);
      _load();
    } catch (e) { _showError('Gagal menghapus: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layanan'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _kategori.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Belum ada kategori layanan',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Tap + untuk menambah kategori',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _kategori.length,
                    itemBuilder: (_, i) {
                      final k = _kategori[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shopping_basket,
                                color: _primary),
                          ),
                          title: Text(k['nama'] ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: (k['deskripsi'] as String?)?.isNotEmpty == true
                              ? Text(k['deskripsi'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)
                              : null,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'produk') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProdukLayananScreen(
                                        kategori: k),
                                  ),
                                );
                              } else if (v == 'edit') {
                                _openSheet(item: k);
                              } else if (v == 'delete') {
                                _delete(k['id'].toString());
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'produk',
                                  child: Text('Lihat Produk')),
                              PopupMenuItem(
                                  value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProdukLayananScreen(kategori: k),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Bottom Sheet ──────────────────────────────────────────────

class _KategoriSheet extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  const _KategoriSheet({this.item, required this.onSaved});

  @override
  State<_KategoriSheet> createState() => _KategoriSheetState();
}

class _KategoriSheetState extends State<_KategoriSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _deskripsi;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.item?['nama'] ?? '');
    _deskripsi =
        TextEditingController(text: widget.item?['deskripsi'] ?? '');
  }

  @override
  void dispose() { _nama.dispose(); _deskripsi.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.item == null) {
        await SupabaseService().addKategoriLayanan(
            nama: _nama.text.trim(), deskripsi: _deskripsi.text.trim());
      } else {
        await SupabaseService().updateKategoriLayanan(
          id: widget.item!['id'].toString(),
          data: {'nama': _nama.text.trim(), 'deskripsi': _deskripsi.text.trim()},
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
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
            Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nama,
              decoration: _dec('Nama Kategori'),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
                controller: _deskripsi, decoration: _dec('Deskripsi')),
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
                    : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Kategori'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}

// ════════════════════════════════════════════════════════════
// PRODUK LAYANAN SCREEN  —  Products for a category
// ════════════════════════════════════════════════════════════

class ProdukLayananScreen extends StatefulWidget {
  final Map<String, dynamic> kategori;
  const ProdukLayananScreen({super.key, required this.kategori});

  @override
  State<ProdukLayananScreen> createState() => _ProdukLayananScreenState();
}

class _ProdukLayananScreenState extends State<ProdukLayananScreen> {
  List<Map<String, dynamic>> _produk = [];
  bool _isLoading = false;

  static const _satuanOptions = ['kg', 'pcs', 'trip'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getProdukLayanan(
          kategoriId: widget.kategori['id'].toString());
      if (mounted) setState(() { _produk = data; _isLoading = false; });
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
      builder: (_) => _ProdukSheet(
        item: item,
        kategoriId: widget.kategori['id'].toString(),
        satuanOptions: _satuanOptions,
        onSaved: _load,
      ),
    );
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SupabaseService().deleteProdukLayanan(id);
      _load();
    } catch (e) { _showError('Gagal menghapus: $e'); }
  }

  String _fmtHarga(int h) {
    final s = h.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kategori['nama'] ?? 'Produk'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _produk.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Belum ada produk',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Tap + untuk menambah produk',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _produk.length,
                    itemBuilder: (_, i) {
                      final p = _produk[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                decoration: const BoxDecoration(
                                  color: _primary,
                                  borderRadius: BorderRadius.horizontal(
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(p['nama'] ?? '-',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15)),
                                            const SizedBox(height: 4),
                                            Row(children: [
                                              Text(
                                                _fmtHarga(
                                                    (p['harga'] as num?)
                                                            ?.toInt() ??
                                                        0),
                                                style: const TextStyle(
                                                    color: _primary,
                                                    fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey.shade300),
                                                ),
                                                child: Text(
                                                  p['satuan'] ?? '-',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                              ),
                                            ]),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (v) {
                                          if (v == 'edit') _openSheet(item: p);
                                          if (v == 'delete') _delete(p['id'].toString());
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Produk Bottom Sheet ───────────────────────────────────────

class _ProdukSheet extends StatefulWidget {
  final Map<String, dynamic>? item;
  final String kategoriId;
  final List<String> satuanOptions;
  final VoidCallback onSaved;
  const _ProdukSheet({
    this.item,
    required this.kategoriId,
    required this.satuanOptions,
    required this.onSaved,
  });

  @override
  State<_ProdukSheet> createState() => _ProdukSheetState();
}

class _ProdukSheetState extends State<_ProdukSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _harga;
  late String _satuan;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.item?['nama'] ?? '');
    _harga = TextEditingController(
        text: (widget.item?['harga'] ?? '').toString());
    _satuan = widget.item?['satuan'] ?? widget.satuanOptions.first;
  }

  @override
  void dispose() { _nama.dispose(); _harga.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final hargaVal = int.parse(_harga.text.trim().replaceAll('.', '').replaceAll(',', ''));
      if (widget.item == null) {
        await SupabaseService().addProdukLayanan(
          nama: _nama.text.trim(),
          harga: hargaVal,
          satuan: _satuan,
          kategoriId: widget.kategoriId,
        );
      } else {
        await SupabaseService().updateProdukLayanan(
          id: widget.item!['id'].toString(),
          data: {'nama': _nama.text.trim(), 'harga': hargaVal, 'satuan': _satuan},
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
              Text(isEdit ? 'Edit Produk' : 'Tambah Produk',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nama,
                decoration: _dec('Nama Produk'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _harga,
                decoration: _dec('Harga'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(
                      v?.trim().replaceAll('.', '').replaceAll(',', '') ?? '');
                  if (n == null || n < 0) return 'Masukkan harga yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _satuan,
                decoration: _dec('Satuan'),
                items: widget.satuanOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _satuan = v ?? _satuan),
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
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Produk'),
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

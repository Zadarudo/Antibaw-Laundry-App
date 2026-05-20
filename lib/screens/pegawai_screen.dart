import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

const _primary = Color(0xFF8B2E6E);

class PegawaiScreen extends StatefulWidget {
  const PegawaiScreen({super.key});

  @override
  State<PegawaiScreen> createState() => _PegawaiScreenState();
}

class _PegawaiScreenState extends State<PegawaiScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.of(_all)
          : _all.where((p) {
              return (p['nama'] as String? ?? '').toLowerCase().contains(q) ||
                  (p['jabatan'] as String? ?? '').toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getPegawai();
      if (mounted) {
        setState(() {
          _all = data;
          _isLoading = false;
        });
        _filter();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Gagal memuat data: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _openSheet({Map<String, dynamic>? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PegawaiSheet(item: item, onSaved: _load),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> item) async {
    try {
      await SupabaseService().updatePegawai(
        id: item['id'].toString(),
        data: {'is_active': !(item['is_active'] as bool? ?? true)},
      );
      _load();
    } catch (e) {
      _showError('Gagal mengubah status: $e');
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pegawai'),
        content: const Text('Yakin ingin menghapus pegawai ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SupabaseService().deletePegawai(id);
      _load();
    } catch (e) {
      _showError('Gagal menghapus: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pegawai'),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pegawai...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                          itemBuilder: (_, i) => _PegawaiCard(
                            item: _filtered[i],
                            onEdit: () => _openSheet(item: _filtered[i]),
                            onToggle: () => _toggleActive(_filtered[i]),
                            onDelete: () =>
                                _delete(_filtered[i]['id'].toString()),
                          ),
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
            Icon(Icons.person_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Belum ada pegawai',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + untuk menambah pegawai baru',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _PegawaiCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PegawaiCard({
    required this.item,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = item['is_active'] as bool? ?? true;
    final cabangNama =
        (item['cabang'] as Map<String, dynamic>?)?['nama'] as String?;
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
                color: isActive ? _primary : Colors.grey,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
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
                            item['nama'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if ((item['jabatan'] as String?)?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  Icon(Icons.work_outline,
                                      size: 13,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['jabatan'],
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          if ((item['telepon'] as String?)?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  Icon(Icons.phone,
                                      size: 12,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['telepon'],
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          if (cabangNama != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  Icon(Icons.apartment,
                                      size: 12,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    cabangNama,
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 6),
                          _StatusBadge(isActive: isActive),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (v) {
                        if (v == 'edit') onEdit();
                        if (v == 'toggle') onToggle();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                        ),
                        const PopupMenuItem(
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
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          fontSize: 11,
          color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

// ── Bottom Sheet ──────────────────────────────────────────────────────────────

class _PegawaiSheet extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  const _PegawaiSheet({this.item, required this.onSaved});

  @override
  State<_PegawaiSheet> createState() => _PegawaiSheetState();
}

class _PegawaiSheetState extends State<_PegawaiSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _jabatan;
  late final TextEditingController _telepon;

  List<Map<String, dynamic>> _cabangList = [];
  String? _selectedCabangId;
  bool _saving = false;
  bool _loadingCabang = false;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.item?['nama'] ?? '');
    _jabatan = TextEditingController(text: widget.item?['jabatan'] ?? '');
    _telepon = TextEditingController(text: widget.item?['telepon'] ?? '');
    _selectedCabangId = widget.item?['cabang_id']?.toString();
    _loadCabang();
  }

  @override
  void dispose() {
    _nama.dispose();
    _jabatan.dispose();
    _telepon.dispose();
    super.dispose();
  }

  Future<void> _loadCabang() async {
    setState(() => _loadingCabang = true);
    try {
      final data = await SupabaseService().getCabang();
      if (mounted) {
        setState(() {
          _cabangList =
              data.where((c) => c['is_active'] == true).toList();
          _loadingCabang = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCabang = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.item == null) {
        await SupabaseService().addPegawai(
          nama: _nama.text.trim(),
          jabatan: _jabatan.text.trim(),
          telepon: _telepon.text.trim(),
          cabangId: _selectedCabangId,
        );
      } else {
        await SupabaseService().updatePegawai(
          id: widget.item!['id'].toString(),
          data: {
            'nama': _nama.text.trim(),
            'jabatan': _jabatan.text.trim(),
            'telepon': _telepon.text.trim(),
            'cabang_id': _selectedCabangId,
          },
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menyimpan: $e'),
              backgroundColor: Colors.red),
        );
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
              _sheetHandle(),
              Text(
                isEdit ? 'Edit Pegawai' : 'Tambah Pegawai',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nama,
                decoration: _dec('Nama Pegawai'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jabatan,
                decoration: _dec('Jabatan'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telepon,
                decoration: _dec('Telepon'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _loadingCabang
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _selectedCabangId,
                      decoration: _dec('Cabang (opsional)'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tidak ada cabang'),
                        ),
                        ..._cabangList.map((c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(c['nama'] ?? '-'),
                            )),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedCabangId = v),
                    ),
              const SizedBox(height: 20),
              _saveButton(isEdit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _saveButton(bool isEdit) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Pegawai'),
        ),
      );

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}

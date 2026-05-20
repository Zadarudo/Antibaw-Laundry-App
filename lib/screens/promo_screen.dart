import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

const _primary = Color(0xFF8B2E6E);

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
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
                  (p['deskripsi'] as String? ?? '').toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getPromo();
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
      builder: (_) => _PromoSheet(item: item, onSaved: _load),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> item) async {
    try {
      await SupabaseService().updatePromo(
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
        title: const Text('Hapus Promo'),
        content: const Text('Yakin ingin menghapus promo ini?'),
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
      await SupabaseService().deletePromo(id);
      _load();
    } catch (e) {
      _showError('Gagal menghapus: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo'),
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
                hintText: 'Cari promo...',
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
                          itemBuilder: (_, i) => _PromoCard(
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
            Icon(Icons.local_offer_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Belum ada promo',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + untuk menambah promo baru',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

bool _isExpired(Map<String, dynamic> item) {
  final raw = item['tanggal_selesai'] as String?;
  if (raw == null) return false;
  try {
    return DateTime.parse(raw).isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );
  } catch (_) {
    return false;
  }
}

String _fmtDate(String? raw) {
  if (raw == null) return '-';
  try {
    return DateFormat('d MMM yyyy', 'id').format(DateTime.parse(raw));
  } catch (_) {
    return raw;
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _PromoCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PromoCard({
    required this.item,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = item['is_active'] as bool? ?? true;
    final expired = _isExpired(item);
    final diskon = item['diskon'] as int? ?? 0;

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
                color: (!expired && isActive) ? _primary : Colors.grey,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['nama'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusBadge(isActive: isActive, expired: expired),
                            ],
                          ),
                          if ((item['deskripsi'] as String?)?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item['deskripsi'],
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.orange.shade200),
                                ),
                                child: Text(
                                  'Diskon $diskon%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item['tanggal_mulai'] != null ||
                              item['tanggal_selesai'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${_fmtDate(item['tanggal_mulai'] as String?)} — ${_fmtDate(item['tanggal_selesai'] as String?)}',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ),
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
  final bool expired;
  const _StatusBadge({required this.isActive, required this.expired});

  @override
  Widget build(BuildContext context) {
    final label = expired
        ? 'Kadaluarsa'
        : isActive
            ? 'Aktif'
            : 'Nonaktif';
    final bg = expired
        ? Colors.red.shade50
        : isActive
            ? Colors.green.shade50
            : Colors.grey.shade100;
    final border = expired
        ? Colors.red.shade300
        : isActive
            ? Colors.green.shade300
            : Colors.grey.shade300;
    final fg = expired
        ? Colors.red.shade700
        : isActive
            ? Colors.green.shade700
            : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: fg)),
    );
  }
}

// ── Bottom Sheet ──────────────────────────────────────────────────────────────

class _PromoSheet extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  const _PromoSheet({this.item, required this.onSaved});

  @override
  State<_PromoSheet> createState() => _PromoSheetState();
}

class _PromoSheetState extends State<_PromoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _deskripsi;
  late final TextEditingController _diskon;
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  bool _saving = false;

  static final _dateFmt = DateFormat('d MMM yyyy', 'id');

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.item?['nama'] ?? '');
    _deskripsi =
        TextEditingController(text: widget.item?['deskripsi'] ?? '');
    _diskon = TextEditingController(
        text: (widget.item?['diskon'] ?? 0).toString());

    final mulaiRaw = widget.item?['tanggal_mulai'] as String?;
    final selesaiRaw = widget.item?['tanggal_selesai'] as String?;
    if (mulaiRaw != null) {
      try {
        _tanggalMulai = DateTime.parse(mulaiRaw);
      } catch (_) {}
    }
    if (selesaiRaw != null) {
      try {
        _tanggalSelesai = DateTime.parse(selesaiRaw);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    _diskon.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isMulai) async {
    final now = DateTime.now();
    final initial = isMulai
        ? (_tanggalMulai ?? now)
        : (_tanggalSelesai ?? _tanggalMulai ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final diskonVal = int.tryParse(_diskon.text.trim()) ?? 0;
      if (widget.item == null) {
        await SupabaseService().addPromo(
          nama: _nama.text.trim(),
          deskripsi: _deskripsi.text.trim(),
          diskon: diskonVal,
          tanggalMulai: _tanggalMulai,
          tanggalSelesai: _tanggalSelesai,
        );
      } else {
        await SupabaseService().updatePromo(
          id: widget.item!['id'].toString(),
          data: {
            'nama': _nama.text.trim(),
            'deskripsi': _deskripsi.text.trim(),
            'diskon': diskonVal,
            'tanggal_mulai':
                _tanggalMulai?.toIso8601String().split('T').first,
            'tanggal_selesai':
                _tanggalSelesai?.toIso8601String().split('T').first,
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
                isEdit ? 'Edit Promo' : 'Tambah Promo',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nama,
                decoration: _dec('Nama Promo'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsi,
                decoration: _dec('Deskripsi'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diskon,
                decoration: _dec('Diskon (%)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Masukkan angka';
                  if (n < 0 || n > 100) return 'Diskon harus 0–100';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _DateTile(
                label: 'Tanggal Mulai',
                date: _tanggalMulai,
                formatter: _dateFmt,
                onTap: () => _pickDate(true),
              ),
              const SizedBox(height: 8),
              _DateTile(
                label: 'Tanggal Selesai',
                date: _tanggalSelesai,
                formatter: _dateFmt,
                onTap: () => _pickDate(false),
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
              : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Promo'),
        ),
      );

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateFormat formatter;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.date,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                date != null ? formatter.format(date!) : label,
                style: TextStyle(
                  color:
                      date != null ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
            ),
            if (date != null)
              Text(
                label,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }
}

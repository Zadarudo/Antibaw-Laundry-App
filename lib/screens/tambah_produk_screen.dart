import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';

class TambahProdukScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const TambahProdukScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<TambahProdukScreen> createState() => _TambahProdukScreenState();
}

class _TambahProdukScreenState extends State<TambahProdukScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  List<Map<String, dynamic>> _categories = [];
  List<String> _units = ['pcs', 'kg', 'gram', 'liter', 'ml', 'box', 'lusin'];
  String? _selectedCategoryId;
  String? _selectedUnit;
  bool _useItemCount = true;
  bool _isSaving = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await SupabaseService().getServiceCategories();
      if (mounted) setState(() => _categories = data);
    } catch (_) {}
  }

  void _showAddUnitDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Tambah Satuan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nama satuan (contoh: botol)',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final unit = controller.text.trim();
              if (unit.isNotEmpty) {
                setState(() {
                  _units.add(unit);
                  _selectedUnit = unit;
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B2E6E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tambah',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();

    if (name.isEmpty) {
      _showError('Nama layanan wajib diisi');
      return;
    }
    if (priceText.isEmpty) {
      _showError('Harga wajib diisi');
      return;
    }
    final price = double.tryParse(priceText) ?? 0;
    if (price <= 0) {
      _showError('Harga harus lebih dari 0');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService().addServiceProduct(
        categoryId: _selectedCategoryId ?? widget.categoryId,
        name: name,
        price: price,
        unit: _selectedUnit,
        imageUrl: _imageUrl,
        useItemCount: _useItemCount,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showError('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tambah produk',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF8B2E6E),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text(
                    'SIMPAN',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo picker placeholder
            GestureDetector(
              onTap: () {
                // Image picking can be added later with image_picker package
                _showError('Fitur upload foto membutuhkan package image_picker');
              },
              child: Container(
                width: double.infinity,
                height: 180,
                color: Colors.grey.shade200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_imageUrl != null)
                      Image.network(_imageUrl!, height: 160, fit: BoxFit.cover)
                    else ...[
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('pilih foto',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category dropdown
                  const Text('Kategori',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF8B2E6E)),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                          hint: const Text('-- Pilih --',
                              style: TextStyle(color: Colors.grey)),
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                    value: c['id'].toString(),
                                    child: Text(c['name'].toString()),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategoryId = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add category button
                      GestureDetector(
                        onTap: () async {
                          await Navigator.pushNamed(context, '/layanan');
                          _loadCategories();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nama Layanan
                  const Text('Nama Layanan',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF8B2E6E)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Harga
                  const Text('Harga',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF8B2E6E)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Satuan
                  const Text('Satuan',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF8B2E6E)),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                          hint: const Text('-- Pilih --',
                              style: TextStyle(color: Colors.grey)),
                          items: _units
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedUnit = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showAddUnitDialog,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Gunakan jumlah item toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gunakan jumlah item',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Switch(
                        value: _useItemCount,
                        onChanged: (v) =>
                            setState(() => _useItemCount = v),
                        activeColor: const Color(0xFF8B2E6E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

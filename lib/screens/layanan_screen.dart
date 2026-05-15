import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'tambah_produk_screen.dart';
import 'produk_list_screen.dart';

class LayananScreen extends StatefulWidget {
  const LayananScreen({super.key});

  @override
  State<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends State<LayananScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getServiceCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _filtered = data;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal memuat data: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = _categories
          .where((c) =>
              c['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Tambah Kategori',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nama kategori',
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
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await _addCategory(name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B2E6E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Simpan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(String name) async {
    try {
      await SupabaseService().addServiceCategory(name: name);
      await _load();
    } catch (e) {
      if (mounted) _showError('Gagal menambah kategori: $e');
    }
  }

  void _confirmDelete(Map<String, dynamic> category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Kategori',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Hapus kategori "${category['name']}"? Semua produk di dalamnya juga akan terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await SupabaseService()
            .deleteServiceCategory(category['id'].toString());
        await _load();
      } catch (e) {
        if (mounted) _showError('Gagal menghapus: $e');
      }
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
        title: const Text('Layanan'),
        backgroundColor: const Color(0xFF8B2E6E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to unit management if needed
            },
            child: const Text('SATUAN',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Cari nama kategori produk',
                suffixIcon:
                    const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B2E6E)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Category list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF8B2E6E)))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada kategori layanan',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap tombol Tambah untuk memulai',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF8B2E6E),
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _buildCategoryCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),

      // Add button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: _showAddCategoryDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B2E6E),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Tambah',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final productCount = category['product_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF8B2E6E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Content
            Expanded(
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProdukListScreen(
                        categoryId: category['id'].toString(),
                        categoryName: category['name'].toString(),
                      ),
                    ),
                  );
                  _load(); // Refresh count when returning
                },
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category['name'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Jumlah produk : $productCount',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Three-dot menu
                      PopupMenuButton<String>(
                        icon: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_vert,
                              color: Colors.grey, size: 20),
                        ),
                        onSelected: (value) {
                          if (value == 'tambah') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TambahProdukScreen(
                                  categoryId: category['id'].toString(),
                                  categoryName:
                                      category['name'].toString(),
                                ),
                              ),
                            ).then((_) => _load());
                          } else if (value == 'hapus') {
                            _confirmDelete(category);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'tambah',
                            child: Row(children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 8),
                              Text('Tambah Produk'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'hapus',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus Kategori',
                                  style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

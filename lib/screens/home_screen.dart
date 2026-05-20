import 'package:flutter/material.dart';
import '../widgets/service_card.dart';
import '../widgets/report_card.dart';
import '../services/supabase_service.dart';
import 'service_detail_screen.dart';
import 'report_detail_screen.dart';
import 'cabang_screen.dart';
import 'pegawai_screen.dart';
import 'pelanggan_screen.dart';
import 'promo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _businessName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = SupabaseService().getCurrentUser();
      if (user != null) {
        final profile = await SupabaseService().getUserProfile(user.id);
        if (profile != null) {
          setState(() {
            _userName = profile['name'] ?? 'User';
            _businessName = profile['business_name'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  int _crossAxisCount(double screenWidth) {
    if (screenWidth < 340) return 3;
    if (screenWidth >= 600) return 5;
    return 4;
  }

  double _childAspectRatio(int columns) {
    if (columns == 3) return 0.85;
    if (columns == 5) return 0.7;
    return 0.78;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cols = _crossAxisCount(screenWidth);
    final aspectRatio = _childAspectRatio(cols);
    final hPadding = screenWidth < 360 ? 12.0 : 20.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(hPadding),
                decoration: const BoxDecoration(
                  color: Color(0xFF8B2E6E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi ${_userName.isEmpty ? 'User' : _userName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _businessName.isEmpty ? 'Loading...' : _businessName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Services Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Layanan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: aspectRatio,
                      children: [
                        ServiceCard(
                          icon: Icons.info,
                          label: 'Cara\nPenggunaan',
                          color: const Color(0xFF2196F3),
                          onTap: () => _navigateToService(
                            context,
                            'Cara Penggunaan',
                            'Pelajari cara menggunakan aplikasi AntiBaw',
                          ),
                        ),
                        ServiceCard(
                          icon: Icons.apartment,
                          label: 'Cabang',
                          color: const Color(0xFF29B6F6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CabangScreen()),
                          ),
                        ),
                        ServiceCard(
                          icon: Icons.shopping_basket,
                          label: 'Layanan',
                          color: const Color(0xFF9C27B0),
                          onTap: () => _navigateToService(
                            context,
                            'Layanan',
                            'Kelola layanan yang tersedia',
                          ),
                        ),
                        ServiceCard(
                          icon: Icons.person,
                          label: 'Pegawai',
                          color: const Color(0xFF66BB6A),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PegawaiScreen()),
                          ),
                        ),
                        ServiceCard(
                          icon: Icons.people,
                          label: 'Pelanggan',
                          color: const Color(0xFFFFA726),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PelangganScreen()),
                          ),
                        ),
                        ServiceCard(
                          icon: Icons.star,
                          label: 'Promo',
                          color: const Color(0xFF4CAF50),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PromoScreen()),
                          ),
                        ),
                        ServiceCard(
                          icon: Icons.mail,
                          label: 'Notifikasi',
                          color: const Color(0xFFEC407A),
                          onTap: () => _navigateToService(
                            context,
                            'Notifikasi',
                            'Kelola notifikasi aplikasi',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reports Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Laporan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: aspectRatio,
                      children: [
                        ReportCard(
                          icon: Icons.receipt,
                          label: 'Data\nTransaksi',
                          color: const Color(0xFF558B2F),
                          onTap: () => _navigateToReport(
                            context,
                            'Data Transaksi',
                            'Laporan transaksi lengkap',
                          ),
                        ),
                        ReportCard(
                          icon: Icons.show_chart,
                          label: 'Grafik\n5 Bulan',
                          color: const Color(0xFF0D47A1),
                          onTap: () => _navigateToReport(
                            context,
                            'Grafik 5 Bulan',
                            'Analisis grafik penjualan',
                          ),
                        ),
                        ReportCard(
                          icon: Icons.account_balance_wallet,
                          label: 'Pengeluaran',
                          color: const Color(0xFF00695C),
                          onTap: () => _navigateToReport(
                            context,
                            'Pengeluaran',
                            'Rincian pengeluaran usaha',
                          ),
                        ),
                        ReportCard(
                          icon: Icons.description,
                          label: 'Detail\nLaporan',
                          color: const Color(0xFF9ACD32),
                          onTap: () => _navigateToReport(
                            context,
                            'Detail Laporan',
                            'Detail lengkap laporan',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToService(BuildContext context, String title, String description) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(
          title: title,
          description: description,
        ),
      ),
    );
  }

  void _navigateToReport(BuildContext context, String title, String description) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(
          title: title,
          description: description,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/service_card.dart';
import '../widgets/report_card.dart';
import '../services/supabase_service.dart';
import 'report_detail_screen.dart';
import 'cabang_screen.dart';
import 'pegawai_screen.dart';
import 'pelanggan_screen.dart';
import 'promo_screen.dart';
import 'layanan_screen.dart';
import 'pengeluaran_screen.dart';
import 'transaksi_screen.dart';
import 'notification_screen.dart';

const _primary = Color(0xFF8B2E6E);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _businessName = '';
  int _todayRevenue = 0;
  int _todayCount = 0;
  int _monthRevenue = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    try {
      final user = SupabaseService().getCurrentUser();
      if (user != null) {
        final profile = await SupabaseService().getUserProfile(user.id);
        if (profile != null && mounted) {
          setState(() {
            _userName = profile['name']?.toString().isNotEmpty == true
                ? profile['name']
                : 'User';
            _businessName = profile['business_name'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SupabaseService().getDashboardStats();
      if (mounted) {
        setState(() {
          _todayRevenue = stats['today_revenue'] as int? ?? 0;
          _todayCount = stats['today_count'] as int? ?? 0;
          _monthRevenue = stats['month_revenue'] as int? ?? 0;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
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

  String _fmtRp(int v) {
    final f = NumberFormat('#,##0', 'id');
    return 'Rp ${f.format(v).replaceAll(',', '.')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cols = _crossAxisCount(screenWidth);
    final aspectRatio = _childAspectRatio(cols);
    final hPadding = screenWidth < 360 ? 12.0 : 20.0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([_loadUserData(), _loadStats()]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(hPadding, hPadding, hPadding, 20),
                  decoration: const BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${_userName.isEmpty ? 'User' : _userName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _businessName.isEmpty ? 'Memuat...' : _businessName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Stats row
                      _loadingStats
                          ? const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white70, strokeWidth: 2),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Pemasukan Hari Ini',
                                    value: _fmtRp(_todayRevenue),
                                    icon: Icons.trending_up,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Transaksi Hari Ini',
                                    value: '$_todayCount',
                                    icon: Icons.receipt_outlined,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Pemasukan Bulan Ini',
                                    value: _fmtRp(_monthRevenue),
                                    icon: Icons.calendar_month_outlined,
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Quick action: Transaksi Baru ──────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPadding),
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TransaksiScreen()),
                      );
                      _loadStats();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFAD4090), _primary],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.point_of_sale,
                              color: Colors.white, size: 28),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Buat Transaksi Baru',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                Text('Catat penjualan & cetak invoice',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Services Section ──────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manajemen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LayananScreen()),
                            ),
                          ),
                          ServiceCard(
                            icon: Icons.badge_outlined,
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
                            icon: Icons.local_offer,
                            label: 'Promo',
                            color: const Color(0xFF4CAF50),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PromoScreen()),
                            ),
                          ),
                          ServiceCard(
                            icon: Icons.account_balance_wallet,
                            label: 'Pengeluaran',
                            color: const Color(0xFFEF5350),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PengeluaranScreen()),
                            ),
                          ),
                          ServiceCard(
                            icon: Icons.notifications_outlined,
                            label: 'Notifikasi',
                            color: const Color(0xFFEC407A),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NotificationScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Reports Section ───────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Laporan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                            icon: Icons.receipt_long,
                            label: 'Data\nTransaksi',
                            color: const Color(0xFF558B2F),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const TransaksiScreen()),
                              );
                              _loadStats();
                            },
                          ),
                          ReportCard(
                            icon: Icons.show_chart,
                            label: 'Grafik\n5 Bulan',
                            color: const Color(0xFF0D47A1),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReportDetailScreen(
                                  title: 'Grafik 5 Bulan',
                                  description: 'Analisis grafik penjualan',
                                ),
                              ),
                            ),
                          ),
                          ReportCard(
                            icon: Icons.account_balance_wallet,
                            label: 'Pengeluaran',
                            color: const Color(0xFF00695C),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PengeluaranScreen()),
                            ),
                          ),
                          ReportCard(
                            icon: Icons.description,
                            label: 'Detail\nLaporan',
                            color: const Color(0xFF9ACD32),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReportDetailScreen(
                                  title: 'Detail Laporan',
                                  description: 'Detail lengkap laporan',
                                ),
                              ),
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
      ),
    );
  }
}

// ── Stat card widget ──────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

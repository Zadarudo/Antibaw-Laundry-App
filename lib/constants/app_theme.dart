import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF8B2E6E);
  static const Color accentColor = Color(0xFF29B6F6);
  
  // Service Colors
  static const Color serviceBlue = Color(0xFF2196F3);
  static const Color serviceCyan = Color(0xFF29B6F6);
  static const Color servicePurple = Color(0xFF9C27B0);
  static const Color serviceGreen = Color(0xFF66BB6A);
  static const Color serviceOrange = Color(0xFFFFA726);
  static const Color serviceGreenDark = Color(0xFF4CAF50);
  static const Color servicePink = Color(0xFFEC407A);

  // Report Colors
  static const Color reportGreen = Color(0xFF558B2F);
  static const Color reportNavy = Color(0xFF0D47A1);
  static const Color reportTeal = Color(0xFF00695C);
  static const Color reportYellow = Color(0xFF9ACD32);

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  // Border Radius
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(10));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(20));
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(8));

  // Spacing
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  // Shadow
  static const BoxShadow shadowSmall = BoxShadow(
    color: Colors.black12,
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowMedium = BoxShadow(
    color: Colors.black26,
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowLarge = BoxShadow(
    color: Colors.black38,
    blurRadius: 12,
    offset: Offset(0, 6),
  );
}

class AppStrings {
  // Navigation
  static const String home = 'Home';
  static const String notifikasi = 'Notifikasi';
  static const String akunSaya = 'Akun Saya';

  // Services
  static const String layanan = 'Layanan';
  static const String caraPenggunaan = 'Cara Penggunaan';
  static const String cabang = 'Cabang';
  static const String pegawai = 'Pegawai';
  static const String pelanggan = 'Pelanggan';
  static const String promo = 'Promo';

  // Reports
  static const String laporan = 'Laporan';
  static const String dataTransaksi = 'Data Transaksi';
  static const String grafik5Bulan = 'Grafik 5 Bulan';
  static const String pengeluaran = 'Pengeluaran';
  static const String detailLaporan = 'Detail Laporan';

  // Common
  static const String tambah = 'Tambah';
  static const String ubah = 'Ubah';
  static const String simpan = 'Simpan';
  static const String hapus = 'Hapus';
  static const String batal = 'Batal';
  static const String logout = 'Logout';
  static const String belumAdaData = 'Belum ada data';
}

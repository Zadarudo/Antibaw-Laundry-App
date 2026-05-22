import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ============== Auth Methods ==============

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String businessName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'business_name': businessName},
      );

      if (response.user != null) {
        await createUserProfile(
          userId: response.user!.id,
          email: email,
          businessName: businessName,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }

  // ============== User Profile Methods ==============

  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String businessName,
  }) async {
    try {
      await _supabase.from('profiles').insert({  // ← was 'users'
        'id': userId,
        'email': email,
        'business_name': businessName,
        'name': '',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')           // ← was 'users'
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;                    // ← return null instead of rethrowing
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabase.from('profiles').update(data).eq('id', userId);  // ← was 'users'
    } catch (e) {
      rethrow;
    }
  }

  // ============== Transaction Methods ==============

  Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addTransaction({
    required String userId,
    required String description,
    required int amount,
    required String type,
  }) async {
    try {
      await _supabase.from('transactions').insert({
        'user_id': userId,
        'description': description,
        'amount': amount,
        'type': type,
        'date': DateTime.now().toIso8601String(),
        'status': 'completed',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _supabase.from('transactions').delete().eq('id', transactionId);
    } catch (e) {
      rethrow;
    }
  }

  // ============== Service Methods ==============

  Future<List<Map<String, dynamic>>> getServices(String userId) async {
    try {
      final response = await _supabase
          .from('services')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addService({
    required String userId,
    required String name,
    required String description,
  }) async {
    try {
      await _supabase.from('services').insert({
        'user_id': userId,
        'name': name,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _supabase.from('services').delete().eq('id', serviceId);
    } catch (e) {
      rethrow;
    }
  }

  // ============== Notification Methods ==============

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      rethrow;
    }
  }

  // ============== Report Methods ==============

  Future<List<Map<String, dynamic>>> getReports({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getReportSummary(String userId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId);

      int totalIncome = 0;
      int totalExpense = 0;

      for (var transaction in response) {
        if (transaction['type'] == 'income') {
          totalIncome += transaction['amount'] as int;
        } else {
          totalExpense += transaction['amount'] as int;
        }
      }

      return {
        'total_income': totalIncome,
        'total_expense': totalExpense,
        'net_profit': totalIncome - totalExpense,
      };
    } catch (e) {
      rethrow;
    }
  }

  // ============== Cabang Methods ==============

  Future<List<Map<String, dynamic>>> getCabang() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    return await _supabase
        .from('cabang')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> addCabang({
    required String nama,
    String? alamat,
    String? telepon,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Tidak terautentikasi');
    await _supabase.from('cabang').insert({
      'user_id': userId,
      'nama': nama,
      'alamat': alamat,
      'telepon': telepon,
      'is_active': true,
    });
  }

  Future<void> updateCabang({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from('cabang').update(data).eq('id', id);
  }

  Future<void> deleteCabang(String id) async {
    await _supabase.from('cabang').delete().eq('id', id);
  }

  // ============== Pegawai Methods ==============

  Future<List<Map<String, dynamic>>> getPegawai() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    return await _supabase
        .from('pegawai')
        .select('*, cabang(nama)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> addPegawai({
    required String nama,
    String? jabatan,
    String? telepon,
    String? cabangId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Tidak terautentikasi');
    await _supabase.from('pegawai').insert({
      'user_id': userId,
      'nama': nama,
      'jabatan': jabatan,
      'telepon': telepon,
      'cabang_id': cabangId,
      'is_active': true,
    });
  }

  Future<void> updatePegawai({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from('pegawai').update(data).eq('id', id);
  }

  Future<void> deletePegawai(String id) async {
    await _supabase.from('pegawai').delete().eq('id', id);
  }

  // ============== Pelanggan Methods ==============

  Future<List<Map<String, dynamic>>> getPelanggan() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    return await _supabase
        .from('pelanggan')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> addPelanggan({
    required String nama,
    String? telepon,
    String? alamat,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Tidak terautentikasi');
    await _supabase.from('pelanggan').insert({
      'user_id': userId,
      'nama': nama,
      'telepon': telepon,
      'alamat': alamat,
      'total_transaksi': 0,
    });
  }

  Future<void> updatePelanggan({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from('pelanggan').update(data).eq('id', id);
  }

  Future<void> deletePelanggan(String id) async {
    await _supabase.from('pelanggan').delete().eq('id', id);
  }

  // ============== Promo Methods ==============

  Future<List<Map<String, dynamic>>> getPromo() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    return await _supabase
        .from('promo')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> addPromo({
    required String nama,
    String? deskripsi,
    int diskon = 0,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Tidak terautentikasi');
    await _supabase.from('promo').insert({
      'user_id': userId,
      'nama': nama,
      'deskripsi': deskripsi,
      'diskon': diskon,
      'tanggal_mulai': tanggalMulai?.toIso8601String().split('T').first,
      'tanggal_selesai': tanggalSelesai?.toIso8601String().split('T').first,
      'is_active': true,
    });
  }

  Future<void> updatePromo({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from('promo').update(data).eq('id', id);
  }

  Future<void> deletePromo(String id) async {
    await _supabase.from('promo').delete().eq('id', id);
  }

  // ============== Kategori Layanan Methods ==============

  Future<List<Map<String, dynamic>>> getKategoriLayanan() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    return await _supabase
        .from('kategori_layanan')
        .select()
        .eq('user_id', userId)
        .order('nama', ascending: true);
  }

  Future<void> addKategoriLayanan({required String nama, String? deskripsi}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Tidak terautentikasi');
    await _supabase.from('kategori_layanan').insert({
      'user_id': userId,
      'nama': nama,
      'deskripsi': deskripsi,
    });
  }

  Future<void> updateKategoriLayanan({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from('kategori_layanan').update(data).eq('id', id);
  }

  Future<void> deleteKategoriLayanan(String id) async {
    await _supabase.from('kategori_layanan').delete().eq('id', id);
  }

  // ============== Produk Layanan Methods ==============

  Future<List<Map<String, dynamic>>> getProdukLayanan({String? kategoriId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    var query = _supabase
        .from('produk_layanan')
        .select('*, kategori_layanan(nama)')
        .eq('user_id', userId);
    if (kategoriId != null) query = query.eq('kategori_id', kategoriId);
    return await query.order('nama', ascending: true);
  }

  Future<void> addProdukLayanan({
    required String nama,
    required int harga,
    required String satuan,
    String? kategoriId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Tidak terautentikasi');
    await _supabase.from('produk_layanan').insert({
      'user_id': userId,
      'kategori_id': kategoriId,
      'nama': nama,
      'harga': harga,
      'satuan': satuan,
    });
  }

  Future<void> updateProdukLayanan({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from('produk_layanan').update(data).eq('id', id);
  }

  Future<void> deleteProdukLayanan(String id) async {
    await _supabase.from('produk_layanan').delete().eq('id', id);
  }

  // ============== Pengeluaran Methods ==============

  Future<List<Map<String, dynamic>>> getPengeluaran() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    return await _supabase
        .from('pengeluaran')
        .select()
        .eq('user_id', userId)
        .order('tanggal', ascending: false);
  }

  Future<void> addPengeluaran({
    required String nama,
    required String kategori,
    required int jumlah,
    required DateTime tanggal,
    String? keterangan,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Tidak terautentikasi');
    await _supabase.from('pengeluaran').insert({
      'user_id': userId,
      'nama': nama,
      'kategori': kategori,
      'jumlah': jumlah,
      'tanggal': tanggal.toIso8601String().split('T').first,
      'keterangan': keterangan,
    });
  }

  Future<void> updatePengeluaran({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.from('pengeluaran').update(data).eq('id', id);
  }

  Future<void> deletePengeluaran(String id) async {
    await _supabase.from('pengeluaran').delete().eq('id', id);
  }

  // ============== Transaksi Methods ==============

  Future<List<Map<String, dynamic>>> getTransaksi({int limit = 50}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    return await _supabase
        .from('transaksi')
        .select('*, pelanggan(nama)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
  }

  Future<Map<String, dynamic>> getTransaksiDetail(String id) async {
    final trx = await _supabase
        .from('transaksi')
        .select('*, pelanggan(nama)')
        .eq('id', id)
        .single();
    final items = await _supabase
        .from('item_transaksi')
        .select()
        .eq('transaksi_id', id)
        .order('created_at', ascending: true);
    return {...trx, 'items': items};
  }

  Future<String> _generateNomorInvoice() async {
    final userId = _supabase.auth.currentUser?.id;
    final today = DateTime.now();
    final dateStr =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final rows = await _supabase
        .from('transaksi')
        .select('id')
        .eq('user_id', userId ?? '')
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String());
    final seq = (rows.length + 1).toString().padLeft(4, '0');
    return 'INV-$dateStr-$seq';
  }

  Future<String> createTransaksi({
    String? pelangganId,
    String? namaPelanggan,
    required List<Map<String, dynamic>> items,
    int diskonPersen = 0,
    String? catatan,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Tidak terautentikasi');
    if (items.isEmpty) throw Exception('Tambahkan minimal satu item');

    final nomorInvoice = await _generateNomorInvoice();
    final totalHarga = items.fold<int>(
        0, (sum, i) => sum + (i['subtotal'] as int));
    final diskonJumlah = (totalHarga * diskonPersen / 100).round();
    final totalBayar = totalHarga - diskonJumlah;

    final trxResult = await _supabase
        .from('transaksi')
        .insert({
          'user_id': userId,
          'pelanggan_id': pelangganId,
          'nama_pelanggan': namaPelanggan,
          'nomor_invoice': nomorInvoice,
          'total_harga': totalHarga,
          'diskon_persen': diskonPersen,
          'diskon_jumlah': diskonJumlah,
          'total_bayar': totalBayar,
          'status': 'selesai',
          'catatan': catatan,
        })
        .select('id')
        .single();

    final transaksiId = trxResult['id'].toString();
    final itemRows = items
        .map((i) => {
              'transaksi_id': transaksiId,
              'produk_id': i['produk_id'],
              'nama_produk': i['nama_produk'],
              'harga': i['harga'],
              'quantity': i['quantity'],
              'satuan': i['satuan'],
              'subtotal': i['subtotal'],
            })
        .toList();
    await _supabase.from('item_transaksi').insert(itemRows);

    // bump total_transaksi on pelanggan
    if (pelangganId != null) {
      try {
        final pel = await _supabase
            .from('pelanggan')
            .select('total_transaksi')
            .eq('id', pelangganId)
            .single();
        final current = pel['total_transaksi'] as int? ?? 0;
        await _supabase
            .from('pelanggan')
            .update({'total_transaksi': current + 1})
            .eq('id', pelangganId);
      } catch (_) {}
    }

    return nomorInvoice;
  }

  Future<void> deleteTransaksi(String id) async {
    await _supabase.from('item_transaksi').delete().eq('transaksi_id', id);
    await _supabase.from('transaksi').delete().eq('id', id);
  }

  // ============== Dashboard Stats ==============

  Future<Map<String, dynamic>> getDashboardStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return {
        'today_revenue': 0,
        'today_count': 0,
        'month_revenue': 0,
        'month_count': 0,
      };
    }
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final todayRows = await _supabase
        .from('transaksi')
        .select('total_bayar')
        .eq('user_id', userId)
        .eq('status', 'selesai')
        .gte('created_at', startOfDay.toIso8601String());
    final monthRows = await _supabase
        .from('transaksi')
        .select('total_bayar')
        .eq('user_id', userId)
        .eq('status', 'selesai')
        .gte('created_at', startOfMonth.toIso8601String());

    final todayRevenue = todayRows.fold<int>(
        0, (s, r) => s + ((r['total_bayar'] as num?)?.toInt() ?? 0));
    final monthRevenue = monthRows.fold<int>(
        0, (s, r) => s + ((r['total_bayar'] as num?)?.toInt() ?? 0));

    return {
      'today_revenue': todayRevenue,
      'today_count': todayRows.length,
      'month_revenue': monthRevenue,
      'month_count': monthRows.length,
    };
  }
}
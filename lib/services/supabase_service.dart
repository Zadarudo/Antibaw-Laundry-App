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
}
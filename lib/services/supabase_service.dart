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
}
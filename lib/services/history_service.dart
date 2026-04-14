import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class HistoryService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final data = await _client
        .from('transactions')
        .select()
        .order('transaction_time', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}
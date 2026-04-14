import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class DashboardService {
  final SupabaseClient _client = SupabaseService.client;

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final transactions = await _client
        .from('transactions')
        .select()
        .order('created_at', ascending: false);

    final items = await _client.from('transaction_items').select();

    final trxList = List<Map<String, dynamic>>.from(transactions);
    final itemList = List<Map<String, dynamic>>.from(items);

    int totalSales = 0;
    int totalTransactions = trxList.length;
    int totalCash = 0;
    int totalQris = 0;

    for (final trx in trxList) {
      final total = (trx['total'] ?? 0) as int;
      totalSales += total;

      final method = (trx['payment_method'] ?? '').toString().toLowerCase();
      if (method == 'cash' || method == 'tunai') {
        totalCash += total;
      } else if (method == 'qris') {
        totalQris += total;
      }
    }

    final Map<String, int> menuCounter = {};
    for (final item in itemList) {
      final menuName = (item['menu_name'] ?? '-').toString();
      final qty = (item['qty'] ?? 0) as int;
      menuCounter[menuName] = (menuCounter[menuName] ?? 0) + qty;
    }

    String bestMenu = '-';
    int bestQty = 0;

    menuCounter.forEach((key, value) {
      if (value > bestQty) {
        bestMenu = key;
        bestQty = value;
      }
    });

    return {
      'totalSales': totalSales,
      'totalTransactions': totalTransactions,
      'totalCash': totalCash,
      'totalQris': totalQris,
      'bestMenu': bestMenu,
      'bestQty': bestQty,
      'recentTransactions': trxList.take(5).toList(),
    };
  }
}
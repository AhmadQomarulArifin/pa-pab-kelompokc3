import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class TransactionService {
  final SupabaseClient _client = SupabaseService.client;

  Future<void> createTransaction({
    required String cashierId,
    required List<Map<String, dynamic>> cartItems,
    required String paymentMethod,
    String? customerName,
  }) async {
    try {
      if (cartItems.isEmpty) {
        throw Exception('Keranjang kosong.');
      }

      final normalizedPaymentMethod = paymentMethod.trim().toLowerCase();
      if (normalizedPaymentMethod != 'tunai' &&
          normalizedPaymentMethod != 'qris') {
        throw Exception('Metode pembayaran tidak valid.');
      }

      final subtotal = _calculateSubtotal(cartItems);
      final tax = (subtotal * 0.1).toInt();
      final total = subtotal + tax;
      final nowUtc = DateTime.now().toUtc();
      final invoiceCode = 'TRX-${DateTime.now().millisecondsSinceEpoch}';

      final Map<String, double> totalIngredientUsage = {};
      final Map<String, String> ingredientNames = {};
      final Map<String, String> ingredientUnits = {};

      for (final item in cartItems) {
        final menuId = item['id'];
        final qty = (item['qty'] ?? 0) as int;

        if (qty <= 0) continue;

        final recipeItems = await _client
            .from('menu_ingredients')
            .select('ingredient_id, qty_used, ingredients(name, unit)')
            .eq('menu_id', menuId);

        final recipeList = List<Map<String, dynamic>>.from(recipeItems);

        if (recipeList.isEmpty) {
          continue;
        }

        for (final recipe in recipeList) {
          final ingredientId = recipe['ingredient_id'].toString();
          final qtyUsed = (recipe['qty_used'] as num?)?.toDouble() ?? 0;
          final totalUsed = qtyUsed * qty;

          totalIngredientUsage[ingredientId] =
              (totalIngredientUsage[ingredientId] ?? 0) + totalUsed;

          final ingredientData = recipe['ingredients'];
          if (ingredientData is Map<String, dynamic>) {
            ingredientNames[ingredientId] =
                (ingredientData['name'] ?? '-').toString();
            ingredientUnits[ingredientId] =
                (ingredientData['unit'] ?? '').toString();
          }
        }
      }

      for (final entry in totalIngredientUsage.entries) {
        final ingredientId = entry.key;
        final requiredQty = entry.value;

        final ingredient = await _client
            .from('ingredients')
            .select('stock, name, unit')
            .eq('id', ingredientId)
            .single();

        final currentStock = (ingredient['stock'] as num?)?.toDouble() ?? 0;
        final ingredientName =
            (ingredient['name'] ?? ingredientNames[ingredientId] ?? '-')
                .toString();
        final unit =
            (ingredient['unit'] ?? ingredientUnits[ingredientId] ?? '')
                .toString();

        if (currentStock < requiredQty) {
          throw Exception(
            'Stok bahan tidak cukup untuk "$ingredientName". '
            'Butuh ${requiredQty.toStringAsFixed(requiredQty % 1 == 0 ? 0 : 2)} $unit, '
            'stok tersedia ${currentStock.toStringAsFixed(currentStock % 1 == 0 ? 0 : 2)} $unit.',
          );
        }
      }

      final trx = await _client
          .from('transactions')
          .insert({
            'invoice_code': invoiceCode,
            'cashier_id': cashierId,
            'customer_name': customerName == null || customerName.trim().isEmpty
                ? null
                : customerName.trim(),
            'payment_method': normalizedPaymentMethod,
            'total': total,
            'status': 'baru',
            'transaction_time': nowUtc.toIso8601String(),
            'created_at': nowUtc.toIso8601String(),
          })
          .select()
          .single();

      final trxId = trx['id'];

      for (final item in cartItems) {
        final menuId = item['id'];
        final menuName = item['name'];
        final price = (item['price'] ?? 0) as int;
        final qty = (item['qty'] ?? 0) as int;

        await _client.from('transaction_items').insert({
          'transaction_id': trxId,
          'menu_id': menuId,
          'menu_name': menuName,
          'price': price,
          'qty': qty,
          'subtotal': price * qty,
        });
      }

      for (final entry in totalIngredientUsage.entries) {
        final ingredientId = entry.key;
        final totalUsed = entry.value;

        final ingredient = await _client
            .from('ingredients')
            .select('stock, name')
            .eq('id', ingredientId)
            .single();

        final currentStock = (ingredient['stock'] as num?)?.toDouble() ?? 0;
        final newStock = currentStock - totalUsed;
        final ingredientName = (ingredient['name'] ?? '-').toString();

        await _client.from('ingredients').update({
          'stock': newStock < 0 ? 0 : newStock,
        }).eq('id', ingredientId);

        await _client.from('stock_logs').insert({
          'ingredient_id': ingredientId,
          'user_id': cashierId,
          'type': 'out',
          'qty': totalUsed,
          'note': 'Dipakai untuk transaksi: $ingredientName',
          'created_at': nowUtc.toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Checkout gagal: $e');
    }
  }

  int _calculateSubtotal(List<Map<String, dynamic>> items) {
    return items.fold<int>(
      0,
      (sum, item) =>
          sum + (((item['price'] ?? 0) as int) * ((item['qty'] ?? 0) as int)),
    );
  }
}
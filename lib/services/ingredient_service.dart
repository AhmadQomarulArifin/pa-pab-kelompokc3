import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class IngredientService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<Map<String, dynamic>>> getIngredients() async {
    final data = await _client
        .from('ingredients')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addIngredient({
    required String name,
    required String unit,
    required num stock,
    required num minimumStock,
    String? expiryDate,
    String? imageUrl,
  }) async {
    await _client.from('ingredients').insert({
      'name': name,
      'unit': unit,
      'stock': stock,
      'minimum_stock': minimumStock,
      'expiry_date': expiryDate?.isEmpty == true ? null : expiryDate,
      'image_url': imageUrl,
    });
  }

  Future<void> updateIngredient({
    required String id,
    required String name,
    required String unit,
    required num stock,
    required num minimumStock,
    String? expiryDate,
    String? imageUrl,
  }) async {
    await _client.from('ingredients').update({
      'name': name,
      'unit': unit,
      'stock': stock,
      'minimum_stock': minimumStock,
      'expiry_date': expiryDate?.isEmpty == true ? null : expiryDate,
      'image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteIngredient(String id) async {
    try {
      
      await _client
          .from('menu_ingredients')
          .delete()
          .eq('ingredient_id', id);

    
      await _client
          .from('stock_logs')
          .delete()
          .eq('ingredient_id', id);

      

      
      await _client
          .from('ingredients')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus bahan: $e');
    }
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class MenuService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<Map<String, dynamic>>> getMenus() async {
    final data = await _client
        .from('menus')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addMenu({
    required String name,
    required String category,
    required int price,
    String? description,
    bool isAvailable = true,
    String? imageUrl,
  }) async {
    await _client.from('menus').insert({
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'is_available': isAvailable,
      'image_url': imageUrl,
    });
  }

  Future<void> updateMenu({
    required String id,
    required String name,
    required String category,
    required int price,
    String? description,
    required bool isAvailable,
    String? imageUrl,
  }) async {
    await _client.from('menus').update({
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'is_available': isAvailable,
      'image_url': imageUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteMenu(String id) async {
    try {
      await _client.from('menu_ingredients').delete().eq('menu_id', id);

      await _client.from('transaction_items').delete().eq('menu_id', id);

      await _client.from('menus').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus menu: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getIngredients() async {
    final data = await _client
        .from('ingredients')
        .select('id, name, unit, stock')
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getMenuIngredients(String menuId) async {
    final data = await _client
        .from('menu_ingredients')
        .select('id, menu_id, ingredient_id, qty_used')
        .eq('menu_id', menuId);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> saveMenuIngredients({
    required String menuId,
    required List<Map<String, dynamic>> items,
  }) async {
    await _client.from('menu_ingredients').delete().eq('menu_id', menuId);

    if (items.isEmpty) return;

    final payload = items.map((item) {
      return {
        'menu_id': menuId,
        'ingredient_id': item['ingredient_id'],
        'qty_used': item['qty_used'],
      };
    }).toList();

    await _client.from('menu_ingredients').insert(payload);
  }

  Future<List<Map<String, dynamic>>> getMenuIngredientsDetailed(
    String menuId,
  ) async {
    final rawRelations = await _client
        .from('menu_ingredients')
        .select('ingredient_id, qty_used')
        .eq('menu_id', menuId);

    final relations = List<Map<String, dynamic>>.from(rawRelations);

    if (relations.isEmpty) return [];

    final ingredientIds =
        relations.map((e) => e['ingredient_id'].toString()).toList();

    final rawIngredients = await _client
        .from('ingredients')
        .select('id, name, unit, stock')
        .inFilter('id', ingredientIds);

    final ingredients = List<Map<String, dynamic>>.from(rawIngredients);

    final ingredientMap = {
      for (final item in ingredients) item['id'].toString(): item,
    };

    return relations.map((relation) {
      final ingredient =
          ingredientMap[relation['ingredient_id'].toString()] ??
              <String, dynamic>{};

      return {
        'ingredient_id': relation['ingredient_id'],
        'qty_used': relation['qty_used'],
        'name': ingredient['name'] ?? '-',
        'unit': ingredient['unit'] ?? '',
        'stock': ingredient['stock'] ?? 0,
      };
    }).toList();
  }
}
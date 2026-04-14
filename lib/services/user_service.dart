import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class UserService {
  final SupabaseClient _client = SupabaseService.client;

  Future<void> createUserProfile({
    required String id,
    required String fullName,
    required String email,
    required String role,
  }) async {
    await _client.from('users').insert({
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'is_active': true,
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String id) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();

    return data;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final data = await _client
        .from('users')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateUser({
    required String id,
    required String fullName,
    required String email,
    required String role,
    required bool isActive,
  }) async {
    await _client.from('users').update({
      'full_name': fullName,
      'email': email,
      'role': role,
      'is_active': isActive,
    }).eq('id', id);
  }

  Future<void> deleteUser(String id) async {
    await _client.from('users').delete().eq('id', id);
  }
}
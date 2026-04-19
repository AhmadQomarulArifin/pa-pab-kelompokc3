import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  
  Future<void> saveLogin({
    required String userId,
    required String email,
  }) async {
    await _storage.write(key: 'user_id', value: userId);
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'is_logged_in', value: 'true');
  }

  
  Future<bool> isLoggedIn() async {
    final value = await _storage.read(key: 'is_logged_in');
    return value == 'true';
  }


  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: 'email');
  }

  
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
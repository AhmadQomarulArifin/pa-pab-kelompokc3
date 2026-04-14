import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndUploadMenuImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) return null;

      final Uint8List bytes = await pickedFile.readAsBytes();
      final String fileName =
          'menu_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _client.storage.from('menu-images').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final String publicUrl =
          _client.storage.from('menu-images').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Upload gambar menu gagal: $e');
    }
  }

  Future<String?> pickAndUploadIngredientImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) return null;

      final Uint8List bytes = await pickedFile.readAsBytes();
      final String fileName =
          'ingredient_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _client.storage.from('ingredients').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final String publicUrl =
          _client.storage.from('ingredients').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Upload gambar bahan gagal: $e');
    }
  }
}
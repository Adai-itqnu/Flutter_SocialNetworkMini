import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ImgBBService {
  // Read from --dart-define first (production), fallback to .env (development)
  static final String _apiKey = const String.fromEnvironment('IMGBB_API_KEY').isNotEmpty
      ? const String.fromEnvironment('IMGBB_API_KEY')
      : (dotenv.env['IMGBB_API_KEY'] ?? '');
  static const String _baseUrl = 'https://api.imgbb.com/1/upload';

  // Upload image to ImgBB - Web compatible version
  static Future<String> uploadImage(XFile imageFile) async {
    if (_apiKey.isEmpty) {
      throw Exception(
          'ImgBB API key không được tìm thấy. Vui lòng build với: --dart-define=IMGBB_API_KEY=your_key');
    }

    try {
      // Read file as bytes (works on all platforms)
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Create form data
      FormData formData = FormData.fromMap({
        'key': _apiKey,
        'image': base64Image,
      });

      // Make POST request
      Dio dio = Dio();
      Response response = await dio.post(_baseUrl, data: formData);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          // Return image URL
          return data['data']['url'] as String;
        } else {
          throw Exception('Upload thất bại: ${data['error']['message']}');
        }
      } else {
        throw Exception('Upload thất bại: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            'Upload thất bại: ${e.response?.data['error']['message'] ?? e.message}');
      } else {
        throw Exception('Lỗi kết nối: ${e.message}');
      }
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Upload multiple images
  static Future<List<String>> uploadMultipleImages(
      List<XFile> imageFiles) async {
    List<String> imageUrls = [];

    for (XFile file in imageFiles) {
      try {
        String url = await uploadImage(file);
        imageUrls.add(url);
      } catch (e) {
        // If one fails, continue with others but log error
        print('Failed to upload image: $e');
      }
    }

    if (imageUrls.isEmpty && imageFiles.isNotEmpty) {
      throw Exception('Không thể upload bất kỳ ảnh nào');
    }

    return imageUrls;
  }
}

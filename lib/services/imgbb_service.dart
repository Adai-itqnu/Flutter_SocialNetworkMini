import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../utils/app_logger.dart';

/// Service upload ảnh lên ImgBB
class ImgBBService {
  // API key từ --dart-define (production) hoặc .env (development)
  static final String _apiKey = const String.fromEnvironment('IMGBB_API_KEY').isNotEmpty
      ? const String.fromEnvironment('IMGBB_API_KEY')
      : (dotenv.env['IMGBB_API_KEY'] ?? '');
  static const String _baseUrl = 'https://api.imgbb.com/1/upload';

  // Upload 1 ảnh lên ImgBB
  static Future<String> uploadImage(XFile imageFile) async {
    if (_apiKey.isEmpty) {
      throw Exception('ImgBB API key không được tìm thấy. Vui lòng build với: --dart-define=IMGBB_API_KEY=your_key');
    }

    try {
      // Đọc file thành bytes (hoạt động trên mọi nền tảng)
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Gửi request
      final formData = FormData.fromMap({'key': _apiKey, 'image': base64Image});
      final response = await Dio().post(_baseUrl, data: formData);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) return data['data']['url'] as String;
        throw Exception('Upload thất bại: ${data['error']['message']}');
      }
      throw Exception('Upload thất bại: HTTP ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response != null) throw Exception('Upload thất bại: ${e.response?.data['error']['message'] ?? e.message}');
      throw Exception('Lỗi kết nối: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Upload nhiều ảnh
  static Future<List<String>> uploadMultipleImages(List<XFile> imageFiles) async {
    List<String> imageUrls = [];

    for (XFile file in imageFiles) {
      try {
        String url = await uploadImage(file);
        imageUrls.add(url);
      } catch (e) {
        AppLogger.warn('Lỗi upload ảnh: $e');
      }
    }

    if (imageUrls.isEmpty && imageFiles.isNotEmpty) {
      throw Exception('Không thể upload bất kỳ ảnh nào');
    }

    return imageUrls;
  }
}

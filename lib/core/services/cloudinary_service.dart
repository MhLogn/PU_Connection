import 'dart:io';
import 'package:dio/dio.dart';

class CloudinaryService {
  final Dio _dio;

  static const String defaultCloudName = 'pu-connection';
  static const String defaultUploadPreset = 'pu_unsigned_preset';

  String cloudName;
  String uploadPreset;

  CloudinaryService({
    Dio? dio,
    this.cloudName = defaultCloudName,
    this.uploadPreset = defaultUploadPreset,
  }) : _dio = dio ?? Dio();

  void configure({required String cloudName, required String uploadPreset}) {
    this.cloudName = cloudName;
    this.uploadPreset = uploadPreset;
  }

  Future<String?> uploadImage(File file, {String folder = 'pu_connection/images'}) async {
    return _uploadFile(file: file, resourceType: 'image', folder: folder);
  }

  Future<String?> uploadDocument(File file, {String folder = 'pu_connection/documents'}) async {
    return _uploadFile(file: file, resourceType: 'raw', folder: folder);
  }

  Future<String?> _uploadFile({
    required File file,
    required String resourceType,
    required String folder,
  }) async {
    try {
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';
      final fileName = file.path.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'upload_preset': uploadPreset,
        'folder': folder,
      });

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {'Accept': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['secure_url'] as String?;
      } else {
        final errorMessage = response.data?['error']?['message'] ?? 'Upload failed';
        throw Exception('Cloudinary upload error: $errorMessage (code: ${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }
}

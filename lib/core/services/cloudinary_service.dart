import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final Dio _dio;

  static const String defaultCloudName = 'kh2kphrq';
  static const String defaultUploadPreset = 'pu_connection';

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

  /// Tải lên tệp ảnh/tài liệu từ XFile (hoạt động đa nền tảng: Web, Android, iOS, Windows, Desktop)
  Future<String?> uploadXFile(
    XFile xFile, {
    String folder = 'pu_connection/images',
    String resourceType = 'image',
  }) async {
    final bytes = await xFile.readAsBytes();
    final name = xFile.name.isNotEmpty
        ? xFile.name
        : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadBytes(
      bytes: bytes,
      fileName: name,
      folder: folder,
      resourceType: resourceType,
    );
  }

  /// Tải lên tệp từ mảng byte trực tiếp (Cross-platform và không phụ thuộc filesystem)
  Future<String?> uploadBytes({
    required List<int> bytes,
    required String fileName,
    String resourceType = 'image',
    String folder = 'pu_connection/images',
  }) async {
    try {
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';
      final cleanFileName = fileName.replaceAll(r'\', '/').split('/').last;

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: cleanFileName),
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

  Future<String?> uploadImage(File file, {String folder = 'pu_connection/images'}) async {
    try {
      final bytes = await file.readAsBytes();
      final cleanFileName = file.path.replaceAll(r'\', '/').split('/').last;
      return uploadBytes(
        bytes: bytes,
        fileName: cleanFileName,
        resourceType: 'image',
        folder: folder,
      );
    } catch (_) {
      return _uploadFile(file: file, resourceType: 'image', folder: folder);
    }
  }

  Future<String?> uploadDocument(File file, {String folder = 'pu_connection/documents'}) async {
    try {
      final bytes = await file.readAsBytes();
      final cleanFileName = file.path.replaceAll(r'\', '/').split('/').last;
      return uploadBytes(
        bytes: bytes,
        fileName: cleanFileName,
        resourceType: 'auto',
        folder: folder,
      );
    } catch (_) {
      return _uploadFile(file: file, resourceType: 'auto', folder: folder);
    }
  }

  Future<String?> _uploadFile({
    required File file,
    required String resourceType,
    required String folder,
  }) async {
    try {
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';
      final fileName = file.path.replaceAll(r'\', '/').split('/').last;

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

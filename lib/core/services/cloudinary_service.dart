import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final Dio _dio;

  static const String defaultCloudName = 'kh2kphrq';
  static const String defaultUploadPreset = 'pu_connection';

  /// Giới hạn dung lượng an toàn để chống tràn quota và lạm dụng bộ nhớ
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxDocumentSizeBytes = 25 * 1024 * 1024; // 25MB

  /// Định dạng tệp cho phép
  static const Set<String> allowedImageExtensions = {
    'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'
  };
  static const Set<String> allowedDocumentExtensions = {
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'
  };

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
      final cleanFileName = fileName.replaceAll(r'\', '/').split('/').last;
      final ext = cleanFileName.contains('.')
          ? cleanFileName.split('.').last.toLowerCase()
          : '';

      // Kiểm tra dung lượng tệp
      if (resourceType == 'image') {
        if (bytes.length > maxImageSizeBytes) {
          throw Exception('Dung lượng ảnh vượt quá giới hạn 10MB.');
        }
        if (ext.isNotEmpty && !allowedImageExtensions.contains(ext)) {
          throw Exception('Định dạng ảnh .$ext không được hỗ trợ.');
        }
      } else {
        if (bytes.length > maxDocumentSizeBytes) {
          throw Exception('Dung lượng tệp vượt quá giới hạn 25MB.');
        }
        if (ext.isNotEmpty && !allowedDocumentExtensions.contains(ext) && !allowedImageExtensions.contains(ext)) {
          throw Exception('Định dạng tệp .$ext không được hỗ trợ.');
        }
      }

      final url =
          'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';

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
        final errorMessage =
            response.data?['error']?['message'] ?? 'Upload failed';
        throw Exception(
          'Cloudinary upload error: $errorMessage (code: ${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadImage(
    File file, {
    String folder = 'pu_connection/images',
  }) async {
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

  Future<String?> uploadDocument(
    File file, {
    String folder = 'pu_connection/documents',
  }) async {
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
      final url =
          'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';
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
        final errorMessage =
            response.data?['error']?['message'] ?? 'Upload failed';
        throw Exception(
          'Cloudinary upload error: $errorMessage (code: ${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

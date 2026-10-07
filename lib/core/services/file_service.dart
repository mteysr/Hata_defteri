import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileService {
  static final FileService instance = FileService._init();
  FileService._init();

  static String? _appDocsDirPath;

  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _appDocsDirPath = directory.path;
    } catch (e) {
      print('Error initializing FileService: $e');
    }
  }

  static String get appDocsDirPath {
    return _appDocsDirPath ?? '';
  }

  // Resolves any path (absolute or relative/filename) to the current container's absolute path
  static String getActualPath(String savedPath) {
    if (savedPath.isEmpty) return '';
    if (savedPath.startsWith('http') || savedPath.startsWith('assets/')) {
      return savedPath;
    }
    
    // If the file exists directly at the given path (e.g., temporary file picked from picker),
    // we use it as is.
    try {
      if (File(savedPath).existsSync()) {
        return savedPath;
      }
    } catch (_) {}
    
    // Extract only the filename from the savedPath (handles legacy absolute paths and new relative names)
    final fileName = p.basename(savedPath);
    
    // Combine with the current container's documents directory
    final baseDir = _appDocsDirPath ?? '';
    return p.join(baseDir, 'mistake_images', fileName);
  }

  Future<String> saveImage(String originalPath) async {
    if (originalPath.isEmpty) return '';
    try {
      final file = File(originalPath);
      if (!await file.exists()) return '';

      // Ensure directory exists
      final baseDir = _appDocsDirPath ?? (await getApplicationDocumentsDirectory()).path;
      if (_appDocsDirPath == null) {
        _appDocsDirPath = baseDir;
      }
      
      final imagesDir = Directory(p.join(baseDir, 'mistake_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final extension = p.extension(originalPath);
      final newFileName = '${const Uuid().v4()}$extension';
      final targetPath = p.join(imagesDir.path, newFileName);

      await file.copy(targetPath);
      return newFileName; // Save ONLY the filename (relative path)!
    } catch (e) {
      print('Error saving image: $e');
      return '';
    }
  }

  Future<bool> deleteImage(String? path) async {
    if (path == null || path.isEmpty) return false;
    try {
      final actualPath = getActualPath(path);
      final file = File(actualPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}

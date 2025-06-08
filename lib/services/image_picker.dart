import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickAndSaveImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      final appDir = await getApplicationDocumentsDirectory();
      final dataDir = Directory(p.join(appDir.path, 'data'));
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }

      final fileName = p.basename(pickedFile.path);
      final destPath = p.join(dataDir.path, fileName);
      final destFile = File(destPath);
      await destFile.writeAsBytes(bytes);

      return destFile;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
}

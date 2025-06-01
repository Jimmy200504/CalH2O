import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImagePickerService {
  static Future<File?> pickAndSaveImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return null;

    final srcPath = result.files.single.path!;
    final bytes = await File(srcPath).readAsBytes();

    final appDir = await getApplicationDocumentsDirectory();
    final dataDir = Directory(p.join(appDir.path, 'data'));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    final fileName = p.basename(srcPath);
    final destPath = p.join(dataDir.path, fileName);
    final destFile = File(destPath);
    await destFile.writeAsBytes(bytes);

    return destFile;
  }
}

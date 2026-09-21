import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<String?> exportPdf({
  required Uint8List bytes,
  required String filename,
  required String title,
}) async {
  final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
  if (Platform.isLinux) {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw const FileSystemException('Home directory is unavailable.');
    }
    final downloads = Directory('$home/Downloads');
    if (!await downloads.exists()) await downloads.create(recursive: true);
    final file = File('${downloads.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(bytes, mimeType: 'application/pdf', name: safeName),
      ],
      title: title,
    ),
  );
  return null;
}

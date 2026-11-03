import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

const pdfMimeType = 'application/pdf';
const xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

Future<String?> exportPdf({
  required Uint8List bytes,
  required String filename,
  required String title,
}) => exportFile(
  bytes: bytes,
  filename: filename,
  title: title,
  mimeType: pdfMimeType,
);

Future<String?> exportFile({
  required Uint8List bytes,
  required String filename,
  required String title,
  required String mimeType,
}) async {
  // Keep letters from any script so Arabic client names survive; only
  // characters that are unsafe in file names are replaced.
  final safeName = filename.replaceAll(
    RegExp(r'[^\p{L}\p{N}._-]', unicode: true),
    '-',
  );
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
      files: [XFile.fromData(bytes, mimeType: mimeType, name: safeName)],
      title: title,
    ),
  );
  return null;
}

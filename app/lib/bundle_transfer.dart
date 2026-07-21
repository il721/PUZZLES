import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Moves bundle text between the app and the device's file system.
///
/// Split out from the settings screen so widget tests can drive the whole
/// export/import flow without a native file dialog.
abstract class BundleTransfer {
  /// Asks the user where to put [jsonText] and writes it.
  ///
  /// Returns false if the user cancelled or the write failed. Implementations
  /// must not throw.
  Future<bool> saveBundle(String jsonText, String suggestedFileName);

  /// Asks the user to pick a bundle file and returns its text.
  ///
  /// Returns null if the user cancelled or the file could not be read.
  /// Implementations must not throw.
  Future<String?> pickBundle();
}

/// [BundleTransfer] backed by the platform file dialogs.
///
/// On Android `saveFile` needs the content up front (`bytes:`) because the
/// write happens through the Storage Access Framework rather than a raw
/// path; on Windows it returns a path and we write it ourselves. Passing
/// `bytes:` on both platforms keeps one code path — on desktop the plugin
/// writes the bytes for us.
class FilePickerBundleTransfer implements BundleTransfer {
  /// Creates a file-dialog-backed transfer.
  const FilePickerBundleTransfer();

  @override
  Future<bool> saveBundle(String jsonText, String suggestedFileName) async {
    try {
      final bytes = utf8.encode(jsonText);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Puzzle Book',
        fileName: suggestedFileName,
        bytes: bytes,
      );
      if (path == null) return false;

      // On desktop the plugin may return the chosen path without having
      // written anything; writing again is harmless and makes the desktop
      // path explicit.
      final file = File(path);
      if (!await file.exists() || await file.length() != bytes.length) {
        await file.writeAsBytes(bytes, flush: true);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> pickBundle() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Puzzle Book',
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;

      final picked = result.files.single;
      final bytes = picked.bytes;
      if (bytes != null) return utf8.decode(bytes, allowMalformed: true);

      final path = picked.path;
      if (path == null) return null;
      return await File(path).readAsString();
    } catch (_) {
      return null;
    }
  }
}

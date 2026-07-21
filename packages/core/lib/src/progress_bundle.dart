import 'dart:convert';

/// Raised when a bundle's text cannot be understood.
///
/// [isVersionTooNew] distinguishes "this file was written by a newer build
/// of the app" (the user should update, and the data is probably fine) from
/// "this file is not a bundle" (the user picked the wrong file).
class BundleFormatException implements Exception {
  /// Human-readable cause, for logs. Not shown to the player directly —
  /// the UI picks a localized message off [isVersionTooNew].
  final String reason;

  /// Whether the failure was specifically a `bundleVersion` newer than
  /// [ProgressBundle.currentBundleVersion].
  final bool isVersionTooNew;

  /// Creates a format exception.
  const BundleFormatException(this.reason, {this.isVersionTooNew = false});

  @override
  String toString() => 'BundleFormatException: $reason';
}

/// A portable snapshot of every puzzle module's save data, suitable for
/// carrying between installs on different devices.
///
/// Deliberately excludes the `settings` namespace: language, sound and
/// theme are per-device preferences, not progress.
class ProgressBundle {
  /// Bundle format version written by this build. [decode] rejects any
  /// bundle claiming a higher version.
  static const int currentBundleVersion = 1;

  /// The `bundleVersion` this instance carries.
  final int bundleVersion;

  /// ISO-8601 local timestamp of when the bundle was produced. Shown to
  /// the player in the import confirmation dialog; never used for merge
  /// decisions.
  final String exportedAt;

  /// Save-namespace name -> that namespace's whole `data` map.
  final Map<String, Map<String, dynamic>> namespaces;

  /// Creates a bundle.
  const ProgressBundle({
    required this.bundleVersion,
    required this.exportedAt,
    required this.namespaces,
  });

  /// Serializes this bundle to indented JSON (indented so a curious player
  /// opening the file in a text editor sees something readable).
  String encode() {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'bundleVersion': bundleVersion,
      'exportedAt': exportedAt,
      'namespaces': namespaces,
    });
  }

  /// Parses [jsonText].
  ///
  /// Throws [BundleFormatException] if the text is not JSON, is not a JSON
  /// object, lacks an integer `bundleVersion`, claims a version newer than
  /// [currentBundleVersion], or has a `namespaces` entry that is not an
  /// object. A missing `namespaces` key is treated as empty.
  static ProgressBundle decode(String jsonText) {
    Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (e) {
      throw BundleFormatException('unparseable JSON: $e');
    }

    if (decoded is! Map) {
      throw const BundleFormatException('top-level JSON value is not an object');
    }

    final version = decoded['bundleVersion'];
    if (version is! int) {
      throw BundleFormatException('missing or non-integer bundleVersion: $version');
    }
    if (version > currentBundleVersion) {
      throw BundleFormatException(
        'bundleVersion $version is newer than supported $currentBundleVersion',
        isVersionTooNew: true,
      );
    }

    final rawExportedAt = decoded['exportedAt'];
    final exportedAt = rawExportedAt is String ? rawExportedAt : '';

    final rawNamespaces = decoded['namespaces'];
    final namespaces = <String, Map<String, dynamic>>{};
    if (rawNamespaces is Map) {
      for (final entry in rawNamespaces.entries) {
        final value = entry.value;
        if (value is! Map) {
          throw BundleFormatException('namespace "${entry.key}" is not an object');
        }
        namespaces['${entry.key}'] = Map<String, dynamic>.from(value);
      }
    } else if (rawNamespaces != null) {
      throw const BundleFormatException('namespaces is not an object');
    }

    return ProgressBundle(
      bundleVersion: version,
      exportedAt: exportedAt,
      namespaces: namespaces,
    );
  }
}

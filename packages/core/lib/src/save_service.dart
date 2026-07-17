import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'logger.dart';

/// Persists per-module save data as JSON files, one file per namespace, in
/// a directory supplied by an injected [Directory] provider.
///
/// Each namespace's file has the shape `{"schemaVersion": 1, "data": {...}}`
/// at `<base>/<namespace>.json`.
///
/// ### Concurrency
/// All writes to the same namespace are serialized: [save] chains each
/// write onto the previous write's completion (success or failure) for
/// that namespace, so writes for a namespace never interleave and always
/// land in call order.
///
/// ### Atomicity
/// Each write is performed by writing to a uniquely-named temporary file in
/// the same directory, then moving it onto the target file. The move
/// prefers an atomic [File.rename]; if that fails with a
/// [FileSystemException] (as `rename` does on Windows when the destination
/// already exists), the target is deleted first and the rename retried.
///
/// ### Corruption handling
/// [load] never throws and never silently discards evidence of corruption:
/// a file that fails to parse as JSON, or whose `schemaVersion` is missing
/// or newer than this service understands, is renamed to a `.bak` sidecar
/// (preserving its contents for inspection) and treated as an empty save.
class SaveService {
  /// Current schema version written by this service. [load] rejects (and
  /// quarantines) files with a schema version greater than this.
  static const int currentSchemaVersion = 1;

  static int _tempCounter = 0;

  final Directory Function() _baseDirProvider;
  final AppLogger? _logger;

  /// Per-namespace queue of the in-flight/most-recently-scheduled write, so
  /// concurrent [save] calls for the same namespace are serialized.
  final Map<String, Future<void>> _queues = <String, Future<void>>{};

  /// Creates a save service.
  ///
  /// [baseDirProvider] is invoked fresh each time a directory is needed
  /// (rather than resolved once at construction), matching how the Flutter
  /// layer will supply a `path_provider`-backed directory. [logger], if
  /// given, receives diagnostic messages (in particular, corruption
  /// quarantine events).
  SaveService(this._baseDirProvider, {AppLogger? logger}) : _logger = logger;

  /// Loads the persisted data for [namespace].
  ///
  /// Returns an empty map if no save file exists yet, if the file cannot be
  /// parsed as JSON, or if its `schemaVersion` is missing or newer than
  /// [currentSchemaVersion]. In the latter two cases the offending file is
  /// preserved as a `.bak` sidecar and a diagnostic is logged; this method
  /// never throws.
  Future<Map<String, dynamic>> load(String namespace) async {
    final file = _targetFile(namespace);
    if (!await file.exists()) {
      return <String, dynamic>{};
    }

    String content;
    try {
      content = await file.readAsString();
    } catch (e, st) {
      _logger?.log(
        'SaveService: failed to read save file for "$namespace"',
        error: e,
        stackTrace: st,
      );
      return <String, dynamic>{};
    }

    Object? decoded;
    try {
      decoded = jsonDecode(content);
    } catch (e, st) {
      await _quarantine(file, reason: 'unparseable JSON', error: e, stackTrace: st);
      return <String, dynamic>{};
    }

    if (decoded is! Map<String, dynamic>) {
      await _quarantine(file, reason: 'top-level JSON value is not an object');
      return <String, dynamic>{};
    }

    final schemaVersion = decoded['schemaVersion'];
    final validVersion = schemaVersion is int && schemaVersion <= currentSchemaVersion;
    if (!validVersion) {
      await _quarantine(
        file,
        reason: 'missing or unsupported schemaVersion: $schemaVersion',
      );
      return <String, dynamic>{};
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  /// Persists [data] under [namespace], serialized with respect to any
  /// other in-flight or queued [save] call for the same namespace.
  ///
  /// The returned future completes when this particular write has been
  /// durably applied (or fails with the error that write raised); it does
  /// not swallow errors, but a failed write does not block subsequent
  /// writes to the same namespace from proceeding.
  Future<void> save(String namespace, Map<String, dynamic> data) {
    final previous = _queues[namespace] ?? Future<void>.value();
    final resultCompleter = Completer<void>();

    // Wait for the previous write (regardless of its outcome) before
    // starting this one, so writes never interleave.
    previous.whenComplete(() {
      _writeNow(namespace, data).then(
        resultCompleter.complete,
        onError: resultCompleter.completeError,
      );
    });

    final result = resultCompleter.future;
    // Track completion (ignoring errors) as the new queue tail so the next
    // save() waits for this one without itself failing due to this write's
    // error.
    _queues[namespace] = result.catchError((_) {});
    return result;
  }

  Future<void> _writeNow(String namespace, Map<String, dynamic> data) async {
    final dir = _baseDirProvider();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final target = File('${dir.path}/$namespace.json');
    final tempFile = File(
      '${dir.path}/$namespace.${_tempCounter++}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );

    final payload = <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'data': data,
    };
    await tempFile.writeAsString(jsonEncode(payload), flush: true);

    try {
      await tempFile.rename(target.path);
    } on FileSystemException {
      // Windows cannot rename onto an existing file; clear the way and retry.
      if (await target.exists()) {
        await target.delete();
      }
      await tempFile.rename(target.path);
    }
  }

  Future<void> _quarantine(
    File file, {
    required String reason,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final backupPath = '${file.path}.${DateTime.now().microsecondsSinceEpoch}.bak';
    _logger?.log(
      'SaveService: quarantining corrupt save file "${file.path}" ($reason) -> "$backupPath"',
      error: error,
      stackTrace: stackTrace,
    );
    try {
      await file.rename(backupPath);
    } on FileSystemException {
      // Fall back to copy+delete if rename cannot cross whatever boundary
      // is in play (e.g. different filesystem/device).
      await file.copy(backupPath);
      await file.delete();
    }
  }

  File _targetFile(String namespace) {
    final dir = _baseDirProvider();
    return File('${dir.path}/$namespace.json');
  }
}

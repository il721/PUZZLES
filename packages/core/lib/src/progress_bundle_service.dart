import 'progress_bundle.dart';
import 'progress_merge.dart';
import 'save_service.dart';

/// Why an import was refused.
enum ImportError {
  /// The text was not a readable bundle — most likely the wrong file.
  badFormat,

  /// The bundle was written by a newer build of the app.
  versionTooNew,
}

/// The outcome of an import attempt.
class ImportReport {
  /// Whether the import was applied.
  final bool ok;

  /// Why it was refused; null when [ok].
  final ImportError? error;

  /// Totals across every namespace touched.
  final NamespaceCounts counts;

  /// The bundle's `exportedAt`, for display. Empty when unknown.
  final String exportedAt;

  /// Creates a report.
  const ImportReport({
    required this.ok,
    this.error,
    this.counts = const NamespaceCounts(),
    this.exportedAt = '',
  });
}

/// Produces and consumes portable progress bundles on top of [SaveService].
///
/// Export enumerates exactly [_exportNamespaces] — pass the registered
/// modules' `saveNamespace` values, which is what keeps the `settings`
/// namespace out of every bundle. Import deliberately does **not** filter:
/// it applies every namespace the bundle carries, so a bundle produced by a
/// newer build (with a module this one has never heard of) preserves that
/// module's data instead of dropping it.
class ProgressBundleService {
  final SaveService _saveService;
  final List<String> _exportNamespaces;

  /// Creates a bundle service over [saveService], exporting
  /// [exportNamespaces].
  ProgressBundleService(this._saveService, List<String> exportNamespaces)
      : _exportNamespaces = List<String>.unmodifiable(exportNamespaces);

  /// Reads every exported namespace and returns the bundle as JSON text.
  Future<String> exportJson() async {
    final namespaces = <String, Map<String, dynamic>>{};
    for (final ns in _exportNamespaces) {
      namespaces[ns] = await _saveService.load(ns);
    }

    final bundle = ProgressBundle(
      bundleVersion: ProgressBundle.currentBundleVersion,
      exportedAt: DateTime.now().toIso8601String(),
      namespaces: namespaces,
    );
    return bundle.encode();
  }

  /// Parses [jsonText] and merges it into local saves.
  ///
  /// Never throws: parse failures come back as a non-[ImportReport.ok]
  /// report. Nothing is written unless the whole bundle parsed, so a bad
  /// file cannot leave saves half-updated.
  Future<ImportReport> importJson(String jsonText) async {
    final ProgressBundle bundle;
    try {
      bundle = ProgressBundle.decode(jsonText);
    } on BundleFormatException catch (e) {
      return ImportReport(
        ok: false,
        error: e.isVersionTooNew ? ImportError.versionTooNew : ImportError.badFormat,
      );
    }

    var totals = const NamespaceCounts();
    for (final entry in bundle.namespaces.entries) {
      final local = await _saveService.load(entry.key);
      final result = mergeNamespaceData(local, entry.value);
      await _saveService.save(entry.key, result.data);
      totals = totals + result.counts;
    }

    return ImportReport(ok: true, counts: totals, exportedAt: bundle.exportedAt);
  }
}

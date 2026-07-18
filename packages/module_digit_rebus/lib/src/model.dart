import 'dart:convert';

/// One of the five book glyphs that mask a digit cell. Each glyph admits a
/// fixed set of digits (book p. 31).
enum Glyph {
  /// Closed loop centered on top - digits 0, 8, 9.
  g1({0, 8, 9}),

  /// Closed loop centered on bottom - digits 0, 6, 8.
  g2({0, 6, 8}),

  /// Straight stem on bottom - digits 1, 4, 7.
  g3({1, 4, 7}),

  /// Open loop on top - digits 2, 3.
  g4({2, 3}),

  /// Open hook on bottom - digits 3, 5, 9.
  g5({3, 5, 9});

  const Glyph(this.digits);

  /// The digits this glyph admits.
  final Set<int> digits;

  /// Parses the JSON code ("G1".."G5").
  static Glyph fromCode(String code) => switch (code) {
        'G1' => g1,
        'G2' => g2,
        'G3' => g3,
        'G4' => g4,
        'G5' => g5,
        _ => throw FormatException('Unknown glyph code "$code"'),
      };

  /// The JSON code ("G1".."G5").
  String get code => 'G${index + 1}';
}

/// A complete digit-rebus puzzle: a 4x4 grid of glyph-masked digit cells
/// where all four rows and all four columns are strict left-to-right
/// equations `c1 op1 c2 op2 c3 = c4` (the fourth row and fourth column
/// double as results and as equations of their own).
class DigitRebusPuzzle {
  /// Stable identifier within the module's data set (e.g. `p01`).
  final String id;

  /// Whether this is the introductory/tutorial puzzle.
  final bool tutorial;

  /// `glyphs[row][col]` - the glyph masking each of the 16 cells.
  final List<List<Glyph>> glyphs;

  /// `rowOps[row]` - the two operators of row `row`'s equation, applied
  /// left to right. Each is one of `+`, `-`, `*`, `:`.
  final List<List<String>> rowOps;

  /// `colOps[col]` - the two operators of column `col`'s equation, applied
  /// top to bottom.
  final List<List<String>> colOps;

  /// `answer[row][col]` - the book's printed solution digits. The win
  /// condition is constraint satisfaction, not answer match; the answer is
  /// kept for data verification and the tutorial.
  final List<List<int>> answer;

  /// Optional data note (e.g. a recorded book misprint).
  final String? note;

  /// Creates a puzzle.
  const DigitRebusPuzzle({
    required this.id,
    required this.tutorial,
    required this.glyphs,
    required this.rowOps,
    required this.colOps,
    required this.answer,
    this.note,
  });

  /// Parses a puzzle from its JSON object representation, matching one
  /// entry of the `puzzles` array in `assets/puzzles/module02.json`.
  factory DigitRebusPuzzle.fromJson(Map<String, dynamic> json) {
    return DigitRebusPuzzle(
      id: json['id'] as String,
      tutorial: json['tutorial'] as bool? ?? false,
      glyphs: (json['glyphs'] as List)
          .map((row) => (row as List)
              .map((code) => Glyph.fromCode(code as String))
              .toList(growable: false))
          .toList(growable: false),
      rowOps: _opsFromJson(json['rowOps']),
      colOps: _opsFromJson(json['colOps']),
      answer: (json['answer'] as List)
          .map((row) =>
              (row as List).map((d) => d as int).toList(growable: false))
          .toList(growable: false),
      note: json['note'] as String?,
    );
  }

  static List<List<String>> _opsFromJson(dynamic json) => (json as List)
      .map((row) =>
          (row as List).map((op) => op as String).toList(growable: false))
      .toList(growable: false);

  /// Parses a full module data file (matching the shape of
  /// `assets/puzzles/module02.json`) into its list of puzzles.
  static List<DigitRebusPuzzle> listFromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final puzzlesJson = decoded['puzzles'] as List;
    return puzzlesJson
        .map((e) => DigitRebusPuzzle.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

import 'dart:convert';

/// An immutable (row, col) grid coordinate. Row 0 is the top row, col 0 is
/// the leftmost column - this matches the book's own visual layout for
/// squareword (unlike `module_labyrinth`, which flips book row numbering;
/// squareword's book row N is already internal row 0). Value equality +
/// hashCode make this usable as a `Set`/`Map` key.
class Cell {
  final int row;
  final int col;

  const Cell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'Cell($row, $col)';
}

/// A single pre-filled cell in a squareword puzzle: its position and the
/// printed letter. Every puzzle's row 0 givens are the full keyword, in
/// column order; additional givens are scattered 3-letter secondary words
/// elsewhere in the grid.
class Given {
  final int row;
  final int col;
  final String letter;

  const Given(this.row, this.col, this.letter);

  /// Parses a `[row, col, letter]` JSON triple.
  factory Given.fromJson(List<dynamic> json) =>
      Given(json[0] as int, json[1] as int, json[2] as String);

  List<dynamic> toJson() => [row, col, letter];

  @override
  String toString() => 'Given($row, $col, "$letter")';
}

/// A complete squareword puzzle: an `n`x`n` grid built around an
/// `n`-letter Cyrillic [keyword], with some cells pre-filled ([givens]).
/// The player fills the rest so every row, every column, and both main
/// diagonals (top-left-to-bottom-right, top-right-to-bottom-left) contain
/// each of [keyword]'s `n` letters exactly once - a "diagonal Latin
/// square". `n` is 5, 6, or 7 depending on the puzzle; the model, grid
/// widget, and solver are all `n`-generic (no per-size code paths).
class SquarewordPuzzle {
  /// Stable identifier within the module's data set (e.g. `p01`, or
  /// `tutorial` for the book's worked example).
  final String id;

  /// Whether this is the introductory/tutorial example, not one of the 17
  /// numbered puzzles.
  final bool tutorial;

  /// Grid size: the number of rows, columns, and distinct keyword letters.
  final int n;

  /// The `n`-letter Cyrillic keyword this puzzle is built around. Always
  /// printed across row 0 (see [givens]) and, split into individual
  /// letters, the candidate alphabet for every cell in this puzzle - each
  /// puzzle has its own keyword/alphabet, not a module-wide shared one.
  final String keyword;

  /// The puzzle's pre-filled cells: always the full [keyword] across row
  /// 0, plus 1-3 scattered secondary 3-letter given words.
  final List<Given> givens;

  /// Creates a puzzle.
  const SquarewordPuzzle({
    required this.id,
    required this.tutorial,
    required this.n,
    required this.keyword,
    required this.givens,
  });

  /// The distinct letters of [keyword], in keyword order.
  List<String> get letters => keyword.split('');

  /// Parses a puzzle from its JSON object representation, matching one
  /// entry of the `puzzles` array in `assets/puzzles/module05.json`.
  ///
  /// Throws a [FormatException] naming [id] if [keyword]'s length does not
  /// match [n] - catching a gross transcription slip at parse time instead
  /// of as a mysterious solver result later. Deeper data invariants (row-0
  /// givens matching the keyword, every given letter being a keyword
  /// member, keyword letters being pairwise distinct) are checked in
  /// `test/data_test.dart`, not here, matching `LabyrinthPuzzle`'s split
  /// between parse-time structural checks and test-time data invariants.
  factory SquarewordPuzzle.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final n = json['n'] as int;
    final keyword = json['keyword'] as String;

    if (keyword.split('').length != n) {
      throw FormatException(
        'Puzzle "$id": keyword "$keyword" has '
        '${keyword.split('').length} letters, expected n=$n',
      );
    }

    final rawGivens = json['givens'] as List;
    final givens = rawGivens
        .map((g) => Given.fromJson(g as List))
        .toList(growable: false);

    return SquarewordPuzzle(
      id: id,
      tutorial: json['tutorial'] as bool? ?? false,
      n: n,
      keyword: keyword,
      givens: givens,
    );
  }

  /// Parses a full module data file (matching the shape of
  /// `assets/puzzles/module05.json`) into its list of puzzles.
  static List<SquarewordPuzzle> listFromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final puzzlesJson = decoded['puzzles'] as List;
    return puzzlesJson
        .map((e) => SquarewordPuzzle.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

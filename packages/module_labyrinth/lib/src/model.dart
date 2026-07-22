import 'dart:convert';

/// An immutable (row, col) grid coordinate. Row 0 is the top row, col 0 is
/// the leftmost column. Value equality + hashCode make this usable as a
/// `Set`/`Map` key.
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

/// The 33 letters of the Russian alphabet in dictionary order. This is the
/// canonical letter set used throughout the module: grid cells, the path
/// solution, and [letterGlyphs] all index into it.
const List<String> russianAlphabet = [
  'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'З', 'И',
  'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т',
  'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь',
  'Э', 'Ю', 'Я',
];

/// The single source of truth for the Cyrillic-to-glyph substitution used
/// to display this puzzle in EN/DE locales, where the grid is re-rendered
/// with non-Cyrillic stand-in glyphs rather than translated (the puzzle is
/// a path-through-symbols exercise, not a language one). L10n adapters
/// import this map rather than hard-coding their own copy.
///
/// All 33 values are pairwise distinct, so the substitution is a bijection
/// and the glyph grid preserves the same "each letter/glyph is either
/// unique or a matched pair" structure as the Cyrillic original.
const Map<String, String> letterGlyphs = {
  'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'G', 'Д': 'D',
  'Е': 'E', 'Ё': '=', 'Ж': '*', 'З': '3', 'И': 'I',
  'Й': 'J', 'К': 'K', 'Л': 'L', 'М': 'M', 'Н': 'N',
  'О': 'O', 'П': 'P', 'Р': 'R', 'С': 'S', 'Т': 'T',
  'У': 'U', 'Ф': 'F', 'Х': 'X', 'Ц': 'C', 'Ч': 'Q',
  'Ш': 'W', 'Щ': '#', 'Ъ': '&', 'Ы': r'$', 'Ь': '@',
  'Э': 'H', 'Ю': 'Y', 'Я': 'Z',
};

/// A complete alphabet-labyrinth puzzle: a fixed 8x8 grid of printed
/// uppercase Cyrillic letters that the player threads with a single
/// self-avoiding orthogonal path of exactly [pathLength] cells, starting at
/// `grid[0][0]` (always `А`) and ending at `grid[7][7]` (always `Я`), whose
/// letters are all 33 letters of the Russian alphabet, each exactly once.
///
/// Book coordinate convention: the book labels rows `8` (top) down to `1`
/// (bottom) and columns `a`..`h` (left to right). A book reference
/// `(bookRow, colLetter)` maps to the internal `(row, col)` used here via
/// `row = 8 - bookRow` and `col = colLetter.codeUnitAt(0) - 'a'.codeUnitAt(0)`.
/// This mapping is display-only (e.g. for citing a book page while
/// debugging data); nothing in this module stores book coordinates.
class LabyrinthPuzzle {
  /// Stable identifier within the module's data set (e.g. `p01`).
  final String id;

  /// Whether this is the introductory/tutorial puzzle.
  final bool tutorial;

  /// `grid[row][col]` - the printed letter at each of the 64 cells. Row 0
  /// is the top row, col 0 is the leftmost column.
  final List<List<String>> grid;

  /// The book's printed solution path, if recorded: the ordered sequence
  /// of [pathLength] cells from `А` to `Я`. The win condition is reaching
  /// any valid path, not matching this exact one; the solution is kept for
  /// data verification and the tutorial.
  final List<Cell>? solution;

  /// Optional data note (e.g. a recorded book misprint or non-uniqueness).
  final String? note;

  /// Creates a puzzle.
  const LabyrinthPuzzle({
    required this.id,
    required this.tutorial,
    required this.grid,
    this.solution,
    this.note,
  });

  /// Number of grid rows (fixed at 8).
  static const int rows = 8;

  /// Number of grid columns (fixed at 8).
  static const int cols = 8;

  /// Number of cells in a valid solution path (fixed at 33: one for each
  /// letter of the Russian alphabet).
  static const int pathLength = 33;

  /// The letter printed at [c].
  String letterAt(Cell c) => grid[c.row][c.col];

  /// Parses a puzzle from its JSON object representation, matching one
  /// entry of the `puzzles` array in `assets/puzzles/module04.json`. The
  /// JSON `grid` is a list of 8 strings of 8 characters each; it is
  /// exploded here into `List<List<String>>`.
  ///
  /// Throws a [FormatException] naming [id] if the grid is not 8x8, if
  /// `grid[0][0]` is not `А`, or if `grid[7][7]` is not `Я` - catching a
  /// flipped row/column transcription convention at parse time instead of
  /// as a mysterious zero-solution result later.
  factory LabyrinthPuzzle.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final rawGrid = json['grid'] as List;
    if (rawGrid.length != rows) {
      throw FormatException(
        'Puzzle "$id": grid has ${rawGrid.length} rows, expected $rows',
      );
    }
    final grid = rawGrid.map((row) {
      final chars = (row as String).split('');
      if (chars.length != cols) {
        throw FormatException(
          'Puzzle "$id": grid row "$row" has ${chars.length} columns, '
          'expected $cols',
        );
      }
      return chars;
    }).toList(growable: false);

    if (grid[0][0] != 'А') {
      throw FormatException(
        'Puzzle "$id": grid[0][0] is "${grid[0][0]}", expected "А"',
      );
    }
    if (grid[rows - 1][cols - 1] != 'Я') {
      throw FormatException(
        'Puzzle "$id": grid[7][7] is "${grid[rows - 1][cols - 1]}", '
        'expected "Я"',
      );
    }

    return LabyrinthPuzzle(
      id: id,
      tutorial: json['tutorial'] as bool? ?? false,
      grid: grid,
      solution: _solutionFromJson(json['solution']),
      note: json['note'] as String?,
    );
  }

  /// Parses the `solution` field: a list of [pathLength] entries, each
  /// `[r, c]`. Absent (`null`) yields `null`.
  static List<Cell>? _solutionFromJson(dynamic json) {
    if (json == null) {
      return null;
    }
    return (json as List).map((pair) {
      final rc = pair as List;
      return Cell(rc[0] as int, rc[1] as int);
    }).toList(growable: false);
  }

  /// Parses a full module data file (matching the shape of
  /// `assets/puzzles/module04.json`) into its list of puzzles.
  static List<LabyrinthPuzzle> listFromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final puzzlesJson = decoded['puzzles'] as List;
    return puzzlesJson
        .map((e) => LabyrinthPuzzle.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

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

/// An unordered pair of two orthogonally-adjacent [Cell]s. Value equality
/// is independent of which cell is `a` and which is `b`.
class Domino {
  final Cell a;
  final Cell b;

  Domino(this.a, this.b)
      : assert(
          (a.row - b.row).abs() + (a.col - b.col).abs() == 1,
          'Domino cells must be orthogonally adjacent: $a, $b',
        );

  @override
  bool operator ==(Object other) =>
      other is Domino &&
      ((other.a == a && other.b == b) || (other.a == b && other.b == a));

  @override
  int get hashCode => a.hashCode ^ b.hashCode;

  @override
  String toString() => 'Domino($a, $b)';
}

/// A complete domino-solitaire puzzle: a fixed 8x7 grid of printed digits
/// 0..6 (56 cells) that the player partitions into 28 dominoes forming
/// exactly one complete double-six set (0:0 .. 6:6, each value-pair used
/// once).
class DominoPuzzle {
  /// Stable identifier within the module's data set (e.g. `p01`).
  final String id;

  /// Whether this is the introductory/tutorial puzzle.
  final bool tutorial;

  /// `grid[row][col]` - the printed digit at each of the 56 cells. Row 0
  /// is the top row, col 0 is the leftmost column.
  final List<List<int>> grid;

  /// The book's printed solution partition, if recorded (currently only
  /// for the tutorial `example`): 28 dominoes covering all 56 cells. The
  /// win condition is constraint satisfaction, not answer match; the
  /// solution is kept for data verification and the tutorial.
  final List<Domino>? solution;

  /// Optional data note (e.g. a recorded book misprint or non-uniqueness).
  final String? note;

  /// Creates a puzzle.
  const DominoPuzzle({
    required this.id,
    required this.tutorial,
    required this.grid,
    this.solution,
    this.note,
  });

  /// Number of grid rows (fixed at 8).
  int get rows => 8;

  /// Number of grid columns (fixed at 7).
  int get cols => 7;

  /// The digit printed at [cell].
  int valueAt(Cell cell) => grid[cell.row][cell.col];

  /// Parses a puzzle from its JSON object representation, matching one
  /// entry of the `puzzles` array in `assets/puzzles/module03.json`.
  factory DominoPuzzle.fromJson(Map<String, dynamic> json) {
    return DominoPuzzle(
      id: json['id'] as String,
      tutorial: json['tutorial'] as bool? ?? false,
      grid: (json['grid'] as List)
          .map((row) =>
              (row as List).map((d) => d as int).toList(growable: false))
          .toList(growable: false),
      solution: _solutionFromJson(json['solution']),
      note: json['note'] as String?,
    );
  }

  /// Parses the `solution` field: a list of 28 entries, each
  /// `[[r1,c1],[r2,c2]]`. Absent (`null`) yields `null`.
  static List<Domino>? _solutionFromJson(dynamic json) {
    if (json == null) {
      return null;
    }
    return (json as List).map((pair) {
      final cells = pair as List;
      final c1 = cells[0] as List;
      final c2 = cells[1] as List;
      return Domino(
        Cell(c1[0] as int, c1[1] as int),
        Cell(c2[0] as int, c2[1] as int),
      );
    }).toList(growable: false);
  }

  /// Parses a full module data file (matching the shape of
  /// `assets/puzzles/module03.json`) into its list of puzzles.
  static List<DominoPuzzle> listFromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final puzzlesJson = decoded['puzzles'] as List;
    return puzzlesJson
        .map((e) => DominoPuzzle.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

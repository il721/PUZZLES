import 'dart:convert';

/// One row of a rebus puzzle: four operand numbers combined left-to-right
/// with three operators to produce [result].
///
/// Numbers are represented as their canonical decimal strings (never with
/// a leading zero). A number's string length is its box width in the
/// puzzle grid — the player always sees the correct number of boxes, even
/// though most of the digits inside them start out hidden.
class RebusRow {
  /// The four operand numbers, as canonical decimal strings, left to right.
  final List<String> nums;

  /// The three operators applied left to right between [nums]: `ops[0]`
  /// combines `nums[0]` and `nums[1]`, `ops[1]` combines that result with
  /// `nums[2]`, and `ops[2]` combines that with `nums[3]`. Each operator is
  /// one of `+`, `-`, `*`, `:` (integer division).
  final List<String> ops;

  /// The row's result, as a canonical decimal string.
  final String result;

  /// Creates a row.
  const RebusRow({
    required this.nums,
    required this.ops,
    required this.result,
  });

  /// Parses a row from its JSON object representation
  /// (`{"nums": [...], "ops": [...], "result": "..."}`).
  factory RebusRow.fromJson(Map<String, dynamic> json) {
    return RebusRow(
      nums: (json['nums'] as List)
          .map((e) => e as String)
          .toList(growable: false),
      ops: (json['ops'] as List)
          .map((e) => e as String)
          .toList(growable: false),
      result: json['result'] as String,
    );
  }
}

/// A single given (pre-filled) digit shown to the player.
///
/// Coordinates follow the puzzle's grid layout: [row] 0..3 identify one of
/// the four arithmetic rows, while [row] 4 identifies the summary row.
/// [slot] 0..3 selects an operand box (arithmetic row) or a column-sum box
/// (summary row); [slot] 4 selects the row's result box (arithmetic row)
/// or the grand-total box (summary row). [pos] indexes the target number's
/// decimal string, 0 being the most significant digit, and [digit] is the
/// required digit (0-9) at that position.
class Given {
  /// 0..3 selects an arithmetic row; 4 selects the summary row.
  final int row;

  /// 0..3 selects an operand (or, on the summary row, a column-sum box);
  /// 4 selects the result (or, on the summary row, the grand total).
  final int slot;

  /// Zero-based index into the target number's decimal string.
  final int pos;

  /// The required digit (0-9) at [pos].
  final int digit;

  /// Creates a given.
  const Given({
    required this.row,
    required this.slot,
    required this.pos,
    required this.digit,
  });

  /// Parses a given from its 4-element JSON array representation
  /// `[row, slot, pos, digit]`.
  factory Given.fromJson(List<dynamic> json) {
    return Given(
      row: json[0] as int,
      slot: json[1] as int,
      pos: json[2] as int,
      digit: json[3] as int,
    );
  }
}

/// A complete rebus puzzle: four arithmetic rows plus a summary row.
///
/// Each arithmetic row evaluates, strictly left to right, to its own
/// result. Column `j` (the `j`-th operand across all four rows) sums to
/// `rows[j].result` — this is the structural link between the arithmetic
/// rows and the summary row: the summary row's four column-sum boxes
/// display `rows[0].result` through `rows[3].result`, and [total] is the
/// sum of those four results.
class RebusPuzzle {
  /// Stable identifier within the module's data set (e.g. `p01`).
  final String id;

  /// Whether this is the introductory/tutorial puzzle. Tutorial puzzles
  /// are not required to have a unique player-facing solution.
  final bool tutorial;

  /// The four arithmetic rows, in display order.
  final List<RebusRow> rows;

  /// The grand total — the sum of the four rows' results — as a canonical
  /// decimal string.
  final String total;

  /// The digits pre-filled for the player.
  final List<Given> givens;

  /// Creates a puzzle.
  const RebusPuzzle({
    required this.id,
    required this.tutorial,
    required this.rows,
    required this.total,
    required this.givens,
  });

  /// Parses a puzzle from its JSON object representation, matching one
  /// entry of the `puzzles` array in `assets/puzzles/module01.json`.
  factory RebusPuzzle.fromJson(Map<String, dynamic> json) {
    return RebusPuzzle(
      id: json['id'] as String,
      tutorial: json['tutorial'] as bool? ?? false,
      rows: (json['rows'] as List)
          .map((e) => RebusRow.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      total: json['total'] as String,
      givens: (json['givens'] as List)
          .map((e) => Given.fromJson(e as List<dynamic>))
          .toList(growable: false),
    );
  }

  /// Parses a full module data file (matching the shape of
  /// `assets/puzzles/module01.json`) into its list of puzzles.
  static List<RebusPuzzle> listFromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final puzzlesJson = decoded['puzzles'] as List;
    return puzzlesJson
        .map((e) => RebusPuzzle.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

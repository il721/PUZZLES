import 'dart:convert';

import 'playground_game.dart';

/// A single game's parsed entry from `assets/puzzles/module06.json`: its
/// move-economy metadata and (when recorded) one optimal solution.
/// Unknown/missing fields are tolerated as `null` rather than rejected -
/// only a malformed [id] parsing path (missing entirely, wrong JSON shape)
/// is treated as a hard parse error; a game with no par question at all
/// simply has `par == null`.
class PlaygroundGameData {
  /// The game id this entry describes, matching `PlaygroundGame.id`.
  final String id;

  /// The recorded par (minimum move count), or `null` if this game has no
  /// move-economy question.
  final int? par;

  /// Whether [par] is a proven optimum. `false` when absent from the JSON.
  final bool parProven;

  /// Where [par] came from. `null` when [par] is `null`.
  final ParSource? parSource;

  /// One recorded optimal solution, if present in the JSON.
  final List<PlaygroundMove>? solution;

  /// Creates a game data entry.
  const PlaygroundGameData({
    required this.id,
    this.par,
    this.parProven = false,
    this.parSource,
    this.solution,
  });

  /// Parses one entry of the `games` array in `module06.json`.
  factory PlaygroundGameData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;

    final parSourceRaw = json['parSource'] as String?;
    ParSource? parSource;
    if (parSourceRaw != null) {
      for (final candidate in ParSource.values) {
        if (candidate.name == parSourceRaw) {
          parSource = candidate;
          break;
        }
      }
      if (parSource == null) {
        throw FormatException(
          'PlaygroundGameData "$id": unknown parSource "$parSourceRaw"',
        );
      }
    }

    final rawSolution = json['solution'] as List?;
    final solution = rawSolution
        ?.map((move) => PlaygroundMove.fromJson(move))
        .toList(growable: false);

    return PlaygroundGameData(
      id: id,
      par: json['par'] as int?,
      parProven: json['parProven'] as bool? ?? false,
      parSource: parSource,
      solution: solution,
    );
  }
}

/// The parsed contents of `assets/puzzles/module06.json`: the schema
/// version, module name, and every game's [PlaygroundGameData] entry.
class PlaygroundData {
  /// The JSON schema version this file was written against.
  final int schemaVersion;

  /// The module name this data belongs to (`"playground"`).
  final String module;

  /// Every game entry present in the file.
  final List<PlaygroundGameData> games;

  /// Creates a data set.
  const PlaygroundData({
    required this.schemaVersion,
    required this.module,
    required this.games,
  });

  /// Parses a full `module06.json` document.
  ///
  /// Throws a [FormatException] if [jsonString] is not well-formed JSON, or
  /// is missing the top-level `schemaVersion`/`module`/`games` fields.
  factory PlaygroundData.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final rawGames = decoded['games'] as List;
    return PlaygroundData(
      schemaVersion: decoded['schemaVersion'] as int,
      module: decoded['module'] as String,
      games: rawGames
          .map((g) => PlaygroundGameData.fromJson(g as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// The data entry for game [id], or `null` if this data set has no entry
  /// for it (tolerated - not every game needs recorded par/solution data).
  PlaygroundGameData? forId(String id) {
    for (final game in games) {
      if (game.id == id) return game;
    }
    return null;
  }
}

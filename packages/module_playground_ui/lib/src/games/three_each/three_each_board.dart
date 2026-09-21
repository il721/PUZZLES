import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_playground/module_playground.dart';

import '../../playground_l10n.dart';
import '../../playground_session_controller.dart';

/// Cardboard-tile colours for «Всюду по три». The circles are fixed
/// regardless of the app's theme: colour identity IS the puzzle, so a dark
/// theme must never invert them. Only the cardboard tint follows the theme -
/// [_teParchment] in light, [_teParchmentDark] in dark - while selection
/// highlights and legal-target hints borrow the theme's
/// [ColorScheme.primary].
const Color _teParchment = Color(0xFFFAF8F2);
const Color _teParchmentDark = Color(0xFFCFD3D6);
const Color _teGridLine = Color(0xFFBDBDBD);
const Color _teBorder = Color(0xFF1A1A1A);
const Color _teRed = Color(0xFFD32F2F);
const Color _teBlack = Color(0xFF1A1A1A);
const Color _teWhite = Color(0xFFFFFFFF);

final List<List<String>> _teEmptyCells =
    List.generate(3, (_) => List.filled(3, threeEachEmpty));

/// Paints one 3x3 tile (a board slot or a tray tile): [background] cardboard,
/// thin grey lines between its own cells, a dark border around the whole
/// tile, and a circle per non-empty cell. [highlight], when non-null, draws
/// an extra inset border in that colour - used for the selected tile and for
/// legal-target hints.
class _ThreeEachTilePainter extends CustomPainter {
  final List<List<String>> cells;
  final Color background;
  final Color? highlight;

  const _ThreeEachTilePainter({
    required this.cells,
    required this.background,
    this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = background);

    final cellSize = size.width / 3;
    final gridPaint = Paint()
      ..color = _teGridLine
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
          Offset(i * cellSize, 0), Offset(i * cellSize, size.height), gridPaint);
      canvas.drawLine(
          Offset(0, i * cellSize), Offset(size.width, i * cellSize), gridPaint);
    }

    canvas.drawRect(
      rect.deflate(1.5),
      Paint()
        ..color = _teBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final cell = cells[r][c];
        if (cell == threeEachEmpty) continue;
        final center = Offset((c + 0.5) * cellSize, (r + 0.5) * cellSize);
        final radius = cellSize * 0.32;
        if (cell == threeEachRed) {
          canvas.drawCircle(center, radius, Paint()..color = _teRed);
        } else if (cell == threeEachBlack) {
          canvas.drawCircle(center, radius, Paint()..color = _teBlack);
        } else if (cell == threeEachWhite) {
          canvas.drawCircle(center, radius, Paint()..color = _teWhite);
          canvas.drawCircle(
            center,
            radius,
            Paint()
              ..color = _teBlack
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }

    final hl = highlight;
    if (hl != null) {
      canvas.drawRect(
        rect.deflate(2),
        Paint()
          ..color = hl
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThreeEachTilePainter oldDelegate) => true;
}

/// The board for «Всюду по три»: nine 3x3 cardboard tiles assembled into a
/// 9x9 square. Renders the live [playgroundSessionProvider] state for
/// [gameId] unless [previewState] is supplied, in which case that state is
/// shown instead and taps are ignored - used by `PlaygroundGameScreen` to
/// animate [PlaygroundGame.optimalSolution] without touching the real play
/// session.
///
/// Input is tap-select-then-tap-target; there is no drag anywhere in this
/// module. Tapping a tray tile selects it (pending rotation starts at 0);
/// tapping the already-selected tray tile advances the pending rotation by
/// one quarter turn, shown live in the tray. With a tray tile selected,
/// tapping an empty board slot lays it there at the pending rotation.
/// Tapping an occupied slot selects that placed tile instead (clearing any
/// tray selection); tapping it again deselects it. The rotate button turns
/// the pending preview when a tray tile is selected, or applies a real
/// rotate-in-place move when a placed tile is selected. The return button
/// sends a selected placed tile back to the tray.
class ThreeEachBoard extends ConsumerStatefulWidget {
  /// The id of the game session to display and drive (`three_each`).
  final String gameId;

  /// When non-null, displayed instead of the live session board and not
  /// interactive. Used for the "show solution" playback.
  final PlaygroundState? previewState;

  /// Creates the three-each board for [gameId].
  const ThreeEachBoard({super.key, required this.gameId, this.previewState});

  @override
  ConsumerState<ThreeEachBoard> createState() => _ThreeEachBoardState();
}

class _ThreeEachBoardState extends ConsumerState<ThreeEachBoard> {
  static const ThreeEachGame _game = ThreeEachGame();

  int? _selectedTrayTile;
  int _pendingRotation = 0;
  int? _selectedSlot;

  bool get _interactive => widget.previewState == null;

  List<List<String>> _cellsOf(ThreeEachPlacement placement) => [
        for (var r = 0; r < 3; r++)
          [for (var c = 0; c < 3; c++) placement.cellAt(r, c)],
      ];

  List<List<String>> _trayCells(int tile, int? selectedTrayTile) {
    final rotation = tile == selectedTrayTile ? _pendingRotation : 0;
    return [
      for (var r = 0; r < 3; r++)
        [for (var c = 0; c < 3; c++) threeEachCell(tile, rotation, r, c)],
    ];
  }

  void _onTrayTap(int tile) {
    if (!_interactive) return;
    setState(() {
      if (_selectedTrayTile == tile) {
        _pendingRotation = (_pendingRotation + 1) % 4;
      } else {
        _selectedTrayTile = tile;
        _pendingRotation = 0;
        _selectedSlot = null;
      }
    });
  }

  void _onSlotTap(int slot, ThreeEachState state) {
    if (!_interactive) return;
    final placement = state.slots[slot];

    if (placement == null) {
      final tile = _selectedTrayTile;
      if (tile == null) return;
      final target = '${threeEachSlotIds[slot]}r$_pendingRotation';
      final legal = _game.legalMoves(state, from: threeEachTileIds[tile]);
      final match = legal.where((m) => m.to == target);
      if (match.isEmpty) return;
      ref
          .read(playgroundSessionProvider(widget.gameId).notifier)
          .apply(match.first);
      setState(() {
        _selectedTrayTile = null;
        _pendingRotation = 0;
      });
      return;
    }

    setState(() {
      if (_selectedSlot == slot) {
        _selectedSlot = null;
      } else {
        _selectedSlot = slot;
        _selectedTrayTile = null;
      }
    });
  }

  VoidCallback? _rotatePressed(ThreeEachState state) {
    if (!_interactive) return null;
    if (_selectedTrayTile != null) {
      return () => setState(() => _pendingRotation = (_pendingRotation + 1) % 4);
    }
    final slot = _selectedSlot;
    if (slot == null) return null;
    final placement = state.slots[slot];
    if (placement == null) return null;
    final slotId = threeEachSlotIds[slot];
    final target = '${slotId}r${(placement.rotation + 1) % 4}';
    final legal = _game.legalMoves(state, from: slotId);
    for (final move in legal) {
      if (move.to == target) {
        return () => ref
            .read(playgroundSessionProvider(widget.gameId).notifier)
            .apply(move);
      }
    }
    return null;
  }

  VoidCallback? _returnPressed(ThreeEachState state) {
    if (!_interactive) return null;
    final slot = _selectedSlot;
    if (slot == null) return null;
    final placement = state.slots[slot];
    if (placement == null) return null;
    final slotId = threeEachSlotIds[slot];
    final target = threeEachTileIds[placement.tile];
    final legal = _game.legalMoves(state, from: slotId);
    for (final move in legal) {
      if (move.to == target) {
        return () {
          ref
              .read(playgroundSessionProvider(widget.gameId).notifier)
              .apply(move);
          setState(() => _selectedSlot = null);
        };
      }
    }
    return null;
  }

  Widget _slot(int index, ThreeEachState state, ColorScheme scheme,
      Color background, int? selectedSlot, int? selectedTrayTile) {
    final placement = state.slots[index];
    final cells = placement == null ? _teEmptyCells : _cellsOf(placement);

    Color? highlight;
    if (selectedSlot == index) {
      highlight = scheme.primary;
    } else if (placement == null && selectedTrayTile != null && _interactive) {
      highlight = scheme.primary.withAlpha(140);
    }

    return GestureDetector(
      key: ValueKey('pg-te-slot-$index'),
      onTap: () => _onSlotTap(index, state),
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _ThreeEachTilePainter(
              cells: cells, background: background, highlight: highlight),
        ),
      ),
    );
  }

  Widget _trayTile(
      int tile, ColorScheme scheme, Color background, int? selectedTrayTile) {
    return GestureDetector(
      key: ValueKey('pg-te-tray-$tile'),
      onTap: () => _onTrayTap(tile),
      child: SizedBox(
        width: 56,
        height: 56,
        child: CustomPaint(
          painter: _ThreeEachTilePainter(
            cells: _trayCells(tile, selectedTrayTile),
            background: background,
            highlight: tile == selectedTrayTile ? scheme.primary : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(playgroundSessionProvider(widget.gameId));
    final displayState =
        (widget.previewState ?? sessionState.board) as ThreeEachState;
    final l10n = ref.watch(playgroundL10nProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background =
        theme.brightness == Brightness.dark ? _teParchmentDark : _teParchment;

    // During "show solution" playback the selection left over from live play
    // has nothing to do with what the preview shows - a stale highlight would
    // point at a slot the preview no longer relates to. Blank both selections
    // for rendering only; the fields stay untouched so play resumes as it was.
    final selectedSlot = _interactive ? _selectedSlot : null;
    final selectedTrayTile = _interactive ? _selectedTrayTile : null;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size =
                  math.min(constraints.maxWidth, constraints.maxHeight);
              return Center(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Column(
                    children: [
                      for (var row = 0; row < 3; row++)
                        Expanded(
                          child: Row(
                            children: [
                              for (var col = 0; col < 3; col++)
                                Expanded(
                                  child: _slot(
                                      row * 3 + col,
                                      displayState,
                                      scheme,
                                      background,
                                      selectedSlot,
                                      selectedTrayTile),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final tile in displayState.trayTiles)
                _trayTile(tile, scheme, background, selectedTrayTile),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const ValueKey('pg-te-rotate'),
              icon: const Icon(Icons.rotate_right),
              tooltip: l10n.rotateTile,
              onPressed: _rotatePressed(displayState),
            ),
            IconButton(
              key: const ValueKey('pg-te-return'),
              icon: const Icon(Icons.arrow_downward),
              tooltip: l10n.returnTileToTray,
              onPressed: _returnPressed(displayState),
            ),
          ],
        ),
      ],
    );
  }
}

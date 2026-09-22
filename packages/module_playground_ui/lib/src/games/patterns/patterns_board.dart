import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_playground/module_playground.dart';

import '../../playground_l10n.dart';
import '../../playground_session_controller.dart';

/// Cardboard-tile colours for «Узоры», matching «Всюду по три»: the tint
/// follows the theme ([_pCardboard] in light, [_pCardboardDark] in dark)
/// while the drawn line stays red in both, because the red line IS the
/// puzzle and a dark theme must not recolour it. Selection highlights and
/// legal-target hints borrow the theme's [ColorScheme.primary].
const Color _pCardboard = Color(0xFFFAF8F2);
const Color _pCardboardDark = Color(0xFFCFD3D6);
const Color _pBorder = Color(0xFF1A1A1A);
const Color _pRed = Color(0xFFD32F2F);

/// Paints one tile - a board slot or a tray tile - as cardboard with a dark
/// border and the red line its four cells carry. [masks] is the tile's cells
/// as direction-bit masks in the order top-left, top-right, bottom-left,
/// bottom-right, or null for an empty slot. [highlight], when non-null,
/// draws an extra inset border in that colour, used for the selected tile
/// and for legal-target hints.
class _PatternsTilePainter extends CustomPainter {
  final List<int>? masks;
  final Color background;
  final Color? highlight;

  const _PatternsTilePainter({
    required this.masks,
    required this.background,
    this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = background);

    canvas.drawRect(
      rect.deflate(1.5),
      Paint()
        ..color = _pBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final cells = masks;
    if (cells != null) {
      final half = size.width / 2;
      final line = Paint()
        ..color = _pRed
        ..strokeWidth = math.max(2, size.width * 0.045)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (var k = 0; k < 4; k++) {
        final centre = Offset(
          (k % 2 + 0.5) * half,
          (k ~/ 2 + 0.5) * half,
        );
        final mask = cells[k];
        if (mask & patternsNorth != 0) {
          canvas.drawLine(centre, centre.translate(0, -half / 2), line);
        }
        if (mask & patternsSouth != 0) {
          canvas.drawLine(centre, centre.translate(0, half / 2), line);
        }
        if (mask & patternsWest != 0) {
          canvas.drawLine(centre, centre.translate(-half / 2, 0), line);
        }
        if (mask & patternsEast != 0) {
          canvas.drawLine(centre, centre.translate(half / 2, 0), line);
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
  bool shouldRepaint(covariant _PatternsTilePainter oldDelegate) => true;
}

/// The board for «Узоры»: [PatternsGame.size] squared cardboard tiles laid
/// into a square whose red segments must close into one loop. Renders the
/// live [playgroundSessionProvider] state for [gameId] unless [previewState]
/// is supplied, in which case that state is shown instead and taps are
/// ignored - used by `PlaygroundGameScreen` to animate
/// [PlaygroundGame.optimalSolution] without touching the real play session.
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
class PatternsBoard extends ConsumerStatefulWidget {
  /// The id of the game session to display and drive (`patterns5`).
  final String gameId;

  /// The game whose tiles and board size this widget renders.
  final PatternsGame game;

  /// When non-null, displayed instead of the live session board and not
  /// interactive. Used for the "show solution" playback.
  final PlaygroundState? previewState;

  /// Creates the patterns board for [gameId].
  const PatternsBoard({
    super.key,
    required this.gameId,
    required this.game,
    this.previewState,
  });

  @override
  ConsumerState<PatternsBoard> createState() => _PatternsBoardState();
}

class _PatternsBoardState extends ConsumerState<PatternsBoard> {
  int? _selectedTrayTile;
  int _pendingRotation = 0;
  int? _selectedSlot;

  PatternsGame get _game => widget.game;

  bool get _interactive => widget.previewState == null;

  void _apply(PlaygroundMove move) =>
      ref.read(playgroundSessionProvider(widget.gameId).notifier).apply(move);

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

  void _onSlotTap(int slot, PatternsState state) {
    if (!_interactive) return;
    final placement = state.slots[slot];

    if (placement == null) {
      final tile = _selectedTrayTile;
      if (tile == null) return;
      final target = '${_game.slotId(slot)}r$_pendingRotation';
      final legal = _game.legalMoves(state, from: _game.tileId(tile));
      final match = legal.where((m) => m.to == target);
      if (match.isEmpty) return;
      _apply(match.first);
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

  VoidCallback? _rotatePressed(PatternsState state) {
    if (!_interactive) return null;
    if (_selectedTrayTile != null) {
      return () =>
          setState(() => _pendingRotation = (_pendingRotation + 1) % 4);
    }
    final slot = _selectedSlot;
    if (slot == null) return null;
    final placement = state.slots[slot];
    if (placement == null) return null;
    final slotId = _game.slotId(slot);
    final target = '${slotId}r${(placement.rotation + 1) % 4}';
    for (final move in _game.legalMoves(state, from: slotId)) {
      if (move.to == target) return () => _apply(move);
    }
    return null;
  }

  VoidCallback? _returnPressed(PatternsState state) {
    if (!_interactive) return null;
    final slot = _selectedSlot;
    if (slot == null) return null;
    final placement = state.slots[slot];
    if (placement == null) return null;
    final slotId = _game.slotId(slot);
    final target = _game.tileId(placement.tile);
    for (final move in _game.legalMoves(state, from: slotId)) {
      if (move.to == target) {
        return () {
          _apply(move);
          setState(() => _selectedSlot = null);
        };
      }
    }
    return null;
  }

  Widget _slot(int index, PatternsState state, ColorScheme scheme,
      Color background, int? selectedSlot, int? selectedTrayTile) {
    final placement = state.slots[index];

    Color? highlight;
    if (selectedSlot == index) {
      highlight = scheme.primary;
    } else if (placement == null && selectedTrayTile != null && _interactive) {
      highlight = scheme.primary.withAlpha(140);
    }

    return GestureDetector(
      key: ValueKey('pg-p5-slot-$index'),
      onTap: () => _onSlotTap(index, state),
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _PatternsTilePainter(
            masks: placement == null
                ? null
                : patternsTileMasks(
                    _game.tiles[placement.tile],
                    placement.rotation,
                  ),
            background: background,
            highlight: highlight,
          ),
        ),
      ),
    );
  }

  Widget _trayTile(
      int tile, ColorScheme scheme, Color background, int? selectedTrayTile) {
    final rotation = tile == selectedTrayTile ? _pendingRotation : 0;
    return GestureDetector(
      key: ValueKey('pg-p5-tray-$tile'),
      onTap: () => _onTrayTap(tile),
      child: SizedBox(
        width: 48,
        height: 48,
        child: CustomPaint(
          painter: _PatternsTilePainter(
            masks: patternsTileMasks(_game.tiles[tile], rotation),
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
        (widget.previewState ?? sessionState.board) as PatternsState;
    final l10n = ref.watch(playgroundL10nProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background =
        theme.brightness == Brightness.dark ? _pCardboardDark : _pCardboard;

    // During "show solution" playback the selection left over from live play
    // has nothing to do with what the preview shows, so blank both
    // selections for rendering only; the fields stay untouched and play
    // resumes exactly as it was.
    final selectedSlot = _interactive ? _selectedSlot : null;
    final selectedTrayTile = _interactive ? _selectedTrayTile : null;

    final tray = [
      for (var tile = 0; tile < _game.tiles.length; tile++)
        if (displayState.slotOfTile(tile) == null) tile,
    ];

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
                      for (var row = 0; row < _game.size; row++)
                        Expanded(
                          child: Row(
                            children: [
                              for (var col = 0; col < _game.size; col++)
                                Expanded(
                                  child: _slot(
                                    row * _game.size + col,
                                    displayState,
                                    scheme,
                                    background,
                                    selectedSlot,
                                    selectedTrayTile,
                                  ),
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
        // The tray holds up to twenty-five tiles, far more than «Всюду по
        // три»'s nine, so it gets its own bounded, scrollable strip instead
        // of growing until it crowds the board off a phone screen.
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 124),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final tile in tray)
                  _trayTile(tile, scheme, background, selectedTrayTile),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const ValueKey('pg-p5-rotate'),
              icon: const Icon(Icons.rotate_right),
              tooltip: l10n.rotateTile,
              onPressed: _rotatePressed(displayState),
            ),
            IconButton(
              key: const ValueKey('pg-p5-return'),
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

import 'package:flutter/material.dart';
import 'package:module_playground/module_playground.dart';

/// Shared node/line rendering primitives for the token-graph board family
/// (`eight_chips`, `cats_dogs`, later `hourglass`): each board lays out its
/// own [TokenGraphBoard] node positions and drives these two widgets to draw
/// the alleys and the tokens sitting on them.

/// Draws every alley of a [TokenGraphBoard] as straight line segments
/// between consecutive nodes, using each board's own [positionFor] to place
/// them.
class TokenGraphLinesPainter extends CustomPainter {
  final TokenGraphBoard board;
  final Offset Function(String nodeId) positionFor;
  final Color color;

  /// Creates a painter drawing [board]'s lines in [color], with node
  /// positions supplied by [positionFor].
  TokenGraphLinesPainter({required this.board, required this.positionFor, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (final line in board.lines) {
      for (var i = 0; i < line.length - 1; i++) {
        canvas.drawLine(positionFor(line[i]), positionFor(line[i + 1]), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TokenGraphLinesPainter oldDelegate) => oldDelegate.color != color;
}

/// A single tappable board node: a circle positioned at [center], holding
/// [token]'s label (if any) and coloured for its [selected]/[isDestination]/
/// occupied state.
class TokenGraphNodeWidget extends StatelessWidget {
  final String nodeId;
  final Offset center;
  final double nodeSize;
  final String? token;

  /// Rotation angle (radians) applied to the token label. `0` for boards
  /// with no per-node rotation.
  final double rotation;
  final bool selected;
  final bool isDestination;
  final ColorScheme scheme;
  final VoidCallback onTap;

  /// When set (and the node is neither [selected] nor [isDestination]) and
  /// [token] is non-null, overrides the default occupied-node background.
  /// `null` keeps the current `surfaceContainerHighest` behaviour.
  final Color? tokenBackground;

  /// Paired with [tokenBackground]: overrides the occupied-node label/
  /// foreground colour under the same condition. `null` keeps the current
  /// `onSurfaceVariant` behaviour.
  final Color? tokenForeground;

  /// Creates a node widget for [nodeId], centred at [center].
  const TokenGraphNodeWidget({
    required Key key,
    required this.nodeId,
    required this.center,
    required this.nodeSize,
    required this.token,
    required this.rotation,
    required this.selected,
    required this.isDestination,
    required this.scheme,
    required this.onTap,
    this.tokenBackground,
    this.tokenForeground,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;
    if (selected) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
    } else if (isDestination) {
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
    } else if (token != null) {
      background = tokenBackground ?? scheme.surfaceContainerHighest;
      foreground = tokenForeground ?? scheme.onSurfaceVariant;
    } else {
      background = scheme.surface;
      foreground = scheme.onSurface;
    }

    return Positioned(
      left: center.dx - nodeSize / 2,
      top: center.dy - nodeSize / 2,
      width: nodeSize,
      height: nodeSize,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            border: Border.all(color: scheme.outline),
          ),
          alignment: Alignment.center,
          child: token == null
              ? null
              : Transform.rotate(
                  angle: rotation,
                  child: Text(
                    token!,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                      fontSize: nodeSize * 0.55,
                      height: 1.0,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

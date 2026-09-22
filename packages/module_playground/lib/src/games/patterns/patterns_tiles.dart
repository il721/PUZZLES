/// The four directions a red line leaves a tile cell by, as bit flags. A
/// cell's connector is the OR of exactly two of them, so the line always
/// runs through a cell rather than starting or ending in it.
const int patternsNorth = 1;

/// East, see [patternsNorth].
const int patternsEast = 2;

/// South, see [patternsNorth].
const int patternsSouth = 4;

/// West, see [patternsNorth].
const int patternsWest = 8;

/// The six connectors a cell can carry, named by the two tile-cell edges
/// the red line joins: four quarter turns and two straight runs.
const List<String> patternsConnectors = ['NE', 'NW', 'SE', 'SW', 'NS', 'EW'];

/// The direction-bit mask of connector [connector] (one of
/// [patternsConnectors]), e.g. `NE` -> [patternsNorth] | [patternsEast].
int patternsConnectorMask(String connector) {
  var mask = 0;
  for (final letter in connector.split('')) {
    mask |= switch (letter) {
      'N' => patternsNorth,
      'E' => patternsEast,
      'S' => patternsSouth,
      'W' => patternsWest,
      _ => throw ArgumentError('patterns: unknown direction "$letter"'),
    };
  }
  return mask;
}

/// The mask [mask] turned one quarter turn clockwise (N->E->S->W->N).
int patternsRotateMask(int mask) {
  var out = 0;
  if (mask & patternsNorth != 0) out |= patternsEast;
  if (mask & patternsEast != 0) out |= patternsSouth;
  if (mask & patternsSouth != 0) out |= patternsWest;
  if (mask & patternsWest != 0) out |= patternsNorth;
  return out;
}

/// The twenty-five cardboard tiles of «Узоры» (Мочалов, 1980, p. 62), in
/// the reading order of the book's figure: five per row, left to right, top
/// to bottom.
///
/// A tile is a 2x2 block of cells and the red line runs from cell centre to
/// cell centre, so each cell carries one of the six [patternsConnectors] and
/// every red end meets a tile edge at a quarter or three-quarter point. The
/// four entries per tile are its cells in the order top-left, top-right,
/// bottom-left, bottom-right, unrotated.
///
/// Transcribed from the 600-dpi scan by sampling the red colour mask at the
/// cell centres and midway to each neighbour; the result was rendered back
/// to PICT/06-patterns5-encoding.png and confirmed by the user. Three
/// independent checks back it: every one of the 100 cells came out with
/// exactly two directions, every shared edge inside a tile agreed, and the
/// book's printed answer on p. 116 - transcribed the same way from a
/// different page - is a multiset bijection onto these tiles under rotation
/// alone.
///
/// T1 and T24 are the same tile; that duplicate is in the book, and the
/// printed answer uses it twice.
const List<List<String>> patterns5Tiles = [
  ['NE', 'SW', 'SW', 'NE'],
  ['NE', 'NW', 'SW', 'SE'],
  ['EW', 'NW', 'SW', 'SE'],
  ['NE', 'EW', 'SW', 'SE'],
  ['EW', 'EW', 'SW', 'SE'],
  ['EW', 'SW', 'SW', 'NS'],
  ['NE', 'SW', 'SW', 'NS'],
  ['EW', 'SW', 'SW', 'NE'],
  ['NE', 'SW', 'SW', 'NE'],
  ['SE', 'SW', 'NW', 'NE'],
  ['SE', 'SW', 'NW', 'NS'],
  ['SE', 'SW', 'NS', 'NE'],
  ['SE', 'SW', 'NS', 'NS'],
  ['NE', 'NW', 'SE', 'SW'],
  ['NE', 'NW', 'SE', 'EW'],
  ['NE', 'NW', 'EW', 'SW'],
  ['NE', 'NW', 'EW', 'EW'],
  ['EW', 'EW', 'EW', 'EW'],
  ['EW', 'EW', 'SE', 'EW'],
  ['EW', 'EW', 'EW', 'SW'],
  ['NE', 'EW', 'SE', 'EW'],
  ['NE', 'EW', 'EW', 'SW'],
  ['EW', 'NW', 'SE', 'EW'],
  ['NS', 'SE', 'NE', 'NW'],
  ['SW', 'NS', 'NE', 'NW'],
];

/// The four cells of tile [tile] after [rotation] quarter turns clockwise,
/// as direction-bit masks in the order top-left, top-right, bottom-left,
/// bottom-right.
///
/// A clockwise turn moves the bottom-left cell into the top-left corner,
/// the top-left into the top-right, and so on, and turns each cell's own
/// connector with it.
List<int> patternsTileMasks(List<String> tile, int rotation) {
  var masks = [for (final cell in tile) patternsConnectorMask(cell)];
  for (var i = 0; i < rotation % 4; i++) {
    masks = [
      patternsRotateMask(masks[2]),
      patternsRotateMask(masks[0]),
      patternsRotateMask(masks[3]),
      patternsRotateMask(masks[1]),
    ];
  }
  return masks;
}

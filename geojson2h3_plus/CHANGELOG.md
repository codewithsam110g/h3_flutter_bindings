# Changelog

## [1.0.0+v4.2.1] - 26/05/2025 (d-m-y)

### Overview

This release (`1.0.0+v4.2.1`) marks the first stable version of the new H3 bindings ecosystem for Dart and Flutter, targeting Uber's H3 C library v4.2.1. It replaces the old, unmaintained bindings (`h3_flutter`, `h3_dart`, and others by festelo), which were based on H3 v3.7.2. Legacy changelogs are preserved in `CHANGELOG.legacy.md`.

### New H3 Bindings Ecosystem

This release introduces a complete ecosystem of H3 bindings consisting of 6 packages:
- **geojson2h3_plus** - GeoJSON to H3 conversion utilities
- **h3_common_plus** - Common H3 interface and types
- **h3_ffi_plus** - FFI implementation using Dart FFI with C for VM Dart
- **h3_web_plus** - Web implementation using dart-js-ffigen for browser environments  
- **h3_dart_plus** - Pure Dart package for VM environments
- **h3_flutter_plus** - Flutter ecosystem package

All packages replace their unmaintained counterparts (non-`_plus` versions by festelo) which were stuck at H3 v3.7.2 and are no longer maintained on pub.dev.

### Architecture

The abstract class `h3_common_plus` is implemented by:
- **FFI implementation**: Uses Dart FFI with C for VM Dart environments
- **Web implementation**: Uses dart-js-ffigen for web environments

Both implementations are updated to H3 v4.2.1. The `h3_dart_plus` (pure Dart) and `h3_flutter_plus` (Flutter ecosystem) packages use these implementations internally to provide the public API across multiple platforms.

### New APIs Introduced

#### Core Functional Extensions
- **`describeH3Error`** - Provides human-readable error messages from H3Error codes [0-15]
- **`polygonToCellsExperimental`** - New algorithmic variant of polygonToCells with support for center-based, fully-contained, and overlapping containment modes via flags parameter
- **`cellToChildPos`** - Provides the position of a child cell within an ordered list of all children of the cell's parent at the specified resolution
- **`childPosToCell`** - Reconstructs the child H3 index from a parent and a positional offset using resolution and child position index

#### Vertex Mode APIs (New in H3 v4)
- **`cellToVertex`** - Returns the index for a specified cell vertex (vertex numbers 0-5 for hexagons, 0-4 for pentagons)
- **`cellToVertexes`** - Returns the indexes for all vertexes of a given cell
- **`vertexToLatLng`** - Returns the latitude and longitude coordinates of a given vertex
- **`isValidVertex`** - Determines if a given H3 index represents a valid H3 vertex

### Updated APIs (H3 v3 → v4 Migration)

Function names have been updated to reflect the new naming conventions in H3 v4. The major change is removing output parameters from return values and adding them as pointer parameters, with functions now returning status codes (success/failure/specific errors).

#### Validation Functions
| v3 Name | v4 Name | Notes |
|---------|---------|-------|
| `h3IsValid` | `isValidCell` | Determines if H3Index is a valid cell (hexagon or pentagon) |
| `h3UnidirectionalEdgeIsValid` | `isValidDirectedEdge` | Validates directed edge indexes |
| `h3IsPentagon` | `isPentagon` | Determines if H3Index is a valid pentagon |
| `h3IsResClassIII` | `isResClassIII` | Checks if Resolution is Class III (rotated ~19.1°) |

#### Hierarchy Functions
| v3 Name | v4 Name | Notes |
|---------|---------|-------|
| `h3ToParent` | `cellToParent` | Get parent cell at specified resolution |
| `h3ToChildren` | `cellToChildren` | Get children/descendants at specified resolution |
| `h3ToCenterChild` | `cellToCenterChild` | Get center child at specified resolution |

#### Geometry Functions
| v3 Name | v4 Name | Notes |
|---------|---------|-------|
| `geoToH3` | `latLngToCell` | Find cell based on lat/lng coordinates at specified resolution |
| `h3ToGeo` | `cellToLatLng` | Get coordinates based on center of given cell |
| `h3ToGeoBoundary` | `cellToBoundary` | Get cell boundary in lat/lng coordinates |

#### Polygon Functions
| v3 Name | v4 Name | Notes |
|---------|---------|-------|
| `polyfill` | `polygonToCells` | Convert polygon coordinates to H3 cells |
| `h3SetToLinkedGeo` | `cellsToLinkedMultiPolygon` | Returns LinkedGeoPolygon |
| `h3SetToMultiPolygon` | `cellsToMultiPolygon` | Bindings only implementation |

#### Set Operations
| v3 Name | v4 Name | Notes |
|---------|---------|-------|
| `compact` | `compactCells` | Compact cells of same resolution across multiple levels |
| `uncompact` | `uncompactCells` | Uncompact compacted set to same resolution |

#### Neighbor and Distance Functions
| v3 Name | v4 Name | Notes |
|---------|---------|-------|
| `h3IndexesAreNeighbors` | `areNeighborCells` | Determines if provided H3 cells are neighbors |
| `h3Distance` | `gridDistance` | Grid distance between two cells (minimum hops) |
| `h3Line` | `gridPathCells` | Line of indexes between two cells (inclusive) |

#### Ring and Disk Functions
| v3 Name | v4 Name | Notes |
|---------|---------|-------|
| `hexRing` | `gridRingUnsafe` | Hollow ring of cells at grid distance k |
| `kRing` | `gridDisk` | Filled-in disk of cells at most grid distance k |
| `kRingDistances` | `gridDiskDistances` | Calls gridDiskDistancesUnsafe and gridDiskDistancesSafe |
| `hexRange` | `gridDiskUnsafe` | Calls hexRangeDistances (now gridDiskDistancesUnsafe) |
| `hexRanges` | `gridDisksUnsafe` | N × gridDiskUnsafe |

#### Local IJ Coordinate Functions
| v3 Name | v4 Name | Notes |
|---------|---------|-------|
| `experimentalLocalIjToH3` | `localIjToCell` | Produces H3 cell for IJ coordinates anchored by origin |
| `experimentalH3ToLocalIj` | `cellToLocalIj` | Produces IJ coordinates for H3 cell anchored by origin |

#### Directed Edge Functions (Concept: UnidirectionalEdge → DirectedEdge)
| v3 Name | v4 Name | Notes |
|---------|---------|-------|
| `getH3UnidirectionalEdge` | `cellsToDirectedEdge` | Provides directed edge H3 index from origin and destination |
| `getH3IndexesFromUnidirectionalEdge` | `directedEdgeToCells` | Get [origin, destination] pair from directed edge |
| `getOriginH3IndexFromUnidirectionalEdge` | `getDirectedEdgeOrigin` | Provides origin hexagon from directed edge |
| `getDestinationH3IndexFromUnidirectionalEdge` | `getDirectedEdgeDestination` | Provides destination hexagon from directed edge |
| `getH3UnidirectionalEdgesFromHexagon` | `originToDirectedEdges` | Provides all directed edges from current cell |
| `getH3UnidirectionalEdgeBoundary` | `directedEdgeToBoundary` | Returns CellBoundary |

#### Area and Length Functions
| v3 Name | v4 Name | Notes |
|---------|---------|-------|
| `hexAreaKm2` | `getHexagonAreaAvgKm2` | Average hexagon area at resolution in km² |
| `hexAreaM2` | `getHexagonAreaAvgM2` | Average hexagon area at resolution in m² |
| `edgeLengthKm` | `getHexagonEdgeLengthAvgKm` | Average hexagon edge length at resolution in km |
| `edgeLengthM` | `getHexagonEdgeLengthAvgM` | Average hexagon edge length at resolution in m |
| `pointDistKm` | `greatCircleDistanceKm` | Great circle/haversine distance in km |
| `pointDistM` | `greatCircleDistanceM` | Great circle/haversine distance in m |
| `pointDistRads` | `greatCircleDistanceRads` | Great circle/haversine distance in radians |
| `exactEdgeLengthRads` | `edgeLengthRads` | Exact length of directed edge in radians |
| `exactEdgeLengthKm` | `edgeLengthKm` | Exact length of directed edge in km |
| `exactEdgeLengthM` | `edgeLengthM` | Exact length of directed edge in m |

#### Utility Functions
| v3 Name | v4 Name | Notes |
|---------|---------|-------|
| `numHexagons` | `getNumCells` | Total count of hexagons at given resolution |
| `getRes0Indexes` | `getRes0Cells` | All H3 indexes at resolution 0 |
| `getPentagonIndexes` | `getPentagons` | Twelve pentagon indexes at given resolution |
| `h3GetBaseCell` | `getBaseCellNumber` | Base cell number (0-121) of provided H3 cell |
| `h3GetResolution` | `getResolution` | Resolution of index (works for cells, edges, vertexes) |
| `h3GetFaces` | `getIcosahedronFaces` | All icosahedron faces intersected by H3 index |

### Internal Functions (Not Exposed in Public API)

The following functions are used internally for memory management and optimization but are not exposed in the public API:

- `maxGridDiskSize` - Memory allocation helper for gridDisk operations
- `gridDiskUnsafe` - Internal unsafe disk implementation  
- `gridDiskDistancesUnsafe` - Internal unsafe disk with distances
- `gridDiskDistancesSafe` - Internal safe disk with distances  
- `maxPolygonToCellsSize` - Memory allocation helper for polygon operations
- `cellToChildrenSize` - Memory allocation helper for cellToChildren
- `uncompactCellsSize` - Memory allocation helper for uncompactCells
- `maxFaceCount` - Memory allocation helper for face operations
- `gridPathCellsSize` - Memory allocation helper for gridPathCells
- `res0CellCount` - Internal constant (122)
- `pentagonCount` - Internal constant (12)
- `destroyLinkedMultiPolygon` - Internal memory cleanup

### Deprecated / Removed Functions

The following functions were mentioned in migration guides or legacy code but are not implemented in H3 v4:

- `isValidIndex` - Not in C code, only in migration guide
- `cellToLoop` - Does not exist in v4
- `loopToBoundary` - Does not exist in v4  
- `boundaryToLoop` - Does not exist in v4
- `gridDiskSafe` - Replaced by `gridDisk`
- `gridRingSafe` - Internal, not API - use `gridRingUnsafe`
- `destinationToDirectedEdges` - Does not exist in v4
- `gridPathEdges` - Does not exist in v4
- `getMode` - Does not exist in v4
- `gridPathDirectedEdges` - Does not exist in v4
- `getPentagonAreaAvg` - Future implementation
- `getPentagonEdgeLengthAvg` - Future implementation

### Technical Changes

#### C API Integration
All functions now follow the H3 v4.2.1 C API pattern where:
- Output parameters are passed as pointers 
- Functions return `H3Error` status codes instead of direct values
- Error handling is more robust with specific error codes [0-15]

#### Multi-Platform Support
- **VM Dart**: Uses FFI implementation with direct C library binding
- **Web**: Uses dart-js-ffigen for JavaScript interop
- **Flutter**: Unified API across all supported platforms

#### String Conversion
- `h3ToString` - Converts H3Index to string representation
- `stringToH3` - Converts string representation to H3Index

#### Unit Conversion Utilities  
- `radsToDegs` - Converts radians to degrees
- `degsToRads` - Converts degrees to radians

### Breaking Changes

This is a complete rewrite targeting H3 v4.2.1, so all existing code using the old festelo packages will need to be migrated. Key migration points:

1. **Package Names**: Update all imports from `h3_*` to `h3_*_plus`
2. **Function Names**: Update all function calls according to the v3→v4 mapping table above  
3. **Return Values**: Handle new error-based return pattern instead of direct value returns
4. **Edge Terminology**: Update "UnidirectionalEdge" to "DirectedEdge" throughout codebase
5. **New Vertex APIs**: Leverage new vertex mode functions for advanced geometric operations

### Dependencies

- Targets H3 C library v4.2.1
- Compatible with Dart SDK constraints as specified in pubspec.yaml
- Flutter compatibility maintained across all supported platforms
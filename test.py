import re

def parse_c_header_to_csv(header_content):
    # Pre-process to remove comments
    # Remove block comments /* ... */
    content = re.sub(r"/\*.*?\*/", "", header_content, flags=re.DOTALL)
    # Remove line comments // ...
    content = re.sub(r"//.*", "", content)
    # Remove preprocessor directives that might interfere if they are on the same line
    # (though unlikely for function signatures)
    content = re.sub(r"^\s*#.*", "", content, flags=re.MULTILINE)

    # Regex to capture function declarations:
    # DECLSPEC (return_type) H3_EXPORT(function_name) (parameters_raw) ;
    function_regex = re.compile(
        r"DECLSPEC\s+"              # DECLSPEC keyword and mandatory space
        r"([\w\s*<>:]+?)"           # Group 1: Return type (non-greedy). Allows for "const char *", "H3Error", "struct Type*", etc.
        r"\s+H3_EXPORT\((\w+)\)"     # Group 2: Function name inside H3_EXPORT()
        r"\s*\(([^)]*)\)\s*;"      # Group 3: Raw parameters string inside (), captures anything not a ')'
                                    # \s* before ; handles potential space: `)( );`
    )

    csv_lines = ['"FunctionName","Parameters","ReturnType"'] # CSV Header with quotes for safety

    # Iterate over matches
    for match in function_regex.finditer(content):
        return_type_raw = match.group(1).strip()
        function_name = match.group(2).strip()
        params_raw = match.group(3).strip()

        # Normalize spaces in return type (e.g., "const char *  " -> "const char *")
        return_type = ' '.join(return_type_raw.split())

        parsed_params = []
        if params_raw == "void" or not params_raw: # No parameters
            formatted_params_str = ""
        else:
            param_list = params_raw.split(',') # Split parameters by comma
            for p_item in param_list:
                p_item = p_item.strip() # Clean whitespace for each parameter item
                if not p_item:
                    continue # Skip if empty (e.g., trailing comma)

                # Split parameter into type and name.
                # Assumption: the last "word" (identifier) in the parameter string is the name.
                # Everything before it constitutes the type.
                last_space_idx = p_item.rfind(' ')

                if last_space_idx == -1:
                    # This case implies a parameter without a name or a type that has no spaces,
                    # e.g., "int" (if name was omitted, not standard for defs) or "MyType" (if name omitted).
                    # For this H3 API, all parameters are named. This path is unlikely.
                    # If it were to happen, treat the whole item as type.
                    param_type_str = p_item
                    param_name_str = "" # Or some placeholder like "_unnamed"
                else:
                    param_type_str = p_item[:last_space_idx].strip()
                    param_name_str = p_item[last_space_idx+1:].strip()

                # Handle cases where '*' might be with the name (e.g., "int *ptr")
                # and ensure it's associated with the type.
                if param_name_str.startswith('*'):
                    # Count '*' to handle multiple pointers like '**'
                    num_stars = param_name_str.count('*')
                    param_type_str += " " + ('*' * num_stars)
                    param_name_str = param_name_str.lstrip('*')

                param_type = ' '.join(param_type_str.split()) # Normalize spaces in type
                param_name = param_name_str

                if param_name: # If a name was successfully parsed
                    parsed_params.append(f"{param_name} ({param_type})")
                else: # If no name (should ideally not happen for this API)
                    parsed_params.append(f"({param_type})") # Store as unnamed param with type

            formatted_params_str = "; ".join(parsed_params)

        # Enclose each field in double quotes for CSV robustness (handles commas in future types etc.)
        csv_lines.append(f'"{function_name}","{formatted_params_str}","{return_type}"')

    return "\n".join(csv_lines)

# --- Provide the h3api.h content here ---
h3api_h_content = """
/*
 * Copyright 2016-2021 Uber Technologies, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/** @file h3api.h
 * @brief   Primary H3 core library entry points.
 *
 * This file defines the public API of the H3 library. Incompatible changes to
 * these functions require the library's major version be increased.
 */

#ifndef H3API_H
#define H3API_H

/*
 * Preprocessor code to support renaming (prefixing) the public API.
 * All public functions should be wrapped in H3_EXPORT so they can be
 * renamed.
 */
#ifdef H3_PREFIX
#define XTJOIN(a, b) a##b
#define TJOIN(a, b) XTJOIN(a, b)

/* export joins the user provided prefix with our exported function name */
#define H3_EXPORT(name) TJOIN(H3_PREFIX, name)
#else
#define H3_EXPORT(name) name
#endif

/* Windows DLL requires attributes indicating what to export */
#if _WIN32 && BUILD_SHARED_LIBS
#if BUILDING_H3
#define DECLSPEC __declspec(dllexport)
#else
#define DECLSPEC __declspec(dllimport)
#endif
#else
#define DECLSPEC
#endif

/* For uint64_t */
#include <stdint.h>
/* For size_t */
#include <stdlib.h>

/*
 * H3 is compiled as C, not C++ code. `extern "C"` is needed for C++ code
 * to be able to use the library.
 */
#ifdef __cplusplus
extern "C" {
#endif

/** @brief Identifier for an object (cell, edge, etc) in the H3 system.
 *
 * The H3Index fits within a 64-bit unsigned integer.
 */
typedef uint64_t H3Index;

/**
 * Invalid index used to indicate an error from latLngToCell and related
 * functions or missing data in arrays of H3 indices. Analogous to NaN in
 * floating point.
 */
#define H3_NULL 0

/** @brief Result code (success or specific error) from an H3 operation */
typedef uint32_t H3Error;

typedef enum {
    E_SUCCESS = 0,  // Success (no error)
    E_FAILED =
        1,  // The operation failed but a more specific error is not available
    E_DOMAIN = 2,  // Argument was outside of acceptable range (when a more
                   // specific error code is not available)
    E_LATLNG_DOMAIN =
        3,  // Latitude or longitude arguments were outside of acceptable range
    E_RES_DOMAIN = 4,    // Resolution argument was outside of acceptable range
    E_CELL_INVALID = 5,  // `H3Index` cell argument was not valid
    E_DIR_EDGE_INVALID = 6,  // `H3Index` directed edge argument was not valid
    E_UNDIR_EDGE_INVALID =
        7,                 // `H3Index` undirected edge argument was not valid
    E_VERTEX_INVALID = 8,  // `H3Index` vertex argument was not valid
    E_PENTAGON = 9,  // Pentagon distortion was encountered which the algorithm
                     // could not handle it
    E_DUPLICATE_INPUT = 10,  // Duplicate input was encountered in the arguments
                             // and the algorithm could not handle it
    E_NOT_NEIGHBORS = 11,    // `H3Index` cell arguments were not neighbors
    E_RES_MISMATCH =
        12,  // `H3Index` cell arguments had incompatible resolutions
    E_MEMORY_ALLOC = 13,   // Necessary memory allocation failed
    E_MEMORY_BOUNDS = 14,  // Bounds of provided memory were not large enough
    E_OPTION_INVALID = 15  // Mode or flags argument was not valid.
} H3ErrorCodes;

/** @defgroup describeH3Error describeH3Error
 * Functions for describeH3Error
 * @{
 */
/** @brief converts the provided H3Error value into a description string */
DECLSPEC const char *H3_EXPORT(describeH3Error)(H3Error err);
/** @} */

/* library version numbers generated from VERSION file */
// clang-format off
#define H3_VERSION_MAJOR 4
#define H3_VERSION_MINOR 2
#define H3_VERSION_PATCH 1
// clang-format on

/** Maximum number of cell boundary vertices; worst case is pentagon:
 *  5 original verts + 5 edge crossings
 */
#define MAX_CELL_BNDRY_VERTS 10

/** @struct LatLng
    @brief latitude/longitude in radians
*/
typedef struct {
    double lat;  ///< latitude in radians
    double lng;  ///< longitude in radians
} LatLng;

/** @struct CellBoundary
    @brief cell boundary in latitude/longitude
*/
typedef struct {
    int numVerts;                        ///< number of vertices
    LatLng verts[MAX_CELL_BNDRY_VERTS];  ///< vertices in ccw order
} CellBoundary;

/** @struct GeoLoop
 *  @brief similar to CellBoundary, but requires more alloc work
 */
typedef struct {
    int numVerts;
    LatLng *verts;
} GeoLoop;

/** @struct GeoPolygon
 *  @brief Simplified core of GeoJSON Polygon coordinates definition
 */
typedef struct {
    GeoLoop geoloop;  ///< exterior boundary of the polygon
    int numHoles;     ///< number of elements in the array pointed to by holes
    GeoLoop *holes;   ///< interior boundaries (holes) in the polygon
} GeoPolygon;

/** @struct GeoMultiPolygon
 *  @brief Simplified core of GeoJSON MultiPolygon coordinates definition
 */
typedef struct {
    int numPolygons;
    GeoPolygon *polygons;
} GeoMultiPolygon;

/**
 * Values representing polyfill containment modes, to be used in
 * the `flags` bit field for `polygonToCellsExperimental`.
 */
typedef enum {
    CONTAINMENT_CENTER = 0,       ///< Cell center is contained in the shape
    CONTAINMENT_FULL = 1,         ///< Cell is fully contained in the shape
    CONTAINMENT_OVERLAPPING = 2,  ///< Cell overlaps the shape at any point
    CONTAINMENT_OVERLAPPING_BBOX = 3,  ///< Cell bounding box overlaps shape
    CONTAINMENT_INVALID = 4  ///< This mode is invalid and should not be used
} ContainmentMode;

/** @struct LinkedLatLng
 *  @brief A coordinate node in a linked geo structure, part of a linked list
 */
typedef struct LinkedLatLng LinkedLatLng;
struct LinkedLatLng {
    LatLng vertex;
    LinkedLatLng *next;
};

/** @struct LinkedGeoLoop
 *  @brief A loop node in a linked geo structure, part of a linked list
 */
typedef struct LinkedGeoLoop LinkedGeoLoop;
struct LinkedGeoLoop {
    LinkedLatLng *first;
    LinkedLatLng *last;
    LinkedGeoLoop *next;
};

/** @struct LinkedGeoPolygon
 *  @brief A polygon node in a linked geo structure, part of a linked list.
 */
typedef struct LinkedGeoPolygon LinkedGeoPolygon;
struct LinkedGeoPolygon {
    LinkedGeoLoop *first;
    LinkedGeoLoop *last;
    LinkedGeoPolygon *next;
};

/** @struct CoordIJ
 * @brief IJ hexagon coordinates
 *
 * Each axis is spaced 120 degrees apart.
 */
typedef struct {
    int i;  ///< i component
    int j;  ///< j component
} CoordIJ;

/** @defgroup latLngToCell latLngToCell
 * Functions for latLngToCell
 * @{
 */
/** @brief find the H3 index of the resolution res cell containing the lat/lng
 */
DECLSPEC H3Error H3_EXPORT(latLngToCell)(const LatLng *g, int res,
                                         H3Index *out);
/** @} */

/** @defgroup cellToLatLng cellToLatLng
 * Functions for cellToLatLng
 * @{
 */
/** @brief find the lat/lng center point g of the cell h3 */
DECLSPEC H3Error H3_EXPORT(cellToLatLng)(H3Index h3, LatLng *g);
/** @} */

/** @defgroup cellToBoundary cellToBoundary
 * Functions for cellToBoundary
 * @{
 */
/** @brief give the cell boundary in lat/lng coordinates for the cell h3 */
DECLSPEC H3Error H3_EXPORT(cellToBoundary)(H3Index h3, CellBoundary *gp);
/** @} */

/** @defgroup gridDisk gridDisk
 * Functions for gridDisk
 * @{
 */
/** @brief maximum number of hexagons in k-ring */
DECLSPEC H3Error H3_EXPORT(maxGridDiskSize)(int k, int64_t *out);

/** @brief hexagons neighbors in all directions, assuming no pentagons */
DECLSPEC H3Error H3_EXPORT(gridDiskUnsafe)(H3Index origin, int k, H3Index *out);
/** @} */

/** @brief hexagons neighbors in all directions, assuming no pentagons,
 * reporting distance from origin */
DECLSPEC H3Error H3_EXPORT(gridDiskDistancesUnsafe)(H3Index origin, int k,
                                                    H3Index *out,
                                                    int *distances);

/** @brief hexagons neighbors in all directions reporting distance from origin
 */
DECLSPEC H3Error H3_EXPORT(gridDiskDistancesSafe)(H3Index origin, int k,
                                                  H3Index *out, int *distances);

/** @brief collection of hex rings sorted by ring for all given hexagons */
DECLSPEC H3Error H3_EXPORT(gridDisksUnsafe)(H3Index *h3Set, int length, int k,
                                            H3Index *out);

/** @brief hexagon neighbors in all directions */
DECLSPEC H3Error H3_EXPORT(gridDisk)(H3Index origin, int k, H3Index *out);
/** @} */

/** @defgroup gridDiskDistances gridDiskDistances
 * Functions for gridDiskDistances
 * @{
 */
/** @brief hexagon neighbors in all directions, reporting distance from origin
 */
DECLSPEC H3Error H3_EXPORT(gridDiskDistances)(H3Index origin, int k,
                                              H3Index *out, int *distances);
/** @} */

/** @defgroup gridRingUnsafe gridRingUnsafe
 * Functions for gridRingUnsafe
 * @{
 */
/** @brief hollow hexagon ring at some origin */
DECLSPEC H3Error H3_EXPORT(gridRingUnsafe)(H3Index origin, int k, H3Index *out);
/** @} */

/** @defgroup polygonToCells polygonToCells
 * Functions for polygonToCells
 * @{
 */
/** @brief maximum number of cells that could be in the polygon */
DECLSPEC H3Error H3_EXPORT(maxPolygonToCellsSize)(const GeoPolygon *geoPolygon,
                                                  int res, uint32_t flags,
                                                  int64_t *out);

/** @brief cells within the given polygon */
DECLSPEC H3Error H3_EXPORT(polygonToCells)(const GeoPolygon *geoPolygon,
                                           int res, uint32_t flags,
                                           H3Index *out);
/** @} */

/** @defgroup polygonToCellsExperimental polygonToCellsExperimental
 * Functions for polygonToCellsExperimental.
 * This is an experimental-only API and is subject to change in minor versions.
 * @{
 */
/** @brief maximum number of cells that could be in the polygon */
DECLSPEC H3Error H3_EXPORT(maxPolygonToCellsSizeExperimental)(
    const GeoPolygon *polygon, int res, uint32_t flags, int64_t *out);

/** @brief cells within the given polygon */
DECLSPEC H3Error H3_EXPORT(polygonToCellsExperimental)(
    const GeoPolygon *polygon, int res, uint32_t flags, int64_t size,
    H3Index *out);
/** @} */

/** @defgroup cellsToMultiPolygon cellsToMultiPolygon
 * Functions for cellsToMultiPolygon (currently a binding-only concept)
 * @{
 */
/** @brief Create a LinkedGeoPolygon from a set of contiguous hexagons */
DECLSPEC H3Error H3_EXPORT(cellsToLinkedMultiPolygon)(const H3Index *h3Set,
                                                      const int numHexes,
                                                      LinkedGeoPolygon *out);

/** @brief Free all memory created for a LinkedGeoPolygon */
DECLSPEC void H3_EXPORT(destroyLinkedMultiPolygon)(LinkedGeoPolygon *polygon);
/** @} */

/** @defgroup degsToRads degsToRads
 * Functions for degsToRads
 * @{
 */
/** @brief converts degrees to radians */
DECLSPEC double H3_EXPORT(degsToRads)(double degrees);
/** @} */

/** @defgroup radsToDegs radsToDegs
 * Functions for radsToDegs
 * @{
 */
/** @brief converts radians to degrees */
DECLSPEC double H3_EXPORT(radsToDegs)(double radians);
/** @} */

/** @defgroup greatCircleDistance greatCircleDistance
 * Functions for distance
 * @{
 */
/** @brief "great circle distance" between pairs of LatLng points in radians*/
DECLSPEC double H3_EXPORT(greatCircleDistanceRads)(const LatLng *a,
                                                   const LatLng *b);

/** @brief "great circle distance" between pairs of LatLng points in
 * kilometers*/
DECLSPEC double H3_EXPORT(greatCircleDistanceKm)(const LatLng *a,
                                                 const LatLng *b);

/** @brief "great circle distance" between pairs of LatLng points in meters*/
DECLSPEC double H3_EXPORT(greatCircleDistanceM)(const LatLng *a,
                                                const LatLng *b);
/** @} */

/** @defgroup getHexagonAreaAvg getHexagonAreaAvg
 * Functions for getHexagonAreaAvg
 * @{
 */
/** @brief average hexagon area in square kilometers (excludes pentagons) */
DECLSPEC H3Error H3_EXPORT(getHexagonAreaAvgKm2)(int res, double *out);

/** @brief average hexagon area in square meters (excludes pentagons) */
DECLSPEC H3Error H3_EXPORT(getHexagonAreaAvgM2)(int res, double *out);
/** @} */

/** @defgroup cellArea cellArea
 * Functions for cellArea
 * @{
 */
/** @brief exact area for a specific cell (hexagon or pentagon) in radians^2 */
DECLSPEC H3Error H3_EXPORT(cellAreaRads2)(H3Index h, double *out);

/** @brief exact area for a specific cell (hexagon or pentagon) in kilometers^2
 */
DECLSPEC H3Error H3_EXPORT(cellAreaKm2)(H3Index h, double *out);

/** @brief exact area for a specific cell (hexagon or pentagon) in meters^2 */
DECLSPEC H3Error H3_EXPORT(cellAreaM2)(H3Index h, double *out);
/** @} */

/** @defgroup getHexagonEdgeLengthAvg getHexagonEdgeLengthAvg
 * Functions for getHexagonEdgeLengthAvg
 * @{
 */
/** @brief average hexagon edge length in kilometers (excludes pentagons) */
DECLSPEC H3Error H3_EXPORT(getHexagonEdgeLengthAvgKm)(int res, double *out);

/** @brief average hexagon edge length in meters (excludes pentagons) */
DECLSPEC H3Error H3_EXPORT(getHexagonEdgeLengthAvgM)(int res, double *out);
/** @} */

/** @defgroup edgeLength edgeLength
 * Functions for edgeLength
 * @{
 */
/** @brief exact length for a specific directed edge in radians*/
DECLSPEC H3Error H3_EXPORT(edgeLengthRads)(H3Index edge, double *length);

/** @brief exact length for a specific directed edge in kilometers*/
DECLSPEC H3Error H3_EXPORT(edgeLengthKm)(H3Index edge, double *length);

/** @brief exact length for a specific directed edge in meters*/
DECLSPEC H3Error H3_EXPORT(edgeLengthM)(H3Index edge, double *length);
/** @} */

/** @defgroup getNumCells getNumCells
 * Functions for getNumCells
 * @{
 */
/** @brief number of cells (hexagons and pentagons) for a given resolution
 *
 * It works out to be `2 + 120*7^r` for resolution `r`.
 *
 * # Mathematical notes
 *
 * Let h(n) be the number of children n levels below
 * a single *hexagon*.
 *
 * Then h(n) = 7^n.
 *
 * Let p(n) be the number of children n levels below
 * a single *pentagon*.
 *
 * Then p(0) = 1, and p(1) = 6, since each pentagon
 * has 5 hexagonal immediate children and 1 pentagonal
 * immediate child.
 *
 * In general, we have the recurrence relation
 *
 * p(n) = 5*h(n-1) + p(n-1)
 *      = 5*7^(n-1) + p(n-1).
 *
 * Working through the recurrence, we get that
 *
 * p(n) = 1 + 5*\sum_{k=1}^n 7^{k-1}
 *      = 1 + 5*(7^n - 1)/6,
 *
 * using the closed form for a geometric series.
 *
 * Using the closed forms for h(n) and p(n), we can
 * get a closed form for the total number of cells
 * at resolution r:
 *
 * c(r) = 12*p(r) + 110*h(r)
 *      = 2 + 120*7^r.
 *
 *
 * @param   res  H3 cell resolution
 *
 * @return       number of cells at resolution `res`
 */
DECLSPEC H3Error H3_EXPORT(getNumCells)(int res, int64_t *out);
/** @} */

/** @defgroup getRes0Cells getRes0Cells
 * Functions for getRes0Cells
 * @{
 */
/** @brief returns the number of resolution 0 cells (hexagons and pentagons) */
DECLSPEC int H3_EXPORT(res0CellCount)(void);

/** @brief provides all base cells in H3Index format*/
DECLSPEC H3Error H3_EXPORT(getRes0Cells)(H3Index *out);
/** @} */

/** @defgroup getPentagons getPentagons
 * Functions for getPentagons
 * @{
 */
/** @brief returns the number of pentagons per resolution */
DECLSPEC int H3_EXPORT(pentagonCount)(void);

/** @brief generates all pentagons at the specified resolution */
DECLSPEC H3Error H3_EXPORT(getPentagons)(int res, H3Index *out);
/** @} */

/** @defgroup getResolution getResolution
 * Functions for getResolution
 * @{
 */
/** @brief returns the resolution of the provided H3 index
 * Works on both cells and directed edges. */
DECLSPEC int H3_EXPORT(getResolution)(H3Index h);
/** @} */

/** @defgroup getBaseCellNumber getBaseCellNumber
 * Functions for getBaseCellNumber
 * @{
 */
/** @brief returns the base cell "number" (0 to 121) of the provided H3 cell
 *
 * Note: Technically works on H3 edges, but will return base cell of the
 * origin cell. */
DECLSPEC int H3_EXPORT(getBaseCellNumber)(H3Index h);
/** @} */

/** @defgroup stringToH3 stringToH3
 * Functions for stringToH3
 * @{
 */
/** @brief converts the canonical string format to H3Index format */
DECLSPEC H3Error H3_EXPORT(stringToH3)(const char *str, H3Index *out);
/** @} */

/** @defgroup h3ToString h3ToString
 * Functions for h3ToString
 * @{
 */
/** @brief converts an H3Index to a canonical string */
DECLSPEC H3Error H3_EXPORT(h3ToString)(H3Index h, char *str, size_t sz);
/** @} */

/** @defgroup isValidCell isValidCell
 * Functions for isValidCell
 * @{
 */
/** @brief confirms if an H3Index is a valid cell (hexagon or pentagon)
 * In particular, returns 0 (False) for H3 directed edges or invalid data
 */
DECLSPEC int H3_EXPORT(isValidCell)(H3Index h);
/** @} */

/** @defgroup cellToParent cellToParent
 * Functions for cellToParent
 * @{
 */
/** @brief returns the parent (or grandparent, etc) cell of the given cell
 */
DECLSPEC H3Error H3_EXPORT(cellToParent)(H3Index h, int parentRes,
                                         H3Index *parent);
/** @} */

/** @defgroup cellToChildren cellToChildren
 * Functions for cellToChildren
 * @{
 */
/** @brief determines the exact number of children (or grandchildren, etc)
 * that would be returned for the given cell */
DECLSPEC H3Error H3_EXPORT(cellToChildrenSize)(H3Index h, int childRes,
                                               int64_t *out);

/** @brief provides the children (or grandchildren, etc) of the given cell */
DECLSPEC H3Error H3_EXPORT(cellToChildren)(H3Index h, int childRes,
                                           H3Index *children);
/** @} */

/** @defgroup cellToCenterChild cellToCenterChild
 * Functions for cellToCenterChild
 * @{
 */
/** @brief returns the center child of the given cell at the specified
 * resolution */
DECLSPEC H3Error H3_EXPORT(cellToCenterChild)(H3Index h, int childRes,
                                              H3Index *child);
/** @} */

/** @defgroup cellToChildPos cellToChildPos
 * Functions for cellToChildPos
 * @{
 */
/** @brief Returns the position of the cell within an ordered list of all
 * children of the cell's parent at the specified resolution */
DECLSPEC H3Error H3_EXPORT(cellToChildPos)(H3Index child, int parentRes,
                                           int64_t *out);
/** @} */

/** @defgroup childPosToCell childPosToCell
 * Functions for childPosToCell
 * @{
 */
/** @brief Returns the child cell at a given position within an ordered list of
 * all children at the specified resolution */
DECLSPEC H3Error H3_EXPORT(childPosToCell)(int64_t childPos, H3Index parent,
                                           int childRes, H3Index *child);
/** @} */

/** @defgroup compactCells compactCells
 * Functions for compactCells
 * @{
 */
/** @brief compacts the given set of hexagons as best as possible */
DECLSPEC H3Error H3_EXPORT(compactCells)(const H3Index *h3Set,
                                         H3Index *compactedSet,
                                         const int64_t numHexes);
/** @} */

/** @defgroup uncompactCells uncompactCells
 * Functions for uncompactCells
 * @{
 */
/** @brief determines the exact number of hexagons that will be uncompacted
 * from the compacted set */
DECLSPEC H3Error H3_EXPORT(uncompactCellsSize)(const H3Index *compactedSet,
                                               const int64_t numCompacted,
                                               const int res, int64_t *out);

/** @brief uncompacts the compacted hexagon set */
DECLSPEC H3Error H3_EXPORT(uncompactCells)(const H3Index *compactedSet,
                                           const int64_t numCompacted,
                                           H3Index *outSet,
                                           const int64_t numOut, const int res);
/** @} */

/** @defgroup isResClassIII isResClassIII
 * Functions for isResClassIII
 * @{
 */
/** @brief determines if a hexagon is Class III (or Class II) */
DECLSPEC int H3_EXPORT(isResClassIII)(H3Index h);
/** @} */

/** @defgroup isPentagon isPentagon
 * Functions for isPentagon
 * @{
 */
/** @brief determines if an H3 cell is a pentagon */
DECLSPEC int H3_EXPORT(isPentagon)(H3Index h);
/** @} */

/** @defgroup getIcosahedronFaces getIcosahedronFaces
 * Functions for getIcosahedronFaces
 * @{
 */
/** @brief Max number of icosahedron faces intersected by an index */
DECLSPEC H3Error H3_EXPORT(maxFaceCount)(H3Index h3, int *out);

/** @brief Find all icosahedron faces intersected by a given H3 index */
DECLSPEC H3Error H3_EXPORT(getIcosahedronFaces)(H3Index h3, int *out);
/** @} */

/** @defgroup areNeighborCells areNeighborCells
 * Functions for areNeighborCells
 * @{
 */
/** @brief returns whether or not the provided hexagons border */
DECLSPEC H3Error H3_EXPORT(areNeighborCells)(H3Index origin,
                                             H3Index destination, int *out);
/** @} */

/** @defgroup cellsToDirectedEdge cellsToDirectedEdge
 * Functions for cellsToDirectedEdge
 * @{
 */
/** @brief returns the directed edge H3Index for the specified origin and
 * destination */
DECLSPEC H3Error H3_EXPORT(cellsToDirectedEdge)(H3Index origin,
                                                H3Index destination,
                                                H3Index *out);
/** @} */

/** @defgroup isValidDirectedEdge isValidDirectedEdge
 * Functions for isValidDirectedEdge
 * @{
 */
/** @brief returns whether the H3Index is a valid directed edge */
DECLSPEC int H3_EXPORT(isValidDirectedEdge)(H3Index edge);
/** @} */

/** @defgroup getDirectedEdgeOrigin \
 * getDirectedEdgeOrigin
 * Functions for getDirectedEdgeOrigin
 * @{
 */
/** @brief Returns the origin hexagon H3Index from the directed edge
 * H3Index */
DECLSPEC H3Error H3_EXPORT(getDirectedEdgeOrigin)(H3Index edge, H3Index *out);
/** @} */

/** @defgroup getDirectedEdgeDestination \
 * getDirectedEdgeDestination
 * Functions for getDirectedEdgeDestination
 * @{
 */
/** @brief Returns the destination hexagon H3Index from the directed edge
 * H3Index */
DECLSPEC H3Error H3_EXPORT(getDirectedEdgeDestination)(H3Index edge,
                                                       H3Index *out);
/** @} */

/** @defgroup directedEdgeToCells \
 * directedEdgeToCells
 * Functions for directedEdgeToCells
 * @{
 */
/** @brief Returns the origin and destination hexagons from the directed
 * edge H3Index */
DECLSPEC H3Error H3_EXPORT(directedEdgeToCells)(H3Index edge,
                                                H3Index *originDestination);
/** @} */

/** @defgroup originToDirectedEdges \
 * originToDirectedEdges
 * Functions for originToDirectedEdges
 * @{
 */
/** @brief Returns the 6 (or 5 for pentagons) edges associated with the H3Index
 */
DECLSPEC H3Error H3_EXPORT(originToDirectedEdges)(H3Index origin,
                                                  H3Index *edges);
/** @} */

/** @defgroup directedEdgeToBoundary directedEdgeToBoundary
 * Functions for directedEdgeToBoundary
 * @{
 */
/** @brief Returns the CellBoundary containing the coordinates of the edge */
DECLSPEC H3Error H3_EXPORT(directedEdgeToBoundary)(H3Index edge,
                                                   CellBoundary *gb);
/** @} */

/** @defgroup cellToVertex cellToVertex
 * Functions for cellToVertex
 * @{
 */
/** @brief Returns a single vertex for a given cell, as an H3 index */
DECLSPEC H3Error H3_EXPORT(cellToVertex)(H3Index origin, int vertexNum,
                                         H3Index *out);
/** @} */

/** @defgroup cellToVertexes cellToVertexes
 * Functions for cellToVertexes
 * @{
 */
/** @brief Returns all vertexes for a given cell, as H3 indexes */
DECLSPEC H3Error H3_EXPORT(cellToVertexes)(H3Index origin, H3Index *vertexes);
/** @} */

/** @defgroup vertexToLatLng vertexToLatLng
 * Functions for vertexToLatLng
 * @{
 */
/** @brief Returns a single vertex for a given cell, as an H3 index */
DECLSPEC H3Error H3_EXPORT(vertexToLatLng)(H3Index vertex, LatLng *point);
/** @} */

/** @defgroup isValidVertex isValidVertex
 * Functions for isValidVertex
 * @{
 */
/** @brief Whether the input is a valid H3 vertex */
DECLSPEC int H3_EXPORT(isValidVertex)(H3Index vertex);
/** @} */

/** @defgroup gridDistance gridDistance
 * Functions for gridDistance
 * @{
 */
/** @brief Returns grid distance between two indexes */
DECLSPEC H3Error H3_EXPORT(gridDistance)(H3Index origin, H3Index h3,
                                         int64_t *distance);
/** @} */

/** @defgroup gridPathCells gridPathCells
 * Functions for gridPathCells
 * @{
 */
/** @brief Number of indexes in a line connecting two indexes */
DECLSPEC H3Error H3_EXPORT(gridPathCellsSize)(H3Index start, H3Index end,
                                              int64_t *size);

/** @brief Line of h3 indexes connecting two indexes */
DECLSPEC H3Error H3_EXPORT(gridPathCells)(H3Index start, H3Index end,
                                          H3Index *out);
/** @} */

/** @defgroup cellToLocalIj cellToLocalIj
 * Functions for cellToLocalIj
 * @{
 */
/** @brief Returns two dimensional coordinates for the given index */
DECLSPEC H3Error H3_EXPORT(cellToLocalIj)(H3Index origin, H3Index h3,
                                          uint32_t mode, CoordIJ *out);
/** @} */

/** @defgroup localIjToCell localIjToCell
 * Functions for localIjToCell
 * @{
 */
/** @brief Returns index for the given two dimensional coordinates */
DECLSPEC H3Error H3_EXPORT(localIjToCell)(H3Index origin, const CoordIJ *ij,
                                          uint32_t mode, H3Index *out);
/** @} */

#ifdef __cplusplus
}  // extern "C"
#endif

#endif
"""

# Generate the CSV content
csv_output = parse_c_header_to_csv(h3api_h_content)

# Print the CSV output (or you can save it to a file)
print(csv_output)
# Define the output filename
output_filename = "h3_api_functions.csv"

# Write the CSV output to a file
try:
    with open(output_filename, "w", encoding="utf-8") as f:
        f.write(csv_output)
    print(f"Successfully saved H3 API function data to {output_filename}")
except IOError as e:
    print(f"Error writing to file {output_filename}: {e}")
# Contributing to h3\_flutter\_plus

Thank you for your interest in contributing to the `h3_flutter_plus` ecosystem!
This guide provides step-by-step instructions for contributing across all related packages:

* `h3_common_plus`
* `h3_ffi_plus`
* `h3_web_plus`
* `geojson2h3_plus`
* `h3_dart_plus`
* `h3_flutter_plus`

---

## Local Development Setup

### 1. Use Path Dependencies

Edit each `pubspec.yaml` file to use local path references instead of published versions:

```yaml
  h3_common_plus:
    path: ../h3_common_plus
```

Do this for all 6 packages where dependencies are internal.

### 2. Refresh Package Cache

Run the following to sync dependencies:

* For `h3_flutter_plus`:

```bash
flutter pub get
```

* For others:

```bash
dart pub get
```

---

## Making Updates Without FFI Version Changes

If you're only fixing bugs, improving exception handling, or making changes that do not require updating the underlying C or JS libraries (e.g., logic changes or internal Dart API improvements), you can:

1. Make changes directly in `h3_common_plus`.
2. Update corresponding logic in both `h3_ffi_plus` and `h3_web_plus`.
3. Follow the usual steps for testing, verification, and publishing.

You **do not** need to regenerate the C or JS bindings for such changes.

---

## Updating the H3 C & JS Library Version

### Step-by-Step: Native H3 Update

1. Clone Uber's H3 repo:

```bash
git clone https://github.com/uber/h3.git
cd h3
```

2. Create a build directory and run:

```bash
mkdir build && cd build
cmake ..
```

> This step generates the important `h3api.h` file from `h3api.h.in` using CMake.

3. Copy files to `h3_ffi_plus`:

   * `h3api.h` from `build/src/h3lib/include` → `h3_ffi_plus/c/h3lib`
   * All `.h` files from `h3/src/h3lib/include/` (excluding `h3api.h.in`) → `h3_ffi_plus/c/h3lib`
   * All `.c` files from `h3/src/h3lib/lib/` → `h3_ffi_plus/c/h3lib`

4. Build the C library using:

```bash
cd h3_ffi_plus
./scripts/build_h3.sh
```

Or use the CMake file directly.

---

## FFI Bindings Generation (Only Needed If Native C Library Changes)

### 1. Update `ffigen.yaml`

Add all public API functions and required internals (e.g. `maxPolygonToCellsSize`).

### 2. Generate Bindings:

```bash
cd h3_ffi_plus
dart run ffigen --config ./ffigen.yaml
```

This will regenerate: `lib/src/generated/generated_bindings.dart`

---

## Bindings Implementation

### Dart VM / Flutter (Non-Web)

If you've made changes to the native C library (FFI update):

1. Generate updated FFI bindings (see previous section).
2. Update `h3_common_plus` with new function signatures and documentation.
3. Implement the new bindings in:

```dart
h3_ffi_plus/lib/src/h3_ffi_plus.dart
```

If you're making non-FFI changes:

1. Update logic and signatures in `h3_common_plus`.
2. Reflect these updates in:

```dart
h3_ffi_plus/lib/src/h3_ffi_plus.dart
```

### Web (h3-js)

If you're making non-FFI changes:

1. Update logic and signatures in `h3_common_plus`.
2. Implement those changes in:

```dart
h3_web_plus/lib/src/h3_web_plus.dart
```

If you're updating the JS FFI layer (e.g., new version of h3-js):

1. Update version in `package.json`
2. Generate bindings:

```bash
npm install && npm run generate
```

Or with `pnpm`:

```bash
pnpm install && pnpm generate
```

This regenerates: `h3_web_plus/lib/src/generated/types.dart`

3. Update implementation in:

```dart
h3_web_plus/lib/src/h3_web_plus.dart
```

**Note:** Always use explicit casting and null checks in web bindings, even if the Dart analyzer says they’re safe.

---

## Testing & Verification

* Write proper test cases across platforms.
* Run tests locally and ensure cross-platform compatibility.
* If packages aren't resolving: rerun `pub get` for all packages to refresh the local cache.

---

## Final Verification

Update and try the example usage in the `example/` folders to confirm correctness. Sometimes the example code needs to be changed to align with recent updates. Make sure the example is working and up to date with the current changes.

---

## Final Release Steps

1. Document your changes (CHANGELOG.md, commit message, PR, etc.)
2. Update README if necessary
3. Bump versions in each `pubspec.yaml`
4. Publish packages in this exact order:

   1. `h3_common_plus`
   2. `h3_ffi_plus`
   3. `h3_web_plus`
   4. `geojson2h3_plus`
   5. `h3_dart_plus`
   6. `h3_flutter_plus`

This order ensures correct resolution of dependencies.

---

Happy contributing!
For any queries or issues, please open a GitHub issue or discussion thread.

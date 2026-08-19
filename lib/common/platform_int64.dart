// Portable construction of FRB's `PlatformInt64` (`int` on IO platforms,
// `BigInt` on the web, where the widget previewer runs).
export 'platform_int64_io.dart' if (dart.library.js_interop) 'platform_int64_web.dart';

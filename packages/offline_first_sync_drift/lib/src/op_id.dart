import 'dart:math';
import 'dart:typed_data';

/// Internal generator for idempotency operation ids.
///
/// We intentionally avoid adding a public dependency on `package:uuid`.
/// The server contract only requires a unique string for idempotency keys.
abstract final class OpId {
  static final Random _random = Random.secure();

  /// Generate a UUID v4 string.
  static String v4() {
    final bytes = Uint8List(16);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }

    // Per RFC 4122:
    // - set version to 4
    // - set variant to 10xx
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

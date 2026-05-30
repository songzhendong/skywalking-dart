import 'dart:convert';

import 'sw8_context.dart';

/// Encode/decode SkyWalking `sw8` propagation header (v3).
abstract final class Sw8Codec {
  static const headerName = 'sw8';

  static String encode(Sw8Context ctx) {
    return [
      '${ctx.sample}',
      _b64(ctx.traceId),
      _b64(ctx.traceSegmentId),
      '${ctx.spanId}',
      _b64(ctx.service),
      _b64(ctx.serviceInstance),
      _b64(ctx.endpoint),
      _b64(ctx.peer),
    ].join('-');
  }

  static Sw8Context? decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.trim().split('-');
    if (parts.length < 8) return null;
    try {
      return Sw8Context(
        sample: int.parse(parts[0]),
        traceId: _ub64(parts[1]),
        traceSegmentId: _ub64(parts[2]),
        spanId: int.parse(parts[3]),
        service: _ub64(parts[4]),
        serviceInstance: _ub64(parts[5]),
        endpoint: _ub64(parts[6]),
        peer: _ub64(parts[7]),
      );
    } catch (_) {
      return null;
    }
  }

  static String _b64(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');

  static String _ub64(String value) =>
      utf8.decode(base64Url.decode(_pad(value)));

  static String _pad(String value) {
    final mod = value.length % 4;
    if (mod == 0) return value;
    return value + '=' * (4 - mod);
  }
}

import 'package:http/http.dart' as http;

import 'sw8_codec.dart';
import 'sw8_context.dart';

/// Injects `sw8` into outbound HTTP requests.
abstract final class Sw8Propagator {
  static void inject(http.BaseRequest request, Sw8Context context) {
    request.headers[Sw8Codec.headerName] = Sw8Codec.encode(context);
  }
}

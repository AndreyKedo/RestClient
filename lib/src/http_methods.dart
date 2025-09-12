import 'package:meta/meta.dart';

/// HTTP methods shortcuts.
///
/// Provides constants for standard HTTP methods.
///
/// * [HttpMethod.get]
/// * [HttpMethod.post]
/// * [HttpMethod.put]
/// * [HttpMethod.patch]
/// * [HttpMethod.delete]
/// * [HttpMethod.head]
extension type const HttpMethod._(String value) implements String {
  /// GET HTTP method.
  ///
  /// See [MDN documentation](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/GET)
  static const get = HttpMethod._('GET');

  /// POST HTTP method.
  ///
  /// See [MDN documentation](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/POST)
  static const post = HttpMethod._('POST');

  /// PUT HTTP method.
  ///
  /// See [MDN documentation](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/PUT)
  static const put = HttpMethod._('PUT');

  /// PATCH HTTP method.
  ///
  /// See [MDN documentation](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/PATCH)
  static const patch = HttpMethod._('PATCH');

  /// DELETE HTTP method.
  ///
  /// See [MDN documentation](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/DELETE)
  static const delete = HttpMethod._('DELETE');

  /// HEAD HTTP method.
  ///
  /// See [MDN documentation](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/HEAD)
  static const head = HttpMethod._('HEAD');

  @internal
  static void checkMethod(String value) {
    if (_availableMethods.contains(value)) return;
    throw ArgumentError.value(
      value,
      'method',
      'Not a valid method',
    );
  }

  static const _availableMethods = {
    get,
    post,
    put,
    patch,
    delete,
    head,
  };
}

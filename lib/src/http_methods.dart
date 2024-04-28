/*
* http_methods.dart
* Available HTTP methods.
* Dashkevich Andrey <dashkevich@ittest-team.ru>, 20 March 2024
*/

/// {@template rest_client.http_methods}
/// HTTP methods.
///
/// * [HttpMethod.get]
/// * [HttpMethod.post]
/// * [HttpMethod.put]
/// * [HttpMethod.patch]
/// * [HttpMethod.delete]
/// * [HttpMethod.head]
/// {@endtemplate}
extension type const HttpMethod._(String value) implements String {
  /// Info of [GET](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/GET)
  static const get = HttpMethod._('GET');

  /// Info of [POST](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/POST)
  static const post = HttpMethod._('POST');

  /// Info of [PUT](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/PUT)
  static const put = HttpMethod._('PUT');

  /// Info of [PATCH](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/PATCH)
  static const patch = HttpMethod._('PATCH');

  /// Info of [DELETE](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/DELETE)
  static const delete = HttpMethod._('DELETE');

  /// Info of [HEAD](https://developer.mozilla.org/en/docs/Web/HTTP/Methods/HEAD)
  static const head = HttpMethod._('HEAD');
}

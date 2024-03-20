/*
* http_methods.dart
* Available HTTP methods.
* Dashkevich Andrey <dashkevich@ittest-team.ru>, 20 March 2024
*/

/// {@template rest_client.http_methods}
/// REST api methods
///
/// [HttpMethod.get]
/// [HttpMethod.post]
/// [HttpMethod.put]
/// [HttpMethod.patch]
/// [HttpMethod.delete]
/// {@endtemplate}
extension type const HttpMethod._(String value) implements String {
  static const get = HttpMethod._('GET');
  static const post = HttpMethod._('POST');
  static const put = HttpMethod._('PUT');
  static const patch = HttpMethod._('PATCH');
  static const delete = HttpMethod._('DELETE');
}

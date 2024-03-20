part of '../../rest_client.dart';

abstract interface class _IRestMethods {
  /// {@template rest_client.http_methods.send}
  /// Base send request method.
  ///
  /// Used [HttpMethod] for create [request].
  ///
  /// Example:
  /// ```dart
  ///
  /// send(Request(HttpMethod.get, Uri.tryParse('example.com')))
  ///
  /// ```
  /// {@endtemplate}
  Future<StreamedResponse> send(BaseRequest request, {final RequestBody? body, final Map<String, String>? headers});

  /// {@template rest_client.http_methods.get}
  /// GET method.
  /// {@endtemplate}
  Future<RCResponse> get(Uri uri, {Map<String, String>? headers});

  /// {@template rest_client.http_methods.post}
  /// POST method.
  /// {@endtemplate}
  Future<RCResponse> post(Uri uri, {RequestBody? body, Map<String, String>? headers});

  /// {@template rest_client.http_methods.put}
  /// PUT method.
  /// {@endtemplate}
  Future<RCResponse> put(Uri uri, {RequestBody? body, Map<String, String>? headers});

  /// {@template rest_client.http_methods.delete}
  /// DELETE method.
  /// {@endtemplate}
  Future<RCResponse> delete(Uri uri, {RequestBody? body, Map<String, String>? headers});

  /// {@template rest_client.http_methods.patch}
  /// PATCH method.
  /// {@endtemplate}
  Future<RCResponse> patch(Uri uri, {RequestBody? body, Map<String, String>? headers});
}

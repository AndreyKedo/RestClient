part of '../../rest_client.dart';

///Request implementation mixin
base mixin _RequestAPI on _InterceptorAPI implements _IRestMethods {
  /// Build base request
  Future<RCResponse> _requestBuilder(String method, Uri uri, {RequestBody? body, Map<String, String>? headers}) async {
    final streamResponse = await send(Request(method, uri), body: body, headers: headers);
    final syncResponse = await Response.fromStream(streamResponse);
    return resolveResponse(syncResponse);
  }

  @override
  Future<RCResponse> get(Uri uri, {Map<String, String>? headers}) =>
      _requestBuilder(HttpMethod.get, uri, headers: headers);

  @override
  Future<RCResponse> post(Uri uri, {RequestBody? body, Map<String, String>? headers}) =>
      _requestBuilder(HttpMethod.post, body: body, uri, headers: headers);

  @override
  Future<RCResponse> put(Uri uri, {RequestBody? body, Map<String, String>? headers}) =>
      _requestBuilder(HttpMethod.put, uri, body: body, headers: headers);

  @override
  Future<RCResponse> patch(Uri uri, {RequestBody? body, Map<String, String>? headers}) =>
      _requestBuilder(HttpMethod.patch, uri, body: body, headers: headers);

  @override
  Future<RCResponse> delete(Uri uri, {RequestBody? body, Map<String, String>? headers}) =>
      _requestBuilder(HttpMethod.delete, uri, body: body, headers: headers);
}

part of '../../rest_client.dart';

final class _HttpClient = RestClient with _ClientBuilderAPI, _InterceptorAPI, _RequestAPI;

base mixin _ClientBuilderAPI on RestClient {
  Future<JWT?> get _getToken {
    if (session == null) return Future.value();
    return session!.jwtStore.read();
  }

  Future<Map<String, String>> get _headers async {
    final header = Map.of(configuration.headers);
    final token = await _getToken;
    if (token != null) {
      header['Authorization'] = 'Bearer ${token.source}';
    }
    return header;
  }

  Uri buildUri({
    required String path,
    Map<String, Object?>? queryParams,
  }) =>
      configuration.host.replace(
        path: path,
        queryParameters: queryParams,
      );

  @override
  void dispose() => _client.close();
}

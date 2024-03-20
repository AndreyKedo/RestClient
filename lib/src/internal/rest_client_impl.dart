part of '../../rest_client.dart';

final class _HttpClient = RestClient with _ClientBuilderAPI, _InterceptorAPI, _RequestAPI;

base mixin _ClientBuilderAPI on RestClient {
  late final Client _client = configuration.client();

  @override
  void dispose() => _client.close();
}

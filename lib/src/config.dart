/*
* config.dart
* Client configuration.
* Dashkevich Andrey, 13 March 2024
*/

part of 'rest_client_impl.dart';

/// {@template rest_client.client_factory}
/// Body of the template
/// {@endtemplate}
typedef ClientFactory = Client Function();

/// {@template rest_client.config}
/// Client configuration.
/// {@endtemplate}
class ClientConfig {
  /// {@macro rest_client.config}
  const ClientConfig(
      {this.interceptors = const [], this.clientFactory = defaultClientFactory, this.headers = defaultHeaders});

  /// Default headers.
  /// Will be used every time when request invoked.
  final Map<String, String> headers;

  /// Interceptors.
  final List<SendInterceptor> interceptors;

  /// Client factory.
  final ClientFactory clientFactory;

  /// Default client factory based [Client]
  static Client defaultClientFactory() => Client();

  /// Default client headers.
  static const defaultHeaders = {'Accept': 'application/json', 'Content-Type': 'application/json'};
}

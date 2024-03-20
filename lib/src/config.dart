/*
* config.dart
* Client configuration.
* Dashkevich Andrey, 13 March 2024
*/

part of '../rest_client.dart';

/// {@template rest_client.client_factory}
/// Body of the template
/// {@endtemplate}
typedef ClientFactory = Client Function();

/// {@template rest_client.config}
/// Client configuration.
/// {@endtemplate}
final class RestConfig {
  /// {@macro rest_client.config}
  const RestConfig({this.interceptors = const [], this.client = defaultClientFactory, this.headers = defaultHeaders});

  /// Default headers.
  /// Will be used every time when request invoked.
  final Map<String, String> headers;

  /// Interceptors.
  final List<IInterceptor> interceptors;

  /// Custom client factory.
  final ClientFactory client;

  /// Default client factory based [Client]
  static Client defaultClientFactory() => Client();

  /// Default client headers.
  static const defaultHeaders = {'Accept': 'application/json', 'Content-Type': 'application/json'};
}

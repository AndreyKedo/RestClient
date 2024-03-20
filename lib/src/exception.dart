/*
* exception.dart
* Default client exceptions.
* Dashkevich Andrey <dashkevich@ittest-team.ru>, 20 March 2024
*/

import 'response.dart';

/// {@template rest_client.exception.network_exception}
/// Base class for all network exceptions
/// {@endtemplate}
sealed class NetworkException implements Exception {
  /// {@macro rest_client.exception.network_exception}
  const NetworkException();
}

/// {@template rest_client.exception.rest_client_exception}
/// If something went wrong on the client side
/// {@endtemplate}
base class RestClientException implements NetworkException {
  /// {@macro rest_client.exception.rest_client_exception}
  const RestClientException({this.message});

  /// Possible reason for the exception
  final String? message;

  @override
  String toString() => 'RestClientException('
      'message: $message'
      ')';
}

/// {@template rest_client.exception.wrong_response_type_exception}
/// If the response type is not supported
/// {@endtemplate}
final class ApiErrorException extends RestClientException {
  final int statusCode;
  final String code;
  final RCResponse response;

  /// {@macro rest_client.exception.wrong_response_type_exception}
  const ApiErrorException(this.response, this.statusCode, this.code, {super.message});

  @override
  String toString() => 'ApiErrorException('
      'code: $code,'
      'message: $message,'
      'statusCode: $statusCode'
      ')';
}

/// {@template rest_client.exception.connection_exception}
/// If there is no internet connection
/// {@endtemplate}
final class ConnectionException extends RestClientException {
  final Uri? uri;

  /// {@macro rest_client.exception.connection_exception}
  const ConnectionException({super.message, this.uri});

  @override
  String toString() => 'ConnectionException('
      'message: $message,'
      'uri: $uri'
      ')';
}

/// {@template rest_client.exception.internal_server_exception}
/// If something went wrong on the server side
/// {@endtemplate}
base class InternalServerException implements NetworkException {
  /// {@macro rest_client.exception.internal_server_exception}
  const InternalServerException({
    this.message,
    this.statusCode,
  });

  /// Possible reason for the exception
  final String? message;

  /// The status code of the response (if any)
  final int? statusCode;

  @override
  String toString() => 'InternalServerErrorException('
      'message: $message,'
      'statusCode: $statusCode'
      ')';
}

/// {@template rest_client.exception.unauthorized}
/// If the user is not authorized to make the request [401]
/// {@endtemplate}
final class UnauthorizedException extends RestClientException {
  /// {@macro rest_client.exception.unauthorized}
  const UnauthorizedException({
    super.message,
  });

  @override
  String toString() => 'UnauthorizedException('
      'message: $message'
      ')';
}

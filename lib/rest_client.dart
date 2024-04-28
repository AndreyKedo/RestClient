/*
* rest_client.dart
* RestClient.
* Dashkevich Andrey, 13 March 2024
*/

/// Rest client.
///
/// A simple lightweight wrapper around [http](https://pub.dev/packages/http).
///
///
/// ```dart
/// import 'dart:developer';
/// import 'package:rest_client/rest_client.dart';
///
/// final client = RestClient(); // Create client instance
/// final response = await client.get(Uri.https('example.example', 'api/echo')); // Create request and send, await [RCResponse]
/// log(response.toString()); // Print response
/// client.close(): // Dispose, closing connection.
/// ```
///
/// Package has simple utils library.
/// See [utils]({@macro utils}).
library rest_client;

export 'package:http/http.dart';
export 'src/exception.dart';
export 'src/http_methods.dart';
export 'src/rest_client_impl.dart';

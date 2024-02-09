// ignore_for_file: depend_on_referenced_packages

library rest_client;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:synchronized/synchronized.dart';

import 'src/utils/utils.dart' show OutputBuffer, JsonParser;
import 'src/body.dart';
import 'src/exception.dart';
import 'src/response_decoder/response_decode.dart';
import 'src/jwt_utils/jwt.dart';
import 'src/response.dart';
import 'src/rest_config.dart';

//JWT Utils
export 'src/jwt_utils/jwt.dart';

//Response decoder
export 'src/response_decoder/response_decode.dart';
export 'src/rest_config.dart';

export 'src/body.dart';
export 'src/exception.dart';
export 'src/response.dart';

part 'src/internal/interceptor_mixin.dart';
part 'src/internal/request_methods_mixin.dart';
part 'src/internal/rest_client_impl.dart';

part 'src/internal/rest_methods_interface.dart';

part 'src/session/jwt_store.dart';
part 'src/session/session.dart';

///REST client
///
///Simple REST client for easy use inside app project
///
///Internal used HTTP dart library
abstract base class RestClient implements _IRestMethods {
  final RestConfig configuration;
  final Session? session;
  late final Client _client = _getClient();

  RestClient(this.configuration, {this.session});

  factory RestClient.create(RestConfig configuration, {Session? session}) =>
      _HttpClient(configuration, session: session);

  Client _getClient() => Client();

  void dispose();
}

/*
* response.dart
* Client response.
* Dashkevich Andrey, 13 March 2024
*/

import 'dart:typed_data';

import 'package:http/http.dart' show BaseResponse, Response;

final class RCResponse extends BaseResponse {
  ///Data property is map json
  ///
  ///If request body matched with {'data': Map} this field has contains map of 'data'
  ///If not matched field, has contains {'data': List|Map}
  final Map<String, Object?> data;

  final Uint8List bodyBytes;

  RCResponse.from(Response value, this.data)
      : bodyBytes = value.bodyBytes,
        super(value.statusCode,
            request: value.request,
            contentLength: value.contentLength,
            headers: value.headers,
            isRedirect: value.isRedirect,
            persistentConnection: value.persistentConnection,
            reasonPhrase: value.reasonPhrase);

  @override
  String toString() => '[${request?.method}]RCResponse '
      '${request?.url} '
      'status code: $statusCode\n'
      'headers: $headers';
}

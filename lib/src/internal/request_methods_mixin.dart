part of '../../rest_client.dart';

///Request implementation mixin
base mixin _RequestAPI on _InterceptorAPI implements _IRestMethods {
  @override
  Future<RCResponse> get(String path, {Map<String, dynamic>? queryParameters, Map<String, String>? headers}) {
    final request = Request('GET', buildUri(path: path, queryParams: queryParameters));
    return _sendRequest(request, headers: headers);
  }

  @override
  Future<RCResponse> post(String path,
      {RequestBody? body, Map<String, dynamic>? queryParameters, Map<String, String>? headers}) {
    final request = Request('POST', buildUri(path: path, queryParams: queryParameters));
    return _sendRequest(request, body: body, headers: headers);
  }

  @override
  Future<RCResponse> put(String path,
      {RequestBody? body, Map<String, dynamic>? queryParameters, Map<String, String>? headers}) {
    final request = Request('PUT', buildUri(path: path, queryParams: queryParameters));
    return _sendRequest(request, body: body, headers: headers);
  }

  @override
  Future<RCResponse> delete(String path,
      {RequestBody? body, Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    final request = Request('DELETE', buildUri(path: path, queryParams: queryParameters));
    return _sendRequest(request, body: body, headers: headers);
  }

  @override
  Future<RCResponse> patch(String path,
      {RequestBody? body, Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    final request = Request('PATCH', buildUri(path: path, queryParams: queryParameters));
    return _sendRequest(request, body: body, headers: headers);
  }

  @override
  Future<RCResponse> sendImage(String path,
      {required BytesBody bytes, Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    final request = MultipartRequest('POST', buildUri(path: path, queryParams: queryParameters));

    final file =
        MultipartFile.fromBytes('file', bytes.value, contentType: MediaType.parse('image/jpg'), filename: 'file.jpg');
    request.files.add(file);

    return _sendRequest(request, headers: headers);
  }

  @override
  Future<RCResponse> sendFile(String path,
      {required String title,
      required BytesBody bytes,
      Map<String, dynamic>? queryParameters,
      Map<String, String>? headers}) async {
    final request = MultipartRequest("POST", buildUri(path: path, queryParams: queryParameters));

    final file = MultipartFile.fromBytes('file', bytes.value, filename: title);
    request.files.add(file);

    return _sendRequest(request, headers: headers);
  }

  @override
  Stream<DownloadFile> downloadFile(String api, Map<String, dynamic> body,
      {Map<String, String>? queryParameters}) async* {
    final request = StreamedRequest('POST', buildUri(path: api, queryParams: queryParameters));

    request.headers.addAll(await _headers);
    final bodyBytes = await JsonParser().encode(body);
    final converted = utf8.encode(bodyBytes);

    request.contentLength = converted.length;
    request.sink.add(converted);
    unawaited(request.sink.close());

    try {
      final response = request.send();
      final OutputBuffer sink = OutputBuffer();
      int bytesReceived = 0;
      await for (StreamedResponse r in response.asStream()) {
        if (r case StreamedResponse(request: BaseRequest request, statusCode: int statusCode)) {
          configuration.log(ResponseLogMessage(request.method, request.url, statusCode));
        }

        int contentLength = r.contentLength ?? 0;

        await for (List<int> chunk in r.stream) {
          sink.add(chunk);
          bytesReceived += chunk.length;
          yield DownloadFile$Loading(bytesReceived, contentLength);
        }
        sink.close();
        if (r.statusCode != 200) {
          final response = Response.bytes(sink.bytes, r.statusCode);
          throw DownloadFile$Error(r.statusCode, response.body);
        }
      }
      final data = base64Encode(sink.bytes);
      yield DownloadFile$Completed(data, sink.bytes);
    } on DownloadFile$Error catch (error, stackTrace) {
      configuration.log(ErrorLogMessage(error, stackTrace));
      rethrow;
    } on Object catch (error, stackTrace) {
      configuration.log(ErrorLogMessage(error, stackTrace));
      Error.throwWithStackTrace(DownloadFile$InternalException(Error.safeToString(error)), stackTrace);
    }
  }
}

sealed class DownloadFile {
  const DownloadFile();

  T? map<T>({
    T Function(String base64, Uint8List bytes)? completed,
    T Function(int cumulative, int? total)? loading,
    T Function(int statusCode, String message)? error,
  }) {
    return switch (this) {
      DownloadFile$Completed(base64: String base64, bytes: Uint8List bytes) => completed?.call(base64, bytes),
      DownloadFile$Loading(cumulative: int cumulative, total: int? total) => loading?.call(cumulative, total),
      DownloadFile$Error(statusCode: int statusCode, message: String message) => error?.call(statusCode, message),
      _ => null
    };
  }
}

final class DownloadFile$Completed extends DownloadFile {
  final String base64;
  final Uint8List bytes;
  const DownloadFile$Completed(this.base64, this.bytes);
}

final class DownloadFile$Loading extends DownloadFile {
  final int cumulative;
  final int total;
  const DownloadFile$Loading(this.cumulative, this.total);

  double get percentage => cumulative / total * 100;
}

final class DownloadFile$Error extends DownloadFile {
  final int statusCode;
  final String message;
  const DownloadFile$Error(this.statusCode, this.message);

  @override
  String toString() => 'DownloadFile\$Error: $statusCode - $message';
}

final class DownloadFile$InternalException extends DownloadFile implements Exception {
  final String message;
  const DownloadFile$InternalException(this.message);

  @override
  String toString() => 'DownloadFile\$InternalException: $message';
}

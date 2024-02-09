part of '../../rest_client.dart';

abstract interface class _IRestMethods {
  Future<RCResponse> get(String path, {Map<String, dynamic>? queryParameters, Map<String, String>? headers});

  Future<RCResponse> post(String path,
      {RequestBody? body, Map<String, dynamic>? queryParameters, Map<String, String>? headers});

  Future<RCResponse> put(String path,
      {RequestBody? body, Map<String, dynamic>? queryParameters, Map<String, String>? headers});

  Future<RCResponse> delete(String path,
      {RequestBody? body, Map<String, dynamic>? queryParameters, Map<String, String>? headers});

  Future<RCResponse> patch(String path,
      {RequestBody? body, Map<String, dynamic>? queryParameters, Map<String, String>? headers});

  Future<RCResponse> sendImage(String path,
      {required BytesBody bytes, Map<String, dynamic>? queryParameters, Map<String, String>? headers});

  Future<RCResponse> sendFile(String path,
      {required String title,
      required BytesBody bytes,
      Map<String, dynamic>? queryParameters,
      Map<String, String>? headers});

  ///Experimental download file stream
  ///
  ///'Download' is progress
  ///base64 String is completed
  Stream<DownloadFile> downloadFile(String api, Map<String, dynamic> body,
      {Map<String, String> queryParameters = const {}});
}

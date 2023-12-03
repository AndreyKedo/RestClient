part of '../../rest_client.dart';

abstract interface class IJWTStore {
  const IJWTStore();

  Future<JWT?> read();
  FutureOr<void> write(JWT value);
  FutureOr<void> remove();
}

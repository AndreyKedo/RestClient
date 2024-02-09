part of '../../rest_client.dart';

final class Session {
  final IJWTStore jwtStore;
  final String refreshTokenPath;

  const Session({required this.jwtStore, required this.refreshTokenPath});

  FutureOr<void> setToken(String token) {
    final tokenObj = JWT.decode(token);
    return jwtStore.write(tokenObj);
  }

  FutureOr<void> removeToken() => jwtStore.remove();
}

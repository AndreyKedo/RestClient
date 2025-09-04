import 'package:http_middleware/utils.dart';
import 'package:test/test.dart';

void main() {
  test('JWT parsing', () {
    final jwt = JWT.tryDecode(
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkwMjJ9.4Adcj3UFYzPUVaVF43FmMab6RlaQD8A9V8wFzzht-KQ');
    expect(jwt, isNotNull, reason: 'Incorrect JWT parsing');

    final payload = jwt!.payload;
    expect(payload.issueAt, 1516239022, reason: 'issue time incorrect');
    expect(payload.expirationTime, 1516239022, reason: 'expiration time incorrect');
  });
}

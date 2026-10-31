import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ScheduleApi api;
  setUp(() => api = ScheduleApi(getContextCallBack: () => null));
  tearDown(() => api.dispose());

  for (final code in ['0', 0]) {
    test('success code $code (${code.runtimeType}) is never an API error', () {
      final body = {
        'Error': {'Code': code}
      };
      expect(api.isJsonResponseOk(body), isTrue);
      expect(api.isTilerRequestError(body), isFalse);
    });
  }

  for (final error in [
    null,
    [],
    'invalid',
    {},
    {'Code': null}
  ]) {
    test('malformed error envelope $error does not throw', () {
      final body = {'Error': error};
      expect(api.isJsonResponseOk(body), isFalse);
      expect(api.isTilerRequestError(body), isFalse);
    });
  }

  test('numeric API errors preserve their code and message', () {
    final body = <String, dynamic>{
      'Error': {'Code': 42, 'Message': 'Rejected'}
    };
    expect(api.getTilerResponseError(body)!.Code, '42');
    expect(api.getTilerResponseError(body)!.Message, 'Rejected');
    expect(TilerError.fromJson({'Code': 42}).Code, '42');
    expect(
        api.errorMessage({
          'Error': {'Code': 42}
        }),
        'Error: 42');
  });
}

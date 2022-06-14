import 'package:ardrive/utils/key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

void main() {
  group('KeyValueStore class', () {
    final store = KeyValueStore();

    setUp(() async {
      Map<String, Object> values = <String, Object>{'isItTrue': false};
      SharedPreferences.setMockInitialValues(values);
      final fakePrefs = await SharedPreferences.getInstance();
      await store.setup(fakePrefs);
    });

    group('putBool method', () {
      test('replaces the previous value', () async {
        var currentValue = store.getBool('isItTrue');
        expect(currentValue, false);
        await store.putBool('isItTrue', true);
        currentValue = store.getBool('isItTrue');
        expect(currentValue, true);
      });
    });

    group('remove method', () {
      test('returns true when sucessfully removed', () async {
        final success = await store.remove('isItTrue');
        expect(success, true);
      });
    });

    group('getBool method', () {
      test('retrurns false if the key is not present', () async {
        var currentValue = store.getBool('isItTrue');
        expect(currentValue, false);
      });
    });
  });
}

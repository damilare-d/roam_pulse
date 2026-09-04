import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:roam_pulse/features/auth/auth_repository.dart';
import 'package:storage/storage.dart';

void main() {
  group('HttpAuthRepository', () {
    late AuthRepository repository;
    late KeyValueStore store;

    setUp(() {
      store = InMemoryKeyValueStore();
      repository = HttpAuthRepository(
        ApiClient(config: const ApiConfig(baseUrl: 'http://unused')),
        store,
      );
    });

    test('hasActiveSession is false when nothing is stored', () async {
      expect(await repository.hasActiveSession(), isFalse);
    });

    test('hasActiveSession is true once a session token is stored', () async {
      await store.setString(
        HttpAuthRepository.sessionTokenKey,
        'demo-session-token',
      );
      expect(await repository.hasActiveSession(), isTrue);
    });

    test('signOut clears the stored session', () async {
      await store.setString(
        HttpAuthRepository.sessionTokenKey,
        'demo-session-token',
      );
      await repository.signOut();
      expect(await repository.hasActiveSession(), isFalse);
    });
  });
}

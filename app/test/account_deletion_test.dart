import 'package:bikesetupapp/features/auth/repositories/firebase_auth_repository.dart';
import 'package:bikesetupapp/common/models/command_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'support/fake_auth_repository.dart';

class DeletionUser extends SessionUser {
  bool rejectPassword = false;
  bool reauthenticated = false;

  @override
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) async {
    if (rejectPassword) throw FirebaseAuthException(code: 'wrong-password');
    reauthenticated = true;
    return SessionCredential();
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    expect(reauthenticated, isTrue);
    expect(forceRefresh, isTrue);
    return 'fresh-id-token';
  }
}

class DeletionApp extends Fake implements FirebaseApp {
  @override
  FirebaseOptions get options => const FirebaseOptions(
      apiKey: 'key',
      appId: 'app',
      messagingSenderId: 'sender',
      projectId: 'test-project');
}

class DeletionAuth extends Fake implements FirebaseAuth {
  DeletionAuth(this.user);

  User? user;

  @override
  User? get currentUser => user;
  @override
  FirebaseApp get app => DeletionApp();

  @override
  Future<void> signOut() async {
    user = null;
  }
}

void main() {
  test(
      'account deletion reauthenticates and clears session only after server success',
      () async {
    final user = DeletionUser();
    final auth = DeletionAuth(user);
    bool cleanup = false;
    final client = MockClient((request) async {
      expect(cleanup, isTrue);
      expect(request.url.path, '/deleteAccount');
      expect(request.headers['authorization'], 'Bearer fresh-id-token');
      expect(request.body, '{}');
      return http.Response('{"deleted":true}', 200);
    });
    final repo = FirebaseAuthRepository(
        auth: auth,
        client: client,
        beforeAccountDeletion: () async {
          expect(user.reauthenticated, isTrue);
          cleanup = true;
        });
    await repo.deleteAccount(password: 'password');
    expect(auth.currentUser, isNull);
    client.close();
  });
  test('failed reauthentication never calls cleanup or deletion server',
      () async {
    final user = DeletionUser()..rejectPassword = true;
    final auth = DeletionAuth(user);
    final client = MockClient((_) async => throw StateError('Must not delete'));
    final repo = FirebaseAuthRepository(
        auth: auth,
        client: client,
        beforeAccountDeletion: () async => fail('Must not disconnect'));
    await expectLater(
        repo.deleteAccount(password: 'wrong'), throwsA(isA<AppFailure>()));
    expect(auth.currentUser, same(user));
    client.close();
  });
  test('server deletion failure keeps the session for retry', () async {
    final user = DeletionUser();
    final auth = DeletionAuth(user);
    final client = MockClient((_) async => http.Response('failure', 500));
    final repo = FirebaseAuthRepository(auth: auth, client: client);
    await expectLater(
        repo.deleteAccount(password: 'password'),
        throwsA(isA<AppFailure>()
            .having((e) => e.code, 'code', FailureCode.accountDeletionFailed)));
    expect(auth.currentUser, same(user));
    client.close();
  });
}

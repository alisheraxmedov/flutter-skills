# Testing state-managed widgets

## Riverpod: override providers in a ProviderScope

Inject mocks by overriding providers at the scope wrapping the widget under test.

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      // or override a notifier/async provider with a fixed value:
      // userProvider.overrideWith((ref) => FakeUserNotifier()),
    ],
    child: const MaterialApp(home: SignInPage()),
  ),
);
```

Stub the mock's methods with `mocktail` exactly as in unit tests, then drive the widget and assert on the rendered result.

## Bloc: mock the bloc or unit-test it with bloc_test

Provide a mock bloc to the widget tree:

```dart
class MockSignInBloc extends MockBloc<SignInEvent, SignInState> implements SignInBloc {}

// widget: wrap with BlocProvider<SignInBloc>.value(value: MockSignInBloc(), child: ...)
// stub state with whenListen(...) or seed an initial state, then assert UI.
```

Unit-test the bloc's transitions directly with `bloc_test`:

```dart
blocTest<SignInBloc, SignInState>(
  'emits [loading, success] when sign-in succeeds',
  build: () => SignInBloc(mockSignIn),
  act: (b) => b.add(const SignInSubmitted('a@b.com', 'pw')),
  expect: () => [SignInLoading(), SignInSuccess(user)],
);
```

Mock the use case/repository the bloc depends on (with `mocktail`) so the test exercises only the bloc's logic.

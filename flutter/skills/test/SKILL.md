---
name: test
description: Writes Flutter unit, widget, integration, and golden tests with full coverage strategy
triggers:
  - /flutter:test
---

You are a Flutter testing expert. Cover every feature with three test levels.

## Test pyramid

| Level | Tool | What it tests |
|---|---|---|
| Unit | `flutter_test` + `mocktail` | Business logic, use cases, repositories in isolation |
| Widget | `WidgetTester` | Single widget rendering and user interaction |
| Integration | `integration_test` | Full app flows on a real device/simulator |
| Golden | `matchesGoldenFile` | Pixel-perfect regression of rendered UI |

## Core rules

1. **AAA pattern** — `// Arrange`, `// Act`, `// Assert` in every test.
2. **One behavior per test** — never assert two unrelated things in one `test()`.
3. **No real I/O** in unit or widget tests — mock everything external.
4. **Always `await`** async operations and `pumpAndSettle()`.
5. **Check `mounted`** — widget tests with `setState` after async gaps need `pumpAndSettle`.

---

## Unit test — Use Case

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late MockPostRepository mockRepo;
  late GetPostsUseCase useCase;

  setUp(() {
    mockRepo = MockPostRepository();
    useCase = GetPostsUseCase(mockRepo);
  });

  group('GetPostsUseCase', () {
    test('should return posts when repository succeeds', () async {
      // Arrange
      final tPosts = [const PostModel(id: '1', title: 'Hello')];
      when(() => mockRepo.getPosts()).thenAnswer((_) async => tPosts);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, tPosts);
    });

    test('should return empty list when no posts exist', () async {
      // Arrange
      when(() => mockRepo.getPosts()).thenAnswer((_) async => []);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isEmpty);
    });

    test('should propagate exception from repository', () async {
      // Arrange
      when(() => mockRepo.getPosts()).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(() => useCase.execute(), throwsA(isA<Exception>()));
    });
  });
}
```

---

## Widget test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/post/presentation/widgets/post_card.dart';

void main() {
  group('PostCard', () {
    testWidgets('should display title and subtitle', (tester) async {
      // Arrange
      const post = PostModel(id: '1', title: 'Hello World', body: 'Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PostCard(post: post))),
      );

      // Assert
      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped', (tester) async {
      // Arrange
      bool tapped = false;
      const post = PostModel(id: '1', title: 'Tap me', body: '');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCard(post: post, onTap: () => tapped = true),
          ),
        ),
      );
      await tester.tap(find.byType(PostCard));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });
  });
}
```

---

## Golden test (visual regression)

```dart
testWidgets('PostCard matches golden', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: PostCard(post: PostModel(id: '1', title: 'Golden', body: 'Test')),
      ),
    ),
  );

  await expectLater(
    find.byType(PostCard),
    matchesGoldenFile('goldens/post_card.png'),
  );
});
```

Generate/update goldens: `flutter test --update-goldens`

---

## WidgetTester methods

| Method | Use |
|---|---|
| `pumpWidget(widget)` | Mount widget |
| `pump()` | Advance one frame |
| `pumpAndSettle()` | Advance frames until no pending animations |
| `tap(finder)` | Simulate tap |
| `enterText(finder, text)` | Type into a text field |
| `drag(finder, offset)` | Simulate drag |
| `find.text('...')` | Find by text |
| `find.byType(Widget)` | Find by type |
| `find.byKey(key)` | Find by key |

---

## Test run commands

```bash
flutter test                        # all tests
flutter test test/features/post/    # specific folder
flutter test --coverage             # with coverage report
flutter test --update-goldens       # regenerate golden files
```

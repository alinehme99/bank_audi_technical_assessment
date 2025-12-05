// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:bank_audi_technical_assessment/features/users/presentation/providers/users_provider.dart';
import 'package:bank_audi_technical_assessment/features/users/presentation/pages/users_list_page.dart';
import 'package:bank_audi_technical_assessment/features/users/domain/repositories/users_repository.dart';

class MockUsersRepository extends Mock implements UsersRepository {}

void main() {
  late MockUsersRepository mockRepository;

  setUp(() {
    mockRepository = MockUsersRepository();
  });

  testWidgets('App should load users list page', (WidgetTester tester) async {
    // Arrange
    when(() => mockRepository.getCachedUsers()).thenAnswer((_) async => []);
    when(() => mockRepository.isCacheValid()).thenAnswer((_) async => false);
    when(() => mockRepository.getUsers(any(), any())).thenAnswer((_) async => []);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UsersProvider(mockRepository),
        child: const MaterialApp(
          home: UsersListPage(),
        ),
      ),
    );

    // Wait for the app to initialize
    await tester.pumpAndSettle();

    // Verify that the app loads with the correct title
    expect(find.text('ReqRes Users'), findsOneWidget);
    
    // Verify that the search field is present
    expect(find.byType(TextField), findsOneWidget);
  });
}

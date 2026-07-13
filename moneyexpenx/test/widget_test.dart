// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moneyexpenx/main.dart';
import 'package:moneyexpenx/data/services/local_storage_service.dart';
import 'package:moneyexpenx/viewmodels/auth_viewmodel.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';

void main() {
  setUp(() async {
    // Set up mock values for SharedPreferences before running tests.
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  testWidgets('MoneyExpenx App Smoke Test - Displays Login Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ChangeNotifierProvider(create: (_) => FinanceViewModel()),
        ],
        child: const MoneyExpenxApp(),
      ),
    );

    // Verify that our app name is displayed.
    expect(find.text('MoneyExpenx'), findsOneWidget);
    
    // Verify that the login button is present.
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthflutter/screens/login_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:healthflutter/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('未登录时显示登录页', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('登录'), findsWidgets);
    expect(find.text('记住密码'), findsOneWidget);
  });

  testWidgets('返回登录页回填密码，取消记住后删除凭据', (tester) async {
    SharedPreferences.setMockInitialValues({
      'remembered_username': 'alice',
      'remember_password': true,
    });
    FlutterSecureStorage.setMockInitialValues({
      'remembered_password': 'saved-secret',
    });
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[0].controller!.text, 'alice');
    expect(fields[1].controller!.text, 'saved-secret');
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('remember_password'), isFalse);
    expect(
      await const FlutterSecureStorage().read(key: 'remembered_password'),
      isNull,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/main.dart';
import 'package:todo_list/UI/pages/start_page1.dart';
import 'package:todo_list/UI/pages/login_page.dart';
import 'package:todo_list/UI/pages/home_page.dart';

void main() {
  testWidgets('StartPage açılış testi (ilk açılış)', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isFirstLaunch: true, isLoggedIn: false));
    expect(find.byType(StartPage), findsOneWidget);
  });

  testWidgets('LoginPage açılış testi (ilk açılış değil, login olunmamış)', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isFirstLaunch: false, isLoggedIn: false));
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('HomePage açılış testi (login olmuş)', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isFirstLaunch: false, isLoggedIn: true));
    expect(find.byType(HomePage), findsOneWidget);
  });
}
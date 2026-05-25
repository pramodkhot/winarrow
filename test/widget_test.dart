import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winarrow/app/app.dart';
import 'package:winarrow/shared/storage/local_storage.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('Home screen shows Play button', (tester) async {
    await tester.pumpWidget(const WinArrowApp());
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('Home screen shows Level 1 by default', (tester) async {
    await tester.pumpWidget(const WinArrowApp());
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
  });

  testWidgets('Bottom nav has all 4 tabs', (tester) async {
    await tester.pumpWidget(const WinArrowApp());
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Level 20'), findsOneWidget);
    expect(find.text('Level 10'), findsOneWidget);
  });

  test('LocalStorage currentLevel defaults to 1', () {
    expect(LocalStorage.currentLevel, 1);
  });

  test('LocalStorage advanceLevel increments correctly', () async {
    await LocalStorage.advanceLevel();
    expect(LocalStorage.currentLevel, 2);
  });
}

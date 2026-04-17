import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mystikesgs_dosen/core/storage/app_prefs.dart';
import 'package:mystikesgs_dosen/main.dart';

void main() {
  testWidgets('MyApp boots with required prefs dependency', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await AppPrefs.getInstance();

    await tester.pumpWidget(MyApp(prefs: prefs));
    await tester.pump();

    expect(find.text('Masuk Akun'), findsOneWidget);
  });
}

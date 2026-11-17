import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comiapp/main.dart';
import 'package:comiapp/core/constants/app_constants.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test renders title on splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ComiApp());
    expect(find.text(AppConstants.appName), findsWidgets);
    // Avanzar el temporizador de splash para completar el frame
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:comiapp/main.dart';
import 'package:comiapp/core/constants/app_constants.dart';

void main() {
  testWidgets('App smoke test renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const ComiApp());
    expect(find.text(AppConstants.appName), findsWidgets);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pu_connection/core/di/injection_container.dart';
import 'package:pu_connection/main.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initDI();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('App renders SplashPage and transitions to IntroPage', (WidgetTester tester) async {
    await tester.pumpWidget(const PUConnectionApp());

    // Verify PU Connection text is present on SplashPage
    expect(find.text('PU Connection'), findsOneWidget);

    // Fast-forward past splash delay (2500ms)
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    // Verify Intro page is displayed
    expect(find.text('Kết nối sinh viên Phenikaa'), findsOneWidget);
  });
}

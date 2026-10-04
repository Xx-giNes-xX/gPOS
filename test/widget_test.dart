import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpos/src/core/storage/local_storage_service.dart';
import 'package:gpos/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  testWidgets('GPosApp smoke test - verifies app launches and renders POS terminal', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GPosApp()));
    await tester.pumpAndSettle();

    // Verify app brand and title are rendered
    expect(find.text('gPOS'), findsOneWidget);
    expect(find.text('Terminal de Ventas'), findsOneWidget);
  });
}

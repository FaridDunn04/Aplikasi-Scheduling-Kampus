import 'package:flutter_test/flutter_test.dart';
import 'package:scheadule_app/main.dart';

void main() {
  testWidgets('UniSched smoke test - renders 3 navigation tabs', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const UniSchedApp());

    // Pastikan 3 tab navigasi muncul di layar
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Jadwal'), findsWidgets);
    expect(find.text('Tugas'), findsWidgets);
  });
}

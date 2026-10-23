import 'package:flutter_test/flutter_test.dart';
import 'package:libtrack/main.dart';

void main() {
  testWidgets('LibTrack app starts and displays its title', (WidgetTester tester) async {
    await tester.pumpWidget(const LibTrackApp());
    await tester.pumpAndSettle();

    expect(find.text('LibTrack'), findsWidgets);
  });
}

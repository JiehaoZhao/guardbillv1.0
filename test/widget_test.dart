import 'package:flutter_test/flutter_test.dart';
import 'package:guard_bill/main.dart';

void main() {
  testWidgets('GuardBill app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GuardBillApp());
    expect(find.text('🛡️ GuardBill'), findsOneWidget);
  });
}
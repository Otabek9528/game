import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/startup_failed.dart';

void main() {
  testWidgets('a failed start says so, with the error, instead of a frozen splash', (tester) async {
    await tester.pumpWidget(StartupFailed(error: StateError('storage unavailable')));
    expect(find.textContaining('Ilova ochilmadi'), findsOneWidget);
    expect(find.text('Bad state: storage unavailable'), findsOneWidget);
  });
}

import 'package:aerofit/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App shows login screen when user is not signed in', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AeroFitApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('AeroFit'), findsOneWidget);
  });
}

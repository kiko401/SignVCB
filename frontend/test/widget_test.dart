import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moyu_app/main.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoyuApp()));
    expect(find.text('听见你的声音，看见你的世界'), findsOneWidget);
  });
}

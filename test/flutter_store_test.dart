import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atomic_state/atomic_state.dart';
import 'package:flutter_atomic_state/flutter_atomic_state.dart';

import 'fixtures/counter.dart';

void main() {
  testWidgets('flutter widgets', (WidgetTester tester) async {
    final store = Store([Counter()]);

    await tester.pumpWidget(StoreProvider(
        store: store,
        child: StoreConnector<Store>(
          builder: (context, store) => Text(
              store.getState<Counter>().count.toString(),
              key: Key('count'),
              textDirection: TextDirection.ltr),
        )));

    store.updateState<Counter>((counter) => counter.inc());

    await tester.pump();

    final text = tester.firstWidget<Text>(find.byKey(Key('count')));

    expect(int.parse(text.data), greaterThan(0));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store/store.dart';
import 'package:flutter_store/flutter_store.dart';

import 'fixtures/counter.dart';

void main() {
  testWidgets('flutter widgets', (WidgetTester tester) async {
    final store = Store([Counter()]);

    await tester.pumpWidget(StoreProvider(
        store: store,
        child: StoreConnector<Counter>(
          builder: (context, counter) => Text(
              counter.count.toString(),
              key: Key('count'),
              textDirection: TextDirection.ltr),
          converter: (state) => state.getState<Counter>(),
        )));

    store.updateState<Counter>((counter) => counter.inc());

    await tester.pump();

    final text = tester.firstWidget<Text>(find.byKey(Key('count')));

    expect(int.parse(text.data), greaterThan(0));
  });
}

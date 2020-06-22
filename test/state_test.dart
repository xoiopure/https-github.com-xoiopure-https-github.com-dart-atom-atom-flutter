import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state/state.dart';

void main() {
  test('state', () {
    final store = new Store(),
        counter = store.getView("test.path[0].counter", {"count": 0});

    final incCount = () => counter.updateState(
        (state) => updateIn(state, "count", getIn(state, "count") + 1));

    incCount();
    expect(store.getState("test.path[0].counter")["count"], equals(1));
    expect(jsonEncode(counter.state), equals('{"count":1}'));

    incCount();
    expect(jsonEncode(store.state),
        equals('{"counter":[{"path":{"test":{"count":2}}}]}'));
  });

  testWidgets('StoreProvider/StoreConnector', (WidgetTester tester) async {
    final store = new Store(), counter = store.getView("counter", {"count": 0});

    final incCount = () => counter.updateState(
        (state) => updateIn(state, "count", getIn(state, "count") + 1));

    await tester.pumpWidget(StoreProvider(
        store: store,
        child: StoreConnector(
          builder: (context, viewModel) => Text(viewModel["count"].toString(),
              key: Key("count"), textDirection: TextDirection.ltr),
          converter: (state) => state["counter"],
        )));

    incCount();

    await tester.pump();

    final text = tester.firstWidget<Text>(find.byKey(Key("count")));

    expect(text.data, "1");
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atomic_state/atomic_state.dart';
import 'package:flutter_atomic_state/flutter_atomic_state.dart';

class Counter {
  final int count;

  Counter({this.count = 0});
  factory Counter.from(Counter counter, {int count}) =>
      Counter(count: count ?? counter.count);

  Counter inc([int value = 1]) => Counter.from(this, count: count + value);

  Map<String, dynamic> toJson() => {'count': count};
}

void main() {
  testWidgets('flutter widgets', (WidgetTester tester) async {
    final store = Store([Counter()]);

    await tester.pumpWidget(StoreProvider(
        store: store,
        child: StoreConnector<Counter>(
            builder: (context, store, counter) => GestureDetector(
                onTap: () =>
                    store.updateState<Counter>((counter) => counter.inc()),
                child: Text('${counter.count}',
                    key: Key('count'), textDirection: TextDirection.ltr)),
            converter: (store) => store.getState())));

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    final text = tester.firstWidget<Text>(find.byKey(Key('count')));

    expect(int.parse(text.data), equals(1));
  });
}

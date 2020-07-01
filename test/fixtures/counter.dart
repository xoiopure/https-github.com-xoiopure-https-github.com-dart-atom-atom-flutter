import 'package:store/store.dart';

class Counter extends StoreState {
  static String name = 'counter';
  final int count;

  Counter({
    this.count = 0
  });
  Counter inc([int value = 1]) => Counter(count: count + value);
  Counter dec([int value = 1]) => Counter(count: count - value);

  @override
  Map<String, dynamic> toJson() => {
    'count': count
  };
}
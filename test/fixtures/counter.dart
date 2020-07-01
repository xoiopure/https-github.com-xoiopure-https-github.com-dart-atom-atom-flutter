class Counter {
  final int count;

  Counter({this.count = 0});
  factory Counter.from(Counter counter, {int count}) =>
      Counter(count: count ?? counter.count);

  Counter inc([int value = 1]) => Counter.from(this, count: count + value);

  Map<String, dynamic> toJson() => {'count': count};
}

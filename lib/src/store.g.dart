part of 'store.dart';

StoreView _$StoreViewFromJson(Map<String, dynamic> json) {
  return StoreView(
    json['store'],
    json['path']
  );
}

Map<String, dynamic> _$StoreViewToJson(StoreView storeView) => <String, dynamic>{
  'store': storeView._store,
  'path' : storeView._path,
};


Store _$StoreFromJson(Map<String, dynamic> json) {
  return Store(initialState: json);
}

Map<String, dynamic> _$StoreToJson(Store store) => <String, dynamic>{
  'state': store.state,
  'sync' : store._sync,
};
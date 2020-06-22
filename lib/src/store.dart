import 'dart:async';

final pathRegex = new RegExp(r"[^\.\[\]]+");

class StoreView {
  final Store _store;
  final String _path;
  final List<dynamic> _pathParts;

  StoreView(Store store, String path)
      : _store = store,
        _path = path,
        _pathParts = _pathToParts(path);

  StoreView getView(String path, Map<String, dynamic> initialState) =>
      _store.getView(_path + path, initialState);

  Map<String, dynamic> get state => _store._getState(_pathParts);

  StoreView setState(Map<String, dynamic> newState) {
    _store._setState(_pathParts, newState);
    return this;
  }

  StoreView updateState(Map<String, dynamic> Function(Map<String, dynamic>) updateFn) {
    _store._updateState(_pathParts, updateFn);
    return this;
  }
}

class Store {
  Map<String, dynamic> _state = Map.identity();
  final StreamController<Map<String, dynamic>> _changeController;

  Store({
    Map<String, dynamic> initialState,
    bool syncStream = true,
  }) : _changeController = StreamController.broadcast(sync: syncStream) {
    if (initialState != null) {
      _state = initialState;
    }
  }

  Map<String, dynamic> get state => _state;

  StoreView getView<V>(String path, [Map<String, dynamic> initialState]) {
    final store = new StoreView(this, path);
    store.setState(initialState);
    return store;
  }

  T _getState<T>(List<dynamic> pathParts) => _getIn(_state, [...pathParts]);

  T getState<T>(String path) => _getIn(_state, _pathToParts(path));

  Store forceEmit() {
    _changeController.add(_state);
    return this;
  }

  Store _unsafeSetState<T>(List<dynamic> pathParts, T value) {
    _state = _updateIn(_copyCollection(_state), [...pathParts], value);
    return this;
  }

  Store unsafeSetState<T>(String path, T value) {
    _state = _updateIn(_copyCollection(_state), _pathToParts(path), value);
    return this;
  }

  Store _setState<T>(List<dynamic> pathParts, T value) =>
      _unsafeSetState(pathParts, value).forceEmit();

  Store setState<T>(String path, T value) =>
      unsafeSetState(path, value).forceEmit();

  Store _updateState<T>(List<dynamic> pathParts, T Function(T) updateFn) =>
      _setState(pathParts, updateFn(_getState(pathParts)));

  Store updateState<T>(String path, T Function(T) updateFn) {
    final pathParts = _pathToParts(path);
    return _updateState(pathParts, updateFn);
  }

  Stream<Map<String, dynamic>> get onChange => _changeController.stream;

  Future teardown() async {
    _state = null;
    return _changeController.close();
  }
}

List<dynamic> _pathToParts(String stringPath) => pathRegex
        .allMatches(stringPath)
        .map((regExpMatch) => regExpMatch.groups([0])[0])
        .map((value) {
      final intValue = int.tryParse(value);

      if (intValue != null) {
        return intValue;
      } else {
        return value;
      }
    }).toList();

T getIn<C, T>(C collection, String path, [T defaultValue]) {
  return _getIn(collection, _pathToParts(path), defaultValue);
}

dynamic _getIn(dynamic collection, List<dynamic> pathParts,
    [dynamic defaultValue]) {
  if (collection == null) {
    return defaultValue;
  } else if (pathParts.length == 0) {
    return collection;
  } else {
    final key = pathParts.removeLast(), subCollection = collection[key];
    return _getIn(subCollection, pathParts, defaultValue);
  }
}

C updateIn<C, V>(C collection, String path, V value) {
  return _updateIn(_copyCollection(collection), _pathToParts(path), value);
}

dynamic _updateIn(dynamic collection, List<dynamic> pathParts, dynamic value) {
  if (pathParts.length == 0) {
    return value;
  } else {
    final key = pathParts.removeLast(), isList = key is int;

    if (collection == null) {
      if (isList) {
        collection = new List();
      } else {
        collection = new Map<String, dynamic>();
      }
    }
    if (isList) {
      int index = key as int;
      List collectionAsList = collection as List;

      if (index >= collectionAsList.length) {
        collectionAsList.length = index + 1;
      }
    }

    collection[key] =
        _updateIn(_copyCollection(collection[key]), pathParts, value);

    return collection;
  }
}

dynamic _copyCollection(dynamic collection) {
  if (collection is Map) {
    Map<String, dynamic> map = collection as Map<String, dynamic>;
    return {...map};
  } else if (collection is List) {
    List<dynamic> list = collection;
    return [...list];
  } else {
    return collection;
  }
}

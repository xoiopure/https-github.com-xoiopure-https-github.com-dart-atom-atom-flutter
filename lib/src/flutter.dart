import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import './store.dart';

class StoreProvider extends InheritedWidget {
  final Store _store;

  const StoreProvider({
    Key key,
    @required Store store,
    @required Widget child,
  })  : assert(store != null),
        assert(child != null),
        _store = store,
        super(key: key, child: child);

  static Store getFromContext(BuildContext context, {bool listen = true}) {
    final provider = (listen
        ? context.dependOnInheritedWidgetOfExactType<StoreProvider>()
        : context
            .getElementForInheritedWidgetOfExactType<StoreProvider>()
            ?.widget) as StoreProvider;

    if (provider == null) {
      final type = _typeOf<StoreProvider>();
      throw new StoreProviderError(type);
    }

    return provider._store;
  }

  static Type _typeOf<T>() => T;

  @override
  bool updateShouldNotify(StoreProvider oldWidget) =>
      _store.state != oldWidget._store.state;
}

typedef ViewModelBuilder<ViewModel> = Widget Function(
  BuildContext context,
  ViewModel vm,
);
typedef StoreConverter<ViewModel> = ViewModel Function(
  Map<String, dynamic> state,
);
typedef OnInitCallback = void Function(
  Map<String, dynamic> state,
);
typedef OnDisposeCallback = void Function(
  Map<String, dynamic> state,
);
typedef IgnoreChangeTest = bool Function(Map<String, dynamic> state);
typedef OnWillChangeCallback<ViewModel> = void Function(
  ViewModel previousViewModel,
  ViewModel newViewModel,
);
typedef OnDidChangeCallback<ViewModel> = void Function(ViewModel viewModel);
typedef OnInitialBuildCallback<ViewModel> = void Function(ViewModel viewModel);

class StoreConnector<ViewModel> extends StatelessWidget {
  final ViewModelBuilder<ViewModel> builder;
  final StoreConverter<ViewModel> converter;
  final bool distinct;
  final OnInitCallback onInit;
  final OnDisposeCallback onDispose;
  final bool rebuildOnChange;
  final IgnoreChangeTest ignoreChange;
  final OnWillChangeCallback<ViewModel> onWillChange;
  final OnDidChangeCallback<ViewModel> onDidChange;
  final OnInitialBuildCallback<ViewModel> onInitialBuild;

  const StoreConnector({
    Key key,
    @required this.builder,
    @required this.converter,
    this.distinct = false,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.ignoreChange,
    this.onWillChange,
    this.onDidChange,
    this.onInitialBuild,
  })  : assert(builder != null),
        assert(converter != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return _StoreStreamListener<ViewModel>(
      store: StoreProvider.getFromContext(context),
      builder: builder,
      converter: converter,
      distinct: distinct,
      onInit: onInit,
      onDispose: onDispose,
      rebuildOnChange: rebuildOnChange,
      ignoreChange: ignoreChange,
      onWillChange: onWillChange,
      onDidChange: onDidChange,
      onInitialBuild: onInitialBuild,
    );
  }
}

class _StoreStreamListener<ViewModel> extends StatefulWidget {
  final ViewModelBuilder<ViewModel> builder;
  final StoreConverter<ViewModel> converter;
  final Store store;
  final bool rebuildOnChange;
  final bool distinct;
  final OnInitCallback onInit;
  final OnDisposeCallback onDispose;
  final IgnoreChangeTest ignoreChange;
  final OnWillChangeCallback<ViewModel> onWillChange;
  final OnDidChangeCallback<ViewModel> onDidChange;
  final OnInitialBuildCallback<ViewModel> onInitialBuild;

  const _StoreStreamListener({
    Key key,
    @required this.builder,
    @required this.store,
    @required this.converter,
    this.distinct = false,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.ignoreChange,
    this.onWillChange,
    this.onDidChange,
    this.onInitialBuild,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _StoreStreamListenerStore<ViewModel>();
  }
}

class _StoreStreamListenerStore<ViewModel>
    extends State<_StoreStreamListener<ViewModel>> {
  Stream<ViewModel> stream;
  ViewModel latestValue;

  @override
  void initState() {
    if (widget.onInit != null) {
      widget.onInit(widget.store.state);
    }

    if (widget.onInitialBuild != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onInitialBuild(latestValue);
      });
    }

    latestValue = widget.converter(widget.store.state);
    _createStream();

    super.initState();
  }

  @override
  void dispose() {
    if (widget.onDispose != null) {
      widget.onDispose(widget.store.state);
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(_StoreStreamListener<ViewModel> oldWidget) {
    latestValue = widget.converter(widget.store.state);

    if (widget.store != oldWidget.store) {
      _createStream();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.rebuildOnChange
        ? StreamBuilder<ViewModel>(
            stream: stream,
            builder: (context, snapshot) => widget.builder(
              context,
              latestValue,
            ),
          )
        : widget.builder(context, latestValue);
  }

  ViewModel _mapConverter(Map<String, dynamic> state) {
    return widget.converter(state);
  }

  bool _whereDistinct(ViewModel vm) {
    if (widget.distinct) {
      return vm != latestValue;
    }

    return true;
  }

  bool _ignoreChange(Map<String, dynamic> state) {
    if (widget.ignoreChange != null) {
      return !widget.ignoreChange(state);
    }

    return true;
  }

  void _createStream() {
    stream = widget.store.onChange
        .where(_ignoreChange)
        .map(_mapConverter)
        .where(_whereDistinct)
        .transform(StreamTransformer.fromHandlers(handleData: _handleChange));
  }

  void _handleChange(ViewModel vm, EventSink<ViewModel> sink) {
    if (widget.onWillChange != null) {
      widget.onWillChange(latestValue, vm);
    }

    latestValue = vm;

    if (widget.onDidChange != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDidChange(latestValue);
      });
    }

    sink.add(vm);
  }
}

class StoreProviderError extends Error {
  Type type;

  StoreProviderError(this.type);

  @override
  String toString() {
    return '''Error: No $type found. To fix, please try:
          
  * Wrapping your App with the StoreProvider<State>, 
  rather than an individual Route
  * Providing full type information to your Store<State>, 
  StoreProvider<State> and StoreConsumer<State, ViewModel>
  * Ensure you are using consistent and complete imports. 
  E.g. always use `import 'package:my_app/app_store.dart';
      ''';
  }
}
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:atomic_state/atomic_state.dart';

class StoreProvider extends InheritedWidget {
  final Store _store;

  /// Creates a new [StoreProvider] [store] and [child] are required
  const StoreProvider({
    Key key,
    @required Store store,
    @required Widget child,
  })  : assert(store != null),
        assert(child != null),
        _store = store,
        super(key: key, child: child);

  /// Gets the current [Store] from the build [context]
  static Store getStore(BuildContext context, {bool listen = true}) {
    final provider = (listen
        ? context.dependOnInheritedWidgetOfExactType<StoreProvider>()
        : context
            .getElementForInheritedWidgetOfExactType<StoreProvider>()
            ?.widget) as StoreProvider;

    if (provider == null) {
      throw StoreProviderError(StoreProvider);
    }

    return provider._store;
  }

  @override
  bool updateShouldNotify(StoreProvider oldWidget) =>
      _store.current != oldWidget._store.current;
}

typedef ViewModelBuilder<ViewModel> = Widget Function(
    BuildContext context, Store store, ViewModel viewModel);
typedef StoreConverter<ViewModel> = ViewModel Function(
  Store store,
);
typedef OnInitCallback = void Function(
  Store store,
);
typedef OnDisposeCallback = void Function(
  Store store,
);
typedef IgnoreChangeTest = bool Function(Store store);
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
    @required this.converter,
    @required this.builder,
    this.distinct = false,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.ignoreChange,
    this.onWillChange,
    this.onDidChange,
    this.onInitialBuild,
  })  : assert(converter != null),
        assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return _StoreStreamListener<ViewModel>(
      store: StoreProvider.getStore(context),
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
    return _StoreStreamListenerState<ViewModel>();
  }
}

class _StoreStreamListenerState<ViewModel>
    extends State<_StoreStreamListener<ViewModel>> {
  Stream<ViewModel> stream;
  ViewModel latestValue;

  @override
  void initState() {
    if (widget.onInit != null) {
      widget.onInit(widget.store);
    }

    if (widget.onInitialBuild != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onInitialBuild(latestValue);
      });
    }

    latestValue = widget.converter(widget.store);
    _createStream();

    super.initState();
  }

  @override
  void dispose() {
    if (widget.onDispose != null) {
      widget.onDispose(widget.store);
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(_StoreStreamListener<ViewModel> oldWidget) {
    latestValue = widget.converter(widget.store);

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
              widget.store,
              latestValue,
            ),
          )
        : widget.builder(context, widget.store, latestValue);
  }

  ViewModel _mapConverter(Store store) {
    return widget.converter(store);
  }

  bool _whereDistinct(ViewModel vm) {
    if (widget.distinct) {
      return vm != latestValue;
    }

    return true;
  }

  bool _ignoreChange(Store store) {
    if (widget.ignoreChange != null) {
      return !widget.ignoreChange(store);
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
  * Providing full type information to your State<State>, 
  StoreProvider<State> and StateConsumer<State, ViewModel>
  * Ensure you are using consistent and complete imports. 
  E.g. always use `import 'package:my_app/app_state.dart';
      ''';
  }
}

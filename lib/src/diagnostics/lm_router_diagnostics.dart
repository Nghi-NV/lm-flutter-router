import 'lm_navigation_event.dart';

typedef LmNavigationEventListener = void Function(LmNavigationEvent event);

final class LmRouterDiagnostics {
  LmRouterDiagnostics({this.maxEvents = 200});

  final int maxEvents;
  final List<LmNavigationEvent> _events = [];
  final List<LmNavigationEventListener> _listeners = [];

  List<LmNavigationEvent> get events => List.unmodifiable(_events);

  void addListener(LmNavigationEventListener listener) {
    _listeners.add(listener);
  }

  void removeListener(LmNavigationEventListener listener) {
    _listeners.remove(listener);
  }

  void emit(LmNavigationEvent event) {
    if (maxEvents > 0 && _events.length >= maxEvents) {
      _events.removeRange(0, _events.length - maxEvents + 1);
    }
    _events.add(event);
    for (final listener in List<LmNavigationEventListener>.of(_listeners)) {
      listener(event);
    }
  }
}

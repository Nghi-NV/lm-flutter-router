import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';

@JS('lmRouterSmokeGo')
external set _lmRouterSmokeGo(JSFunction value);

@JS('lmRouterSmokePresent')
external set _lmRouterSmokePresent(JSFunction value);

@JS('lmRouterSmokePop')
external set _lmRouterSmokePop(JSFunction value);

@JS('lmRouterSmokeState')
external set _lmRouterSmokeState(JSFunction value);

@JS('window.addEventListener')
external void _addEventListener(String type, JSFunction listener);

bool _historyListenersInstalled = false;

void installWebSmokeBridge(BuildContext _, LmRouter router) {
  const enabled = bool.fromEnvironment('LM_ROUTER_WEB_SMOKE');
  if (!enabled) {
    return;
  }
  final handle = LmRouterHandle(router);
  _lmRouterSmokeGo = ((String location) {
    handle.go(location);
  }).toJS;
  _lmRouterSmokePresent = ((String location) {
    handle.present(location);
  }).toJS;
  _lmRouterSmokePop = (() {
    handle.pop();
  }).toJS;
  _lmRouterSmokeState = (() {
    final current = router.delegate.currentConfiguration?.canonical ?? '<null>';
    final provider = router.routeInformationProvider.value.uri.toString();
    return 'current=$current provider=$provider';
  }).toJS;
  if (_historyListenersInstalled) {
    return;
  }
  _historyListenersInstalled = true;
  void syncBrowserLocation(JSAny? _) {
    router.go(router.parser.parseUri(Uri.base));
  }

  _addEventListener('popstate', syncBrowserLocation.toJS);
  _addEventListener('hashchange', syncBrowserLocation.toJS);
}

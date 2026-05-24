import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/lm_location.dart';
import '../router/lm_link_normalizer.dart';
import '../router/lm_router_scope.dart';
import 'lm_cupertino_sheet_content_page.dart';
import 'lm_cupertino_sheet_deep_link.dart';

typedef LmCupertinoSheetNestedPageBuilder =
    Widget Function(
      BuildContext context,
      LmCupertinoSheetNavigation navigation,
    );

typedef LmCupertinoSheetLocationChanged = FutureOr<void> Function(String path);

final class LmCupertinoSheetNestedPage {
  const LmCupertinoSheetNestedPage({
    required this.id,
    required this.path,
    required this.builder,
  });

  final String id;
  final String path;
  final LmCupertinoSheetNestedPageBuilder builder;
}

final class LmCupertinoSheetNestedConfig implements LmLinkTransformer {
  LmCupertinoSheetNestedConfig({
    required this.sheetPath,
    required this.rootPage,
    required List<LmCupertinoSheetNestedPage> pages,
    this.queryKey = 'sheetPage',
  }) : pages = List.unmodifiable(pages),
       _links = LmCupertinoSheetDeepLinks([
         for (final page in pages)
           LmCupertinoSheetDeepLink(
             sheetPath: sheetPath,
             nestedPath: page.path,
             nestedPage: page.id,
             queryKey: queryKey,
           ),
       ]);

  final String sheetPath;
  final LmCupertinoSheetNestedPage rootPage;
  final List<LmCupertinoSheetNestedPage> pages;
  final String queryKey;
  final LmCupertinoSheetDeepLinks _links;

  @override
  LmLocation? normalize(Uri uri) => _links.normalize(uri);

  @override
  Uri? restore(LmLocation location) => _links.restore(location);

  LmCupertinoSheetNestedPage? selectedPage(LmLocation location) {
    final selectedId = location.query[queryKey];
    return pageFor(selectedId);
  }

  LmCupertinoSheetNestedPage? pageFor(String? selectedId) {
    if (selectedId == null) {
      return null;
    }
    for (final page in pages) {
      if (page.id == selectedId) {
        return page;
      }
    }
    return null;
  }

  String pathFor(String pageId) {
    if (rootPage.id == pageId) {
      return sheetPath;
    }
    for (final page in pages) {
      if (page.id == pageId) {
        return Uri(
          path: sheetPath,
          queryParameters: {queryKey: page.id},
        ).toString();
      }
    }
    throw ArgumentError.value(pageId, 'pageId', 'Unknown sheet page id.');
  }
}

final class LmCupertinoSheetNavigation {
  const LmCupertinoSheetNavigation({
    required this.push,
    required this.popToRoot,
    required this.dismiss,
  });

  final void Function(String pageId) push;
  final VoidCallback popToRoot;
  final VoidCallback dismiss;
}

final class LmCupertinoSheetNestedNavigator extends StatefulWidget {
  const LmCupertinoSheetNestedNavigator({
    required this.config,
    required this.location,
    required this.onLocationChanged,
    required this.onDismiss,
    super.key,
  });

  final LmCupertinoSheetNestedConfig config;
  final LmLocation location;
  final LmCupertinoSheetLocationChanged onLocationChanged;
  final VoidCallback onDismiss;

  @override
  State<LmCupertinoSheetNestedNavigator> createState() =>
      _LmCupertinoSheetNestedNavigatorState();
}

final class _LmCupertinoSheetNestedNavigatorState
    extends State<LmCupertinoSheetNestedNavigator> {
  String? _selectedPageId;

  @override
  void initState() {
    super.initState();
    _selectedPageId = widget.config.selectedPage(widget.location)?.id;
  }

  @override
  void didUpdateWidget(LmCupertinoSheetNestedNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPageId = widget.config.selectedPage(widget.location)?.id;
    if (nextPageId != _selectedPageId) {
      _selectedPageId = nextPageId;
    }
  }

  void _push(String pageId) {
    setState(() => _selectedPageId = pageId);
    widget.onLocationChanged(widget.config.pathFor(pageId));
  }

  void _popToRoot() {
    setState(() => _selectedPageId = null);
    widget.onLocationChanged(widget.config.sheetPath);
  }

  @override
  Widget build(BuildContext context) {
    final selectedPage = widget.config.pageFor(_selectedPageId);
    final navigation = LmCupertinoSheetNavigation(
      push: _push,
      popToRoot: _popToRoot,
      dismiss: widget.onDismiss,
    );
    return Navigator(
      pages: [
        LmCupertinoSheetContentPage<void>(
          key: ValueKey('sheet-${widget.config.rootPage.id}'),
          child: widget.config.rootPage.builder(context, navigation),
        ),
        if (selectedPage != null)
          LmCupertinoSheetContentPage<void>(
            key: ValueKey('sheet-${selectedPage.id}'),
            child: selectedPage.builder(context, navigation),
          ),
      ],
      onDidRemovePage: (page) {
        if (page.key != ValueKey('sheet-${widget.config.rootPage.id}')) {
          navigation.popToRoot();
        }
      },
    );
  }
}

final class LmCupertinoSheetNavigator extends StatelessWidget {
  LmCupertinoSheetNavigator({
    required String sheetPath,
    required LmCupertinoSheetNestedPage rootPage,
    required List<LmCupertinoSheetNestedPage> pages,
    required this.location,
    required this.onLocationChanged,
    required this.onDismiss,
    String queryKey = 'sheetPage',
    super.key,
  }) : config = LmCupertinoSheetNestedConfig(
         sheetPath: sheetPath,
         rootPage: rootPage,
         pages: pages,
         queryKey: queryKey,
       );

  const LmCupertinoSheetNavigator.config({
    required this.config,
    required this.location,
    required this.onLocationChanged,
    required this.onDismiss,
    super.key,
  });

  const LmCupertinoSheetNavigator.bound({
    required this.config,
    this.location,
    this.onLocationChanged,
    this.onDismiss,
    super.key,
  });

  final LmCupertinoSheetNestedConfig config;
  final LmLocation? location;
  final LmCupertinoSheetLocationChanged? onLocationChanged;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final explicitLocation = location;
    final explicitLocationChanged = onLocationChanged;
    final explicitDismiss = onDismiss;
    if (explicitLocation != null &&
        explicitLocationChanged != null &&
        explicitDismiss != null) {
      return LmCupertinoSheetNestedNavigator(
        config: config,
        location: explicitLocation,
        onLocationChanged: explicitLocationChanged,
        onDismiss: explicitDismiss,
      );
    }
    final handle = context.lm;
    return AnimatedBuilder(
      animation: handle.router.delegate,
      builder: (context, _) {
        return LmCupertinoSheetNestedNavigator(
          config: config,
          location: explicitLocation ?? handle.router.controller.state.location,
          onLocationChanged: explicitLocationChanged ?? handle.go,
          onDismiss: explicitDismiss ?? () => unawaited(handle.pop()),
        );
      },
    );
  }
}

final class LmCupertinoSheetBoundNavigator extends StatelessWidget {
  const LmCupertinoSheetBoundNavigator({
    required this.config,
    this.onDismiss,
    super.key,
  });

  final LmCupertinoSheetNestedConfig config;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return LmCupertinoSheetNestedNavigator(
      config: config,
      location: context.lm.router.controller.state.location,
      onLocationChanged: context.lm.go,
      onDismiss: onDismiss ?? () => unawaited(context.lm.pop()),
    );
  }
}

typedef LmCupertinoSheetPage = LmCupertinoSheetNestedPage;

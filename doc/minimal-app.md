# Minimal App

This is the shortest complete setup for an app-owned router.

```dart
import 'package:flutter/material.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';

void main() {
  final router = Lm.router(
    routes: [
      Lm.page<void>(
        path: '/',
        transition: const LmTransition.none(),
        build: (context, _) => const HomeScreen(),
      ),
      Lm.page<int>(
        path: '/orders/:orderId',
        decode: (params) => Lm.params(params).requiredInt('orderId'),
        buildPath: (orderId) => '/orders/$orderId',
        build: (context, orderId) => OrderScreen(orderId: orderId!),
      ),
    ],
    modalRoutes: [
      Lm.actionSheet<int>(
        path: '/orders/:orderId/actions',
        decode: (params) => Lm.params(params).requiredInt('orderId'),
        buildPath: (orderId) => '/orders/$orderId/actions',
        build: (context, orderId) => OrderActionsSheet(orderId: orderId!),
      ),
    ],
  );

  runApp(FieldApp(router: router));
}

final class FieldApp extends StatelessWidget {
  const FieldApp({required this.router, super.key});

  final LmRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router.config,
      builder: router.scopeBuilder(autoDispose: false),
    );
  }
}

final class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.lm.pushPath('/orders/1042'),
          child: const Text('Open order'),
        ),
      ),
    );
  }
}

final class OrderScreen extends StatelessWidget {
  const OrderScreen({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order $orderId')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.lm.presentPath('/orders/$orderId/actions'),
          child: const Text('Actions'),
        ),
      ),
    );
  }
}

final class OrderActionsSheet extends StatelessWidget {
  const OrderActionsSheet({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text('Order $orderId actions')),
          FilledButton(
            onPressed: context.lm.pop,
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}
```

Use `scopeBuilder(autoDispose: false)` when the router is stored outside the
`MaterialApp` subtree. Use `scopedBuilder()` only when that subtree creates and
owns the router instance.

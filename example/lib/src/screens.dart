import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lm_flutter_router/lm_flutter_router.dart';

import 'domain.dart';
import 'field_orders_app.dart';

final class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.repository, super.key});

  final OrdersRepository repository;

  @override
  Widget build(BuildContext context) {
    final exceptionCount = repository.orders
        .where((order) => order.status == 'Exception')
        .length;
    return ListView(
      padding: _screenPadding(context),
      children: [
        const _ScreenTopBar(title: 'Field Orders'),
        const SizedBox(height: 24),
        _Header(
          title: 'Today',
          subtitle: '${repository.orders.length} field orders scheduled',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Ready',
                value: '${repository.orders.length - exceptionCount}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(label: 'Exceptions', value: '$exceptionCount'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Priority Orders', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final order in repository.orders.take(2)) OrderTile(order: order),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Implementation Reference'),
            subtitle: const Text(
              'Copyable setup, routes, guards, sheets, and deep links',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => unawaited(context.lm.push('/lab/reference')),
          ),
        ),
      ],
    );
  }
}

final class OrdersScreen extends StatelessWidget {
  const OrdersScreen({required this.repository, super.key});

  final OrdersRepository repository;

  @override
  Widget build(BuildContext context) {
    return OrdersListPane(repository: repository);
  }
}

final class OrdersListPane extends StatelessWidget {
  const OrdersListPane({required this.repository, super.key});

  final OrdersRepository repository;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _screenPadding(context),
      children: [
        const _ScreenTopBar(title: 'Orders'),
        const SizedBox(height: 24),
        const _Header(
          title: 'Orders',
          subtitle: 'Dispatch queue and fulfillment exceptions',
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search customer or order',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        for (final order in repository.orders) OrderTile(order: order),
      ],
    );
  }
}

final class OrderTile extends StatelessWidget {
  const OrderTile({required this.order, super.key});

  final FieldOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${order.id}'.substring(2))),
        title: Text('${order.customer} #${order.id}'),
        subtitle: Text('${order.window} • ${order.status}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            unawaited(_navigateForLayout(context, orderPath(order.id))),
      ),
    );
  }
}

final class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    required this.repository,
    required this.orderId,
    super.key,
  });

  final OrdersRepository repository;
  final int orderId;

  @override
  Widget build(BuildContext context) {
    final order = repository.findOrder(orderId);
    if (order == null) {
      return NotFoundScreen(title: 'Order #$orderId not found');
    }
    return ListView(
      padding: _screenPadding(context),
      children: [
        const _ScreenTopBar(title: 'Order detail', canPop: true),
        const SizedBox(height: 24),
        _Header(title: 'Order #${order.id}', subtitle: order.customer),
        const SizedBox(height: 12),
        _InfoCard(
          rows: [
            ('Status', order.status),
            ('Window', order.window),
            ('Address', order.address),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => showOrderActions(context, order),
          icon: const Icon(Icons.more_horiz),
          label: const Text('Order actions'),
        ),
        const SizedBox(height: 16),
        Text('Line Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in order.items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item.name),
              subtitle: Text('${item.sku} • Qty ${item.quantity}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => unawaited(
                _navigateForLayout(context, orderItemPath(order.id, item.id)),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> _navigateForLayout(BuildContext context, String path) {
  final router = context.lm;
  if (router.location.canonical == path) {
    return Future<void>.value();
  }
  final isExpanded = MediaQuery.sizeOf(context).width >= 840;
  final currentPath = router.location.path;
  final isOrderDetail = RegExp(r'^/orders/[^/]+$').hasMatch(path);
  if (isExpanded && isOrderDetail && currentPath != '/orders') {
    return router.go(path);
  }
  return router.push(path);
}

final class OrderItemScreen extends StatelessWidget {
  const OrderItemScreen({
    required this.repository,
    required this.orderId,
    required this.itemId,
    super.key,
  });

  final OrdersRepository repository;
  final int orderId;
  final int itemId;

  @override
  Widget build(BuildContext context) {
    final item = repository.findItem(orderId, itemId);
    if (item == null) {
      return NotFoundScreen(title: 'Item #$itemId not found');
    }
    return ListView(
      padding: _screenPadding(context),
      children: [
        const _ScreenTopBar(title: 'Line item', canPop: true),
        const SizedBox(height: 24),
        _Header(title: item.name, subtitle: 'Order #$orderId'),
        const SizedBox(height: 12),
        _InfoCard(
          rows: [
            ('SKU', item.sku),
            ('Quantity', '${item.quantity}'),
            ('Status', item.status),
            ('Notes', item.notes),
          ],
        ),
      ],
    );
  }
}

final class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.session,
    required this.onSignOut,
    super.key,
  });

  final SessionStore session;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _screenPadding(context),
      children: [
        const _ScreenTopBar(title: 'Settings'),
        const SizedBox(height: 24),
        const _Header(title: 'Settings', subtitle: 'Account and route testing'),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(session.isSignedIn ? session.userName : 'Signed out'),
            subtitle: const Text('Dispatcher account'),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

final class LoginScreen extends StatelessWidget {
  const LoginScreen({
    required this.returnTo,
    required this.onSignIn,
    super.key,
  });

  final String? returnTo;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sign in', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  returnTo == null
                      ? 'Use your dispatcher account to continue.'
                      : 'Sign in to open $returnTo.',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onSignIn,
                  child: const Text('Sign in and continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

void showOrderActions(BuildContext context, FieldOrder order) {
  unawaited(context.lm.present(orderActionsPath(order.id)));
}

final class OrderActionsSheet extends StatelessWidget {
  const OrderActionsSheet({
    required this.repository,
    required this.orderId,
    super.key,
  });

  final OrdersRepository repository;
  final int orderId;

  @override
  Widget build(BuildContext context) {
    final order = repository.findOrder(orderId);
    if (order == null) {
      return const SizedBox.shrink();
    }
    return CupertinoActionSheet(
      title: Text('Order #${order.id}'),
      message: Text(order.customer),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => unawaited(context.lm.pop()),
          child: const Text('Mark delivered'),
        ),
        CupertinoActionSheetAction(
          onPressed: () => unawaited(_openReschedule(context, order)),
          child: const Text('Reschedule'),
        ),
        CupertinoActionSheetAction(
          onPressed: () => unawaited(_openSharedItem(context, order)),
          child: const Text('Open shared item link'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => unawaited(context.lm.pop()),
        child: const Text('Cancel'),
      ),
    );
  }

  Future<void> _openSharedItem(BuildContext context, FieldOrder order) async {
    final lm = context.lm;
    await lm.pop();
    await Future<void>.delayed(const Duration(milliseconds: 360));
    final firstItem = order.items.first;
    await lm.go(orderItemPath(order.id, firstItem.id));
  }

  Future<void> _openReschedule(BuildContext context, FieldOrder order) async {
    final lm = context.lm;
    await lm.pop();
    await Future<void>.delayed(const Duration(milliseconds: 360));
    await lm.present(orderReschedulePath(order.id));
  }
}

final class OrderRescheduleSheet extends StatelessWidget {
  const OrderRescheduleSheet({
    required this.repository,
    required this.orderId,
    super.key,
  });

  final OrdersRepository repository;
  final int orderId;

  @override
  Widget build(BuildContext context) {
    final router = context.lm;
    final order = repository.findOrder(orderId);
    if (order == null) {
      return const SizedBox.shrink();
    }
    return CupertinoPopupSurface(
      isSurfacePainted: true,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'Choose a new window',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Order #${order.id} for ${order.customer}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (final option in const [
                'Today, 14:00 - 16:00',
                'Tomorrow, 09:00 - 11:00',
                'Tomorrow, 13:00 - 15:00',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CupertinoButton.filled(
                    onPressed: router.pop,
                    child: Text(option),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

EdgeInsets _screenPadding(BuildContext context) {
  return const EdgeInsets.fromLTRB(16, 16, 16, 16);
}

final class _ScreenTopBar extends StatelessWidget {
  const _ScreenTopBar({required this.title, this.canPop = false});

  final String title;
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    if (_isExpandedViewport(context)) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            if (canPop)
              IconButton(
                tooltip: 'Back',
                onPressed: context.lm.pop,
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  semanticLabel: 'Back',
                ),
              )
            else
              const SizedBox.shrink(),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!canPop)
              IconButton(
                tooltip: 'Settings',
                onPressed: () => unawaited(context.lm.go('/settings')),
                icon: const Icon(Icons.verified_user_outlined),
              )
            else
              const SizedBox(width: 48),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

bool _isExpandedViewport(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= 840;
}

final class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    );
  }
}

final class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        row.$1,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Expanded(child: Text(row.$2)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

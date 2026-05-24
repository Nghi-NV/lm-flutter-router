import 'package:flutter/foundation.dart';

final class FieldOrder {
  const FieldOrder({
    required this.id,
    required this.customer,
    required this.address,
    required this.status,
    required this.window,
    required this.items,
  });

  final int id;
  final String customer;
  final String address;
  final String status;
  final String window;
  final List<OrderItem> items;
}

final class OrderItem {
  const OrderItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.status,
    required this.notes,
  });

  final int id;
  final String sku;
  final String name;
  final int quantity;
  final String status;
  final String notes;
}

final class OrdersRepository {
  OrdersRepository()
    : orders = const [
        FieldOrder(
          id: 1042,
          customer: 'Minh Tran',
          address: '12 Nguyen Hue, District 1',
          status: 'Ready for dispatch',
          window: '09:00 - 11:00',
          items: [
            OrderItem(
              id: 9,
              sku: 'LM-CAM-4K',
              name: 'Outdoor camera kit',
              quantity: 2,
              status: 'Packed',
              notes: 'Requires ladder access at delivery site.',
            ),
            OrderItem(
              id: 12,
              sku: 'LM-HUB-PRO',
              name: 'Control hub pro',
              quantity: 1,
              status: 'Packed',
              notes: 'Pair with customer account before handoff.',
            ),
          ],
        ),
        FieldOrder(
          id: 1047,
          customer: 'An Pham',
          address: '88 Vo Van Tan, District 3',
          status: 'Awaiting pickup',
          window: '13:00 - 15:00',
          items: [
            OrderItem(
              id: 3,
              sku: 'LM-SENSOR',
              name: 'Door sensor pack',
              quantity: 6,
              status: 'Picking',
              notes: 'Customer requested tamper labels.',
            ),
          ],
        ),
        FieldOrder(
          id: 1051,
          customer: 'Bao Le',
          address: '4 Pasteur, District 1',
          status: 'Exception',
          window: '16:00 - 18:00',
          items: [
            OrderItem(
              id: 1,
              sku: 'LM-ROUTER-MESH',
              name: 'Mesh router',
              quantity: 3,
              status: 'Needs review',
              notes: 'One unit failed warehouse scan.',
            ),
          ],
        ),
      ];

  final List<FieldOrder> orders;

  FieldOrder? findOrder(int id) {
    for (final order in orders) {
      if (order.id == id) {
        return order;
      }
    }
    return null;
  }

  OrderItem? findItem(int orderId, int itemId) {
    final order = findOrder(orderId);
    if (order == null) {
      return null;
    }
    for (final item in order.items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }
}

final class SessionStore extends ChangeNotifier {
  bool isSignedIn = true;
  String userName = 'Lan Nguyen';

  void signIn() {
    isSignedIn = true;
    notifyListeners();
  }

  void signOut() {
    isSignedIn = false;
    notifyListeners();
  }
}

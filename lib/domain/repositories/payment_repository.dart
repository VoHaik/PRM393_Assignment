import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<List<Tier>> getTiers();
  Future<CreateOrderResponse> createOrder(String tierId);
  Future<void> cancelOrder(String orderId);
  Future<OrderStatusResponse> getOrderStatus(String orderId);
  Future<List<OrderHistoryItem>> getMyOrders({int page = 0, int size = 10});
}

import 'package:dio/dio.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final Dio _dio;

  PaymentRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<Tier>> getTiers() async {
    // Correct backend path: GET /payments/tiers
    final response = await _dio.get('/payments/tiers');
    final apiResponse = response.data;
    final List<dynamic> list = apiResponse['data'] is List ? apiResponse['data'] : [];
    return list.map((item) => TierModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<CreateOrderResponse> createOrder(String tierId) async {
    // Correct backend path: POST /payments/checkout (NOT /payments/orders)
    final response = await _dio.post(
      '/payments/checkout',
      data: {'tierId': tierId},
    );
    final apiResponse = response.data;
    return CreateOrderResponseModel.fromJson(apiResponse['data']);
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    // Backend does not have a cancel-by-orderCode endpoint.
    // Use POST /payments/payos/return to notify backend of cancellation.
    await _dio.post(
      '/payments/payos/return',
      data: {
        'orderCode': int.tryParse(orderId) ?? orderId,
        'cancel': true,
        'status': 'CANCELLED',
      },
    );
  }

  @override
  Future<OrderStatusResponse> getOrderStatus(String orderId) async {
    // Backend does not have a single-order status lookup by orderCode.
    // Fall back to fetching the payment history and finding the matching order.
    final response = await _dio.get('/payments/me');
    final apiResponse = response.data;
    final List<dynamic> list = apiResponse['data'] is List ? apiResponse['data'] : [];
    final allOrders = list
        .map((item) => OrderHistoryItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final orderCode = int.tryParse(orderId);
    final match = allOrders.firstWhere(
      (o) => o.orderCode.toString() == orderId || (orderCode != null && o.orderCode == orderCode),
      orElse: () => throw Exception('Order not found: $orderId'),
    );

    return OrderStatusResponseModel.fromOrderHistoryItem(match);
  }

  @override
  Future<List<OrderHistoryItem>> getMyOrders({int page = 0, int size = 10}) async {
    // Correct backend path: GET /payments/me (NOT /payments/orders)
    // Note: backend GET /payments/me does NOT support pagination params;
    // it returns all orders for the current user.
    final response = await _dio.get('/payments/me');
    final apiResponse = response.data;
    final List<dynamic> list = apiResponse['data'] is List ? apiResponse['data'] : [];
    return list.map((item) => OrderHistoryItemModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}

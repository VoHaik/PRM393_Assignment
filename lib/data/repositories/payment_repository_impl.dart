import 'package:dio/dio.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final Dio _dio;

  PaymentRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<Tier>> getTiers() async {
    final response = await _dio.get('/tiers');
    final apiResponse = response.data;
    final List<dynamic> list = apiResponse['data'] is List ? apiResponse['data'] : [];
    return list.map((item) => TierModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<CreateOrderResponse> createOrder(String tierId) async {
    final response = await _dio.post(
      '/payments/orders',
      data: {'tierId': tierId},
    );
    final apiResponse = response.data;
    return CreateOrderResponseModel.fromJson(apiResponse['data']);
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    // The backend uses orderCode (number) for cancellations. 
    // We try to parse the orderId string to int if possible, or fallback to the string directly.
    final orderCode = int.tryParse(orderId) ?? orderId;
    await _dio.post('/payments/orders/$orderCode/cancel');
  }

  @override
  Future<OrderStatusResponse> getOrderStatus(String orderId) async {
    final orderCode = int.tryParse(orderId) ?? orderId;
    final response = await _dio.get('/payments/orders/$orderCode');
    final apiResponse = response.data;
    return OrderStatusResponseModel.fromJson(apiResponse['data']);
  }

  @override
  Future<List<OrderHistoryItem>> getMyOrders({int page = 0, int size = 10}) async {
    final response = await _dio.get(
      '/payments/orders',
      queryParameters: {'page': page, 'size': size},
    );
    final apiResponse = response.data;
    final content = apiResponse['data'] != null && apiResponse['data']['content'] != null
        ? apiResponse['data']['content'] as List
        : [];
    return content.map((item) => OrderHistoryItemModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}

import '../../domain/entities/payment.dart';

OrderStatus parseOrderStatus(String? statusStr) {
  switch (statusStr?.toLowerCase()) {
    case 'paid':
      return OrderStatus.paid;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'expired':
      return OrderStatus.expired;
    case 'pending':
    default:
      return OrderStatus.pending;
  }
}

String serializeOrderStatus(OrderStatus status) {
  switch (status) {
    case OrderStatus.paid:
      return 'paid';
    case OrderStatus.cancelled:
      return 'cancelled';
    case OrderStatus.expired:
      return 'expired';
    case OrderStatus.pending:
      return 'pending';
  }
}

class TierModel extends Tier {
  const TierModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.noMonth,
    required super.limitedToken,
    required super.isActive,
  });

  factory TierModel.fromJson(Map<String, dynamic> json) {
    return TierModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      noMonth: json['noMonth'] as int? ?? 0,
      limitedToken: json['limitedToken'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

class CreateOrderResponseModel extends CreateOrderResponse {
  const CreateOrderResponseModel({
    required super.orderId,
    required super.orderCode,
    required super.amount,
    required super.status,
    required super.checkoutUrl,
    required super.qrCode,
    required super.paymentLinkId,
    required super.bin,
    required super.accountNumber,
    required super.accountName,
    required super.expiresAt,
  });

  factory CreateOrderResponseModel.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponseModel(
      orderId: json['orderId'] as String? ?? '',
      orderCode: json['orderCode'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: parseOrderStatus(json['status'] as String?),
      checkoutUrl: json['checkoutUrl'] as String? ?? '',
      qrCode: json['qrCode'] as String? ?? '',
      paymentLinkId: json['paymentLinkId'] as String? ?? '',
      bin: json['bin'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class OrderStatusResponseModel extends OrderStatusResponse {
  const OrderStatusResponseModel({
    required super.orderId,
    required super.orderCode,
    required super.amount,
    required super.status,
    required super.tierId,
    super.checkoutUrl,
    super.qrCode,
    super.paidAt,
    required super.createdAt,
  });

  factory OrderStatusResponseModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusResponseModel(
      orderId: json['orderId'] as String? ?? '',
      orderCode: json['orderCode'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: parseOrderStatus(json['status'] as String?),
      tierId: json['tierId'] as String? ?? '',
      checkoutUrl: json['checkoutUrl'] as String?,
      qrCode: json['qrCode'] as String?,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class OrderHistoryItemModel extends OrderHistoryItem {
  const OrderHistoryItemModel({
    required super.orderId,
    required super.orderCode,
    required super.amount,
    required super.status,
    super.tierTitle,
    super.tierAmount,
    super.tierNoMonth,
    super.checkoutUrl,
    super.paidAt,
    required super.createdAt,
  });

  factory OrderHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final tierMap = json['tier'] as Map?;
    return OrderHistoryItemModel(
      orderId: json['orderId'] as String? ?? '',
      orderCode: json['orderCode'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: parseOrderStatus(json['status'] as String?),
      tierTitle: tierMap?['title'] as String?,
      tierAmount: (tierMap?['amount'] as num?)?.toDouble(),
      tierNoMonth: tierMap?['noMonth'] as int?,
      checkoutUrl: json['checkoutUrl'] as String?,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

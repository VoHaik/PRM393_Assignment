enum OrderStatus { pending, paid, cancelled, expired }

class Tier {
  final String id;
  final String title; // 'free', 'plus', 'pro'
  final double amount;
  final int noMonth;
  final int limitedToken;
  final bool isActive;

  const Tier({
    required this.id,
    required this.title,
    required this.amount,
    required this.noMonth,
    required this.limitedToken,
    required this.isActive,
  });
}

class CreateOrderResponse {
  final String orderId;
  final int orderCode;
  final double amount;
  final OrderStatus status;
  final String checkoutUrl;
  final String qrCode;
  final String paymentLinkId;
  final String bin;
  final String accountNumber;
  final String accountName;
  final DateTime expiresAt;

  const CreateOrderResponse({
    required this.orderId,
    required this.orderCode,
    required this.amount,
    required this.status,
    required this.checkoutUrl,
    required this.qrCode,
    required this.paymentLinkId,
    required this.bin,
    required this.accountNumber,
    required this.accountName,
    required this.expiresAt,
  });
}

class OrderStatusResponse {
  final String orderId;
  final int orderCode;
  final double amount;
  final OrderStatus status;
  final String tierId;
  final String? checkoutUrl;
  final String? qrCode;
  final DateTime? paidAt;
  final DateTime createdAt;

  const OrderStatusResponse({
    required this.orderId,
    required this.orderCode,
    required this.amount,
    required this.status,
    required this.tierId,
    this.checkoutUrl,
    this.qrCode,
    this.paidAt,
    required this.createdAt,
  });
}

class OrderHistoryItem {
  final String orderId;
  final int orderCode;
  final double amount;
  final OrderStatus status;
  final String? tierTitle;
  final double? tierAmount;
  final int? tierNoMonth;
  final String? checkoutUrl;
  final DateTime? paidAt;
  final DateTime createdAt;

  const OrderHistoryItem({
    required this.orderId,
    required this.orderCode,
    required this.amount,
    required this.status,
    this.tierTitle,
    this.tierAmount,
    this.tierNoMonth,
    this.checkoutUrl,
    this.paidAt,
    required this.createdAt,
  });
}

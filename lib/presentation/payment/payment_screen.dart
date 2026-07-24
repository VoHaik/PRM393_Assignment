import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:historytalk_flutter/core/theme/lucide_icons.dart';
import 'payment_bloc.dart';
import '../auth/auth_bloc.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/user.dart';
import '../../core/theme/app_theme.dart';
import '../../injection_container.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentBloc _paymentBloc;

  @override
  void initState() {
    super.initState();
    _paymentBloc = sl<PaymentBloc>()..add(FetchTiersRequested());
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi-VN', symbol: '₫', decimalDigits: 0);
    return format.format(amount);
  }

  String _tierFeatureSummary(String title) {
    final v = title.toLowerCase();
    if (v.contains('pro')) return 'Nội dung, chat, call, video call, quiz';
    if (v.contains('plus')) return 'Nội dung, chat, call, quiz';
    return 'Nội dung, chat, quiz';
  }

  Widget _buildStatusBanner(OrderStatus status, Color accentColor) {
    IconData icon;
    Color color;
    String label;

    switch (status) {
      case OrderStatus.paid:
        icon = LucideIcons.badgeCheck;
        color = Colors.green;
        label = 'Thanh toán thành công! Gói đã được kích hoạt.';
        break;
      case OrderStatus.pending:
        icon = LucideIcons.clock;
        color = Colors.amber.shade800;
        label = 'PayOS đang xử lý. Hãy kiểm tra lại sau ít phút.';
        break;
      case OrderStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.red;
        label = 'Giao dịch đã bị hủy.';
        break;
      case OrderStatus.expired:
        icon = Icons.cancel;
        color = Colors.red;
        label = 'Liên kết thanh toán đã hết hạn.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocProvider.value(
      value: _paymentBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nâng cấp gói hội viên', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.textTheme.bodyLarge?.color,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.history),
              onPressed: () {
                // Navigate to order history screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Lịch sử giao dịch')),
                      body: const Center(child: Text('Lịch sử giao dịch')),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: BlocConsumer<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state.polledStatus?.status == OrderStatus.paid) {
                // Refresh User profile in AuthBloc if order is completed
                context.read<AuthBloc>().add(AppStarted());
              }
            },
            builder: (context, state) {
              if (state.isTiersLoading && state.tiers.isEmpty) {
                return Center(child: CircularProgressIndicator(color: accentColor));
              }

              final activeTiers = state.tiers.where((t) => t.isActive).toList()
                ..sort((a, b) => a.amount.compareTo(b.amount));

              return RefreshIndicator(
                onRefresh: () async {
                  _paymentBloc.add(FetchTiersRequested());
                },
                color: accentColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Polling Banner
                      if (state.polledStatus != null)
                        _buildStatusBanner(state.polledStatus!.status, accentColor),

                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Text(
                          'Chọn gói phù hợp để mở khóa toàn bộ tính năng HistoryTalk. Thanh toán an toàn qua PayOS — chuyển khoản ngân hàng & quét mã QR.',
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13, height: 1.4),
                        ),
                      ),

                      // List of Tiers
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: activeTiers.map((tier) {
                            final isFree = tier.amount <= 0;
                            // Check if this tier matches the user's active tier
                            final authState = context.read<AuthBloc>().state;
                            final bool isCurrent = authState is Authenticated &&
                                authState.user.role == UserRole.customer; // Simplification, would check tierId
                            final isFeatured = tier.title.toLowerCase().contains('pro') && !isFree;
                            final isBusy = state.isOrdering && state.activeOrder == null; // Loader for selected order

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Container(
                                padding: const EdgeInsets.all(18.0),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isFeatured ? accentColor : borderColor,
                                    width: isFeatured ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          LucideIcons.crown,
                                          color: isFeatured ? accentColor : textMuted,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tier.title.toUpperCase(),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${tier.noMonth} tháng sử dụng',
                                                style: TextStyle(fontSize: 12, color: textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Pricing
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          isFree ? 'Miễn phí' : _formatCurrency(tier.amount),
                                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                        if (!isFree) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '/${tier.noMonth} tháng',
                                            style: TextStyle(fontSize: 12, color: textMuted),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Features list
                                    Column(
                                      children: [
                                        _buildFeatureItem(
                                          'Token AI: ${NumberFormat('#,###', 'vi_VN').format(tier.limitedToken)}',
                                          isFeatured,
                                          accentColor,
                                          textMuted,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildFeatureItem(
                                          _tierFeatureSummary(tier.title),
                                          isFeatured,
                                          accentColor,
                                          textMuted,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),

                                    // Purchase button
                                    if (isFree || isCurrent)
                                      Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Gói hiện tại',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                                          ),
                                        ),
                                      )
                                    else
                                      ElevatedButton(
                                        onPressed: isBusy ? null : () => _paymentBloc.add(CreateOrderRequested(tierId: tier.id)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isFeatured ? accentColor : accentColor.withOpacity(0.12),
                                          foregroundColor: isFeatured ? Colors.white : accentColor,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          minimumSize: const Size.fromHeight(46),
                                        ),
                                        child: isBusy
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : const Text('Đăng ký ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Footer Note
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.shieldCheck, size: 14, color: textMuted),
                            const SizedBox(width: 6),
                            Text('Thanh toán bảo mật an toàn qua PayOS', style: TextStyle(fontSize: 11, color: textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool isFeatured, Color accentColor, Color textMuted) {
    return Row(
      children: [
        Icon(
          isFeatured ? LucideIcons.sparkles : LucideIcons.check,
          size: 14,
          color: isFeatured ? accentColor : textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

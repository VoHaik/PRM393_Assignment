import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final transactions = [
      {
        'tier': 'Gói Premium (1 Tháng)',
        'amount': '99.000 VNĐ',
        'date': '15/07/2026 14:30',
        'status': 'Thành công',
        'orderCode': 'PAYOS-849201',
      },
      {
        'tier': 'Gói Tiêu Chuẩn (1 Tháng)',
        'amount': '49.000 VNĐ',
        'date': '15/06/2026 10:15',
        'status': 'Thành công',
        'orderCode': 'PAYOS-738192',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tx['tier']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tx['status']!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mã đơn hàng: ${tx['orderCode']}', style: TextStyle(fontSize: 13, color: textMuted)),
                      Text(
                        tx['amount']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Thời gian: ${tx['date']}', style: TextStyle(fontSize: 12, color: textMuted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

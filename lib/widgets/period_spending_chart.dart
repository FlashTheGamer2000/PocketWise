import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpendingBucket {
  final String label;
  final double amount;

  const SpendingBucket({required this.label, required this.amount});
}

class PeriodSpendingChart extends StatelessWidget {
  final String title;
  final List<SpendingBucket> buckets;

  const PeriodSpendingChart({
    super.key,
    required this.title,
    required this.buckets,
  });

  @override
  Widget build(BuildContext context) {
    final maxAmount = buckets.fold<double>(
      0.0,
      (maximum, bucket) => math.max(maximum, bucket.amount).toDouble(),
    );
    final hasSpending = maxAmount > 0;
    final viewportWidth = MediaQuery.sizeOf(context).width - 68;
    final chartWidth = math.max(viewportWidth, buckets.length * 58.0).toDouble();
    final compactCurrency = NumberFormat.compact(locale: 'id_ID');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSpending
                ? 'Amounts in rupiah'
                : 'No spending recorded for this period',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              height: 158,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: buckets.map((bucket) {
                  final ratio = maxAmount > 0 ? bucket.amount / maxAmount : 0.0;
                  final barHeight =
                      hasSpending ? math.max(4.0, ratio * 100).toDouble() : 4.0;
                  return SizedBox(
                    width: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 25,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              bucket.amount <= 0
                                  ? 'Rp 0'
                                  : 'Rp ${compactCurrency.format(bucket.amount)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          width: 27,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 20,
                          child: Center(
                            child: Text(
                              bucket.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
// 🚨 核心修复：用 ../ 退回上一级目录，红线瞬间消失！
import '../models/bill_data.dart';
import '../theme/app_theme.dart'; 

class BillDetailPage extends StatelessWidget {
  final BillData bill;

  const BillDetailPage({super.key, required this.bill});

  Color getRiskColor(String risk) {
    switch (risk) {
      case 'SAFE': return AppColors.success;
      case 'HIGH': return AppColors.danger;
      default: return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color riskColor = getRiskColor(bill.riskLevel);
    final bool hasRisk = bill.riskPoints.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgMain, // 极致暗黑底色
      appBar: AppBar(
        title: const Text('安全审计报告', style: AppText.cardTitle18),
        backgroundColor: AppColors.bgSecondary,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧱 模块 1：宏观资产总览卡片
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(bill.issuer, style: AppText.section22),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bill.riskLevel == 'SAFE' ? '🛡️ SAFE' : '⚠️ HIGH RISK',
                          style: AppText.tag12.copyWith(color: riskColor),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Amount Due', style: AppText.secondary14),
                          const SizedBox(height: 8),
                          Text('\$${bill.amountDue.toStringAsFixed(2)}', style: AppText.amount26),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Due Date', style: AppText.secondary14),
                          const SizedBox(height: 8),
                          Text(bill.dueDate, style: AppText.cardTitle18),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🧱 模块 2：价值战报（GuardBill 帮你省了多少钱）
            if (bill.amountSaved > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.accent, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Potential Loss Prevented', style: AppText.tag12.copyWith(color: AppColors.accent)),
                          const SizedBox(height: 4),
                          Text('\$${bill.amountSaved.toStringAsFixed(2)}', style: AppText.section22),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 🧱 模块 3：硬核风控诊断书（逐条列出风险）
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text('AI Audit Results', style: AppText.cardTitle18),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: !hasRisk
                  ? Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                        const SizedBox(width: 12),
                        Expanded(child: Text('全项审计通过，未检测到隐藏利息陷阱。', style: AppText.secondary14.copyWith(color: AppColors.textMain))),
                      ],
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bill.riskPoints.length,
                      separatorBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: AppColors.divider),
                      ),
                      itemBuilder: (context, index) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2.0),
                              child: Icon(Icons.warning_rounded, color: AppColors.danger, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                bill.riskPoints[index],
                                style: AppText.secondary14.copyWith(color: AppColors.textMain, height: 1.5),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // 🧱 模块 4：基础账单静态存证
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text('Document Meta', style: AppText.cardTitle18),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildStaticRow('Type', bill.billType),
                  const SizedBox(height: 16),
                  _buildStaticRow('Currency', bill.currency),
                  const SizedBox(height: 16),
                  _buildStaticRow('Min Payment', '\$${bill.minimumDue.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  _buildStaticRow('Risk Exposure', '\$${bill.potentialLoss.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  _buildStaticRow('Audit Time', bill.createdAt.substring(0, 10) + ' ' + bill.createdAt.substring(11, 16)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.secondary14),
        Text(value, style: AppText.secondary14.copyWith(color: AppColors.textMain, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
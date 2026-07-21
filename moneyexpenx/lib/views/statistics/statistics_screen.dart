import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/core/constants/icons.dart';
import 'package:moneyexpenx/data/models/category_model.dart';
import 'package:moneyexpenx/data/models/transaction_model.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _typeTabController;
  String _timeFilter = 'Tháng'; // 'Tuần', 'Tháng', 'Năm'
  final formatter = NumberFormat.decimalPattern('vi_VN');

  // Vibrant chart colors matching the premium theme
  final List<Color> _chartColors = [
    AppTheme.primaryYellow,
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Emerald Green
    const Color(0xFFEC4899), // Pink
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _typeTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _typeTabController.dispose();
    super.dispose();
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> allTx) {
    final now = DateTime.now();
    DateTime startDate;

    if (_timeFilter == 'Tuần') {
      // Start of current week (Monday)
      final daysToSubtract = now.weekday - 1;
      startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
    } else if (_timeFilter == 'Năm') {
      startDate = DateTime(now.year, 1, 1);
    } else {
      // Default: 'Tháng' (Start of current month)
      startDate = DateTime(now.year, now.month, 1);
    }

    return allTx.where((tx) => tx.tsDate.isAfter(startDate) || tx.tsDate.isAtSameMomentAs(startDate)).toList();
  }

  // Export report to CSV (Excel compatible)
  Future<void> _exportReport(
      List<TransactionModel> txs, List<CategoryModel> categories, String type) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/BaoCao_ThuChi_${type}_$dateStr.csv';
      final file = File(filePath);

      // CSV Header
      StringBuffer csvContent = StringBuffer();
      // Add UTF-8 BOM for Excel compatibility with Vietnamese characters
      csvContent.write('\uFEFF');
      csvContent.writeln('Mã Giao Dịch,Ngày,Loại,Danh Mục,Số Tiền (đ),Ghi Chú');

      for (var tx in txs) {
        final cat = categories.firstWhere(
          (c) => c.ctgID == tx.ctgID,
          orElse: () => CategoryModel(ctgID: '', uID: '', name: 'Không rõ', type: type, iconKey: 'payment'),
        );

        if (cat.type == type) {
          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(tx.tsDate);
          final note = tx.note.replaceAll(',', ';'); // avoid breaking columns
          csvContent.writeln('${tx.tsID},$formattedDate,${cat.type},${cat.name},${tx.amt},$note');
        }
      }

      await file.writeAsString(csvContent.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xuất báo cáo thành công!\nĐường dẫn: $filePath',
              style: GoogleFonts.beVietnamPro(color: Colors.white),
            ),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất báo cáo: $e', style: GoogleFonts.beVietnamPro(color: Colors.white)),
            backgroundColor: AppTheme.alertRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeVm = Provider.of<FinanceViewModel>(context);
    final allTxs = financeVm.transactions;
    final categories = financeVm.categories;

    // Filter transactions by time range
    final filteredTxs = _filterTransactions(allTxs);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thống Kê Báo Cáo',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        bottom: TabBar(
          controller: _typeTabController,
          indicatorColor: AppTheme.primaryYellow,
          labelColor: AppTheme.primaryYellow,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'KHOẢN CHI'),
            Tab(text: 'KHOẢN THU'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppTheme.primaryYellow, size: 26),
            onPressed: () {
              final activeType = _typeTabController.index == 0 ? 'Chi' : 'Thu';
              _exportReport(filteredTxs, categories, activeType);
            },
            tooltip: 'Xuất file Excel CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Time Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Khoảng thời gian:',
                  style: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary, fontSize: 14),
                ),
                Row(
                  children: ['Tuần', 'Tháng', 'Năm'].map((filter) {
                    final isSelected = _timeFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _timeFilter = filter;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryYellow.withOpacity(0.15) : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryYellow : Colors.grey[850]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          filter == 'Tuần'
                              ? 'Tuần này'
                              : filter == 'Tháng'
                                  ? 'Tháng này'
                                  : 'Năm nay',
                          style: GoogleFonts.beVietnamPro(
                            color: isSelected ? AppTheme.primaryYellow : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _typeTabController,
              children: [
                _buildReportSection(filteredTxs, categories, 'Chi'),
                _buildReportSection(filteredTxs, categories, 'Thu'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection(
      List<TransactionModel> txs, List<CategoryModel> categories, String type) {
    // 1. Filter transactions by type
    final typeTxs = txs.where((t) {
      final cat = categories.firstWhere(
        (c) => c.ctgID == t.ctgID,
        orElse: () => CategoryModel(ctgID: '', uID: '', name: '', type: '', iconKey: ''),
      );
      return cat.type == type;
    }).toList();

    if (typeTxs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Chưa có giao dịch $type nào trong thời gian này.',
              style: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    // 2. Aggregate sum by category ID
    final Map<String, double> categorySums = {};
    double totalSum = 0.0;

    for (var tx in typeTxs) {
      categorySums[tx.ctgID] = (categorySums[tx.ctgID] ?? 0.0) + tx.amt;
      totalSum += tx.amt;
    }

    // 3. Map category sums to details and sort
    final List<MapEntry<String, double>> sortedEntries = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Group into Top 5 and "Others" if needed
    List<CategoryStatItem> statItems = [];
    double othersSum = 0.0;

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final cat = categories.firstWhere(
        (c) => c.ctgID == entry.key,
        orElse: () => CategoryModel(ctgID: '', uID: '', name: 'Không rõ', type: type, iconKey: 'payment'),
      );

      if (i < 5) {
        statItems.add(CategoryStatItem(
          category: cat,
          amount: entry.value,
          percentage: entry.value / totalSum,
          color: _chartColors[i % _chartColors.length],
        ));
      } else {
        othersSum += entry.value;
      }
    }

    if (othersSum > 0) {
      statItems.add(CategoryStatItem(
        category: CategoryModel(ctgID: 'others', uID: '', name: 'Khác', type: type, iconKey: 'payment'),
        amount: othersSum,
        percentage: othersSum / totalSum,
        color: _chartColors[5 % _chartColors.length],
      ));
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Total Card
        GlassContainer(
          padding: const EdgeInsets.all(20),
          color: Colors.white.withOpacity(0.03),
          borderColor: Colors.white.withOpacity(0.05),
          child: Column(
            children: [
              Text(
                'TỔNG ${type.toUpperCase()}',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatter.format(totalSum)} đ',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: type == 'Thu' ? AppTheme.successGreen : AppTheme.alertRed,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Donut Chart Card
        GlassContainer(
          padding: const EdgeInsets.all(24),
          color: Colors.white.withOpacity(0.02),
          borderColor: Colors.white.withOpacity(0.04),
          child: Column(
            children: [
              Text(
                'Phân Tích Cơ Cấu',
                style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              // Draw Custom Donut Chart
              SizedBox(
                height: 160,
                width: 160,
                child: CustomPaint(
                  painter: DonutChartPainter(
                    values: statItems.map((item) => item.amount).toList(),
                    colors: statItems.map((item) => item.color).toList(),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Giao dịch',
                          style: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        Text(
                          '${typeTxs.length}',
                          style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Statistics list title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Xếp hạng danh mục',
            style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),

        // Statistics List
        ...statItems.map((item) {
          final percentStr = '${(item.percentage * 100).toStringAsFixed(1)}%';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white.withOpacity(0.04),
              borderColor: Colors.white.withOpacity(0.05),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: item.color.withOpacity(0.1),
                    child: Icon(
                      CategoryIcons.getIcon(item.category.iconKey),
                      color: item.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.category.name,
                          style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        // Linear mini-bar indicator
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: item.percentage,
                            backgroundColor: Colors.grey[900],
                            color: item.color,
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${formatter.format(item.amount)} đ',
                        style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        percentStr,
                        style: GoogleFonts.beVietnamPro(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class CategoryStatItem {
  final CategoryModel category;
  final double amount;
  final double percentage;
  final Color color;

  CategoryStatItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2.5, paint);
      return;
    }

    final double center = size.width / 2;
    final double radius = size.width / 2.5;
    double startAngle = -3.14159 / 2;

    for (int i = 0; i < values.length; i++) {
      final double sweepAngle = 2 * 3.14159 * (values[i] / total);
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 14;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(center, center), radius: radius),
        startAngle,
        sweepAngle - 0.05, // small gap between segments
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({Key? key}) : super(key: key);

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  int _selectedFormatIndex = 0; // 0 = Excel/CSV, 1 = Printable PDF/Text
  bool _copied = false;
  bool _isSaving = false;

  Future<void> _saveFileToDevice(String content, bool isCsv) async {
    setState(() => _isSaving = true);
    try {
      Directory? dir;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final extension = isCsv ? 'csv' : 'txt';
      final fileName = 'Bao_Cao_Tai_Chinh_MoneyExpenx_$dateStr.$extension';
      final file = File('${dir.path}/$fileName');

      await file.writeAsString(content, encoding: utf8);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Đã lưu file thành công!\nĐường dẫn: ${file.path}',
              style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu file: $e', style: GoogleFonts.beVietnamPro(color: Colors.white)),
            backgroundColor: AppTheme.alertRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeVm = Provider.of<FinanceViewModel>(context);
    final csvContent = financeVm.exportExcelCsvContent();
    final reportContent = financeVm.exportPrintableReportContent();
    final isCsvMode = _selectedFormatIndex == 0;
    final currentContent = isCsvMode ? csvContent : reportContent;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Xuất Báo Cáo Tài Chính',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format selector tabs
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedFormatIndex = 0;
                          _copied = false;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedFormatIndex == 0 ? AppTheme.primaryYellow : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.table_chart_outlined,
                                size: 18,
                                color: _selectedFormatIndex == 0 ? Colors.black : Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'File Excel / CSV',
                                style: GoogleFonts.beVietnamPro(
                                  color: _selectedFormatIndex == 0 ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedFormatIndex = 1;
                          _copied = false;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedFormatIndex == 1 ? AppTheme.primaryYellow : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 18,
                                color: _selectedFormatIndex == 1 ? Colors.black : Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Báo Cáo PDF / Text',
                                style: GoogleFonts.beVietnamPro(
                                  color: _selectedFormatIndex == 1 ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Format Description Card
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _selectedFormatIndex == 0 ? Icons.grid_on : Icons.description,
                        color: AppTheme.primaryYellow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFormatIndex == 0
                                ? 'Định dạng Excel CSV (.csv / .xlsx)'
                                : 'Định dạng Văn Bản / PDF In Ấn',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedFormatIndex == 0
                                ? 'Chứa đầy đủ mã giao dịch, danh mục, số tiền, hũ tiết kiệm & nợ. Mở trực tiếp bằng Excel/Google Sheets.'
                                : 'Bản tóm tắt đẹp mắt chỉ số thu chi, tỷ lệ phân bổ danh mục, hũ tích lũy và dư nợ vay.',
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Code/Text Preview Container
              Expanded(
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Xem trước nội dung',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${currentContent.length} ký tự',
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SelectableText(
                            currentContent,
                            style: GoogleFonts.firaCode(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons Row (Tải file về máy + Sao chép nội dung)
              Row(
                children: [
                  // 1. Download File Button
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _saveFileToDevice(currentContent, isCsvMode),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                      label: Text(
                        _isSaving
                            ? 'Đang Lưu...'
                            : (isCsvMode ? 'TẢI FILE EXCEL (.csv)' : 'TẢI FILE VĂN BẢN (.txt)'),
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 2. Copy Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: currentContent));
                        setState(() {
                          _copied = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isCsvMode
                                  ? 'Đã sao chép nội dung Excel/CSV vào bộ nhớ tạm!'
                                  : 'Đã sao chép nội dung Báo cáo PDF/Text vào bộ nhớ tạm!',
                            ),
                            backgroundColor: AppTheme.primaryYellow,
                          ),
                        );
                      },
                      icon: Icon(_copied ? Icons.check : Icons.copy, color: Colors.white, size: 16),
                      label: Text(
                        _copied ? 'Đã Chép' : 'Sao Chép',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.12),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

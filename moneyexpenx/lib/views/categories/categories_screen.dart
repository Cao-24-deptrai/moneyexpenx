import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/core/constants/icons.dart';
import 'package:moneyexpenx/data/models/category_model.dart';
import 'package:moneyexpenx/viewmodels/auth_viewmodel.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  String _selectedType = 'Chi';
  String _selectedIconKey = 'payment';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showAddCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GlassContainer(
                borderRadius: 24,
                color: Colors.black.withOpacity(0.85),
                borderColor: AppTheme.primaryYellow.withOpacity(0.3),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thêm Danh Mục',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryYellow,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Name field
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.beVietnamPro(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tên danh mục',
                        labelStyle: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primaryYellow),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Segmented Type
                    Row(
                      children: [
                        Text(
                          'Loại:',
                          style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: Text('Chi tiêu (Chi)', style: GoogleFonts.beVietnamPro(color: _selectedType == 'Chi' ? Colors.black : Colors.white)),
                          selected: _selectedType == 'Chi',
                          selectedColor: AppTheme.primaryYellow,
                          backgroundColor: Colors.grey[900],
                          onSelected: (val) {
                            if (val) setModalState(() => _selectedType = 'Chi');
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: Text('Thu nhập (Thu)', style: GoogleFonts.beVietnamPro(color: _selectedType == 'Thu' ? Colors.black : Colors.white)),
                          selected: _selectedType == 'Thu',
                          selectedColor: AppTheme.primaryYellow,
                          backgroundColor: Colors.grey[900],
                          onSelected: (val) {
                            if (val) setModalState(() => _selectedType = 'Thu');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Chọn Biểu Tượng:',
                      style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    // Icons grid
                    SizedBox(
                      height: 120,
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: CategoryIcons.iconMap.length,
                        itemBuilder: (context, index) {
                          String key = CategoryIcons.iconMap.keys.elementAt(index);
                          IconData icon = CategoryIcons.iconMap.values.elementAt(index);
                          bool isSelected = _selectedIconKey == key;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _selectedIconKey = key;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryYellow.withOpacity(0.2) : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryYellow : Colors.grey[800]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? AppTheme.primaryYellow : Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassCardButton(
                      color: AppTheme.primaryYellow,
                      onTap: () async {
                        if (_nameController.text.trim().isEmpty) return;
                        final authVm = Provider.of<AuthViewModel>(context, listen: false);
                        final financeVm = Provider.of<FinanceViewModel>(context, listen: false);

                        final error = await financeVm.addCategory(
                          name: _nameController.text,
                          type: _selectedType,
                          iconKey: _selectedIconKey,
                          uID: authVm.currentUser!.uID,
                        );

                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error, style: GoogleFonts.beVietnamPro(color: Colors.white)),
                              backgroundColor: AppTheme.alertRed,
                            ),
                          );
                        } else {
                          _nameController.clear();
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          'TẠO DANH MỤC',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeVm = Provider.of<FinanceViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Danh Mục Tài Chính',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        bottom: TabBar(
          controller: _tabController,
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
            icon: const Icon(Icons.add, color: AppTheme.primaryYellow, size: 28),
            onPressed: _showAddCategorySheet,
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(financeVm.getExpenseCategories()),
          _buildCategoryList(financeVm.getIncomeCategories()),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Chưa có danh mục nào.',
              style: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showAddCategorySheet,
              child: Text(
                'Tạo danh mục mới',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0x0AFFFFFF),
            borderColor: Colors.white.withOpacity(0.05),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryYellow.withOpacity(0.1),
                  child: Icon(
                    CategoryIcons.getIcon(cat.iconKey),
                    color: AppTheme.primaryYellow,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    cat.name,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  cat.type == 'Thu' ? 'Thu nhập' : 'Chi tiêu',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: cat.type == 'Thu' ? AppTheme.successGreen : AppTheme.alertRed,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                  onPressed: () {
                    // Show double confirm
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppTheme.cardBg,
                        title: Text('Xóa Danh Mục', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
                        content: Text(
                          'Bạn có chắc muốn xóa danh mục "${cat.name}"? Các giao dịch thuộc danh mục này sẽ mất phân loại.',
                          style: GoogleFonts.beVietnamPro(),
                        ),
                        actions: [
                          TextButton(
                            child: Text('HỦY', style: GoogleFonts.beVietnamPro(color: Colors.white)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text('XÓA', style: GoogleFonts.beVietnamPro(color: AppTheme.alertRed)),
                            onPressed: () {
                              Provider.of<FinanceViewModel>(context, listen: false).deleteCategory(cat.ctgID);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

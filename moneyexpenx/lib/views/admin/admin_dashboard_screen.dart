import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/data/models/user_model.dart';
import 'package:moneyexpenx/viewmodels/auth_viewmodel.dart';
import 'package:moneyexpenx/views/dashboard/dashboard_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  List<UserModel> _users = [];
  Map<String, int> _stats = {
    'totalUsers': 0,
    'totalTransactions': 0,
    'totalJars': 0,
    'totalLoans': 0,
  };
  String _searchQuery = '';
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final authVm = Provider.of<AuthViewModel>(context, listen: false);

    final users = await authVm.fetchAllUsers();
    final stats = await authVm.fetchSystemStats();

    if (mounted) {
      setState(() {
        _users = users;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.trim().isEmpty) return _users;
    final query = _searchQuery.trim().toLowerCase();
    return _users.where((u) {
      return u.username.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _toggleUserRole(UserModel user) async {
    final newRole = user.role == 'admin' ? 'user' : 'admin';
    final actionText = newRole == 'admin' ? 'nâng lên Admin' : 'hạ xuống User';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận đổi quyền',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc chắn muốn $actionText cho tài khoản "${user.username}" (${user.email})?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authVm = Provider.of<AuthViewModel>(context, listen: false);
      final success = await authVm.updateUserRole(user.uID, newRole);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã đổi quyền của ${user.username} thành ${newRole.toUpperCase()}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadAdminData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authVm.errorMessage ?? 'Thao tác thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xóa tài khoản người dùng',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Hành động này sẽ XÓA VĨNH VIỄN tài khoản "${user.username}" (${user.email}) và mọi dữ liệu liên quan (giao dịch, hũ tiết kiệm, khoản vay, danh mục...). Hành động này không thể hoàn tác!\n\nBạn có chắc chắn muốn xóa không?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authVm = Provider.of<AuthViewModel>(context, listen: false);
      final success = await authVm.deleteUser(user.uID);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa thành công tài khoản của ${user.username}!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAdminData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authVm.errorMessage ?? 'Xóa thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context);
    final currentUser = authVm.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.blackBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: AppTheme.primaryYellow,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PANEL QUẢN TRỊ ADMIN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  currentUser?.email ?? 'rocon@gmail.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryYellow),
            tooltip: 'Làm mới dữ liệu',
            onPressed: _loadAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: () => authVm.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryYellow),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              color: AppTheme.primaryYellow,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Navigation Button to User Mode
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryYellow,
                            AppTheme.primaryYellow.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryYellow.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DashboardScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.dashboard_customize,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'CHUYỂN SANG MÀN HÌNH NGƯỜI DÙNG',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Section Title: System Statistics
                    const Text(
                      '📌 THỐNG KÊ HỆ THỐNG TOÀN CẦU',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryYellow,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grid of 4 Stat Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          title: 'Tổng Người Dùng',
                          value: _stats['totalUsers']?.toString() ?? '0',
                          icon: Icons.people_alt,
                          color: Colors.blueAccent,
                        ),
                        _buildStatCard(
                          title: 'Tổng Giao Dịch',
                          value: _stats['totalTransactions']?.toString() ?? '0',
                          icon: Icons.receipt_long,
                          color: Colors.amber,
                        ),
                        _buildStatCard(
                          title: 'Hũ Tiết Kiệm',
                          value: _stats['totalJars']?.toString() ?? '0',
                          icon: Icons.savings,
                          color: Colors.greenAccent,
                        ),
                        _buildStatCard(
                          title: 'Khoản Vay & Nợ',
                          value: _stats['totalLoans']?.toString() ?? '0',
                          icon: Icons.account_balance_wallet,
                          color: Colors.purpleAccent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Section Title: User Management
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '👥 QUẢN LÝ DANH SÁCH TÀI KHOẢN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryYellow,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_filteredUsers.length} tài khoản',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search Box
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo tên hoặc email...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.primaryYellow,
                        ),
                        filled: true,
                        fillColor: AppTheme.cardBg,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryYellow,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User List
                    if (_filteredUsers.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 48,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy tài khoản nào',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isAdmin = user.role == 'admin';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isAdmin
                                        ? AppTheme.primaryYellow.withOpacity(
                                            0.2,
                                          )
                                        : Colors.white.withOpacity(0.1),
                                    child: Icon(
                                      isAdmin
                                          ? Icons.workspace_premium
                                          : Icons.person,
                                      color: isAdmin
                                          ? AppTheme.primaryYellow
                                          : Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                user.username,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isAdmin
                                                    ? AppTheme.primaryYellow
                                                          .withOpacity(0.2)
                                                    : Colors.blue.withOpacity(
                                                        0.2,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isAdmin
                                                      ? AppTheme.primaryYellow
                                                      : Colors.blue,
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                user.role.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isAdmin
                                                      ? AppTheme.primaryYellow
                                                      : Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.email,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Ngày tạo: ${_dateFormat.format(user.createdAt)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white.withOpacity(
                                              0.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (user.uID != currentUser?.uID &&
                                      user.email != 'rocon@gmail.com')
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Colors.white70,
                                      ),
                                      color: AppTheme.cardBg,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      onSelected: (val) {
                                        if (val == 'toggle_role') {
                                          _toggleUserRole(user);
                                        } else if (val == 'delete_user') {
                                          _deleteUser(user);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        PopupMenuItem(
                                          value: 'toggle_role',
                                          child: Row(
                                            children: [
                                              Icon(
                                                isAdmin
                                                    ? Icons.arrow_downward
                                                    : Icons.arrow_upward,
                                                color: isAdmin
                                                    ? Colors.orangeAccent
                                                    : AppTheme.primaryYellow,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isAdmin
                                                    ? 'Chuyển về User'
                                                    : 'Nâng thành Admin',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete_user',
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.delete_forever,
                                                color: Colors.redAccent,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Xóa tài khoản',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

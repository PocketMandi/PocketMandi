import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'users_management_screen.dart';
import 'crops_management_screen.dart';
import 'requests_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const AdminHomeScreen();
      case 1:
        return const UsersManagementScreen();
      case 2:
        return const CropsManagementScreen();
      case 3:
        return const RequestsManagementScreen();
      default:
        return const AdminHomeScreen();
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF104f22).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF104f22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF104f22) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.people_rounded, 'Users'),
                _buildNavItem(2, Icons.eco_rounded, 'Crops'),
                _buildNavItem(3, Icons.assignment_rounded, 'Requests'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF104f22),
              const Color(0xFF104f22).withOpacity(0.8),
              Colors.white,
            ],
            stops: const [0.0, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Manage your platform',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
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
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder(
                          stream: FirebaseDatabase.instance
                              .ref('users')
                              .onValue,
                          builder:
                              (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                                int totalUsers = 0;
                                int farmers = 0;
                                int traders = 0;
                                int pendingKyc = 0;

                                if (snapshot.hasData &&
                                    snapshot.data!.snapshot.value != null) {
                                  var usersData =
                                      snapshot.data!.snapshot.value
                                          as Map<dynamic, dynamic>;
                                  totalUsers = usersData.length;
                                  farmers = usersData.values
                                      .where((u) => u['role'] == 'farmer')
                                      .length;
                                  traders = usersData.values
                                      .where((u) => u['role'] == 'trader')
                                      .length;
                                  pendingKyc = usersData.values
                                      .where((u) => u['kycStatus'] == 'pending')
                                      .length;
                                }

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatCard(
                                            'Total Users',
                                            totalUsers.toString(),
                                            Icons.people,
                                            const Color(0xFF2196F3),
                                            const Color(0xFFE3F2FD),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatCard(
                                            'Pending KYC',
                                            pendingKyc.toString(),
                                            Icons.pending_actions,
                                            const Color(0xFFFF9800),
                                            const Color(0xFFFFF3E0),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatCard(
                                            'Farmers',
                                            farmers.toString(),
                                            Icons.agriculture,
                                            const Color(0xFF4CAF50),
                                            const Color(0xFFE8F5E9),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatCard(
                                            'Traders',
                                            traders.toString(),
                                            Icons.store,
                                            const Color(0xFF9C27B0),
                                            const Color(0xFFF3E5F5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionCard(
                          context,
                          'Manage Users',
                          'View and manage all users',
                          Icons.people_outline,
                          const Color(0xFF2196F3),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UsersManagementScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          context,
                          'Manage Crops',
                          'Add, edit or delete crops',
                          Icons.grass,
                          const Color(0xFF4CAF50),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CropsManagementScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          context,
                          'View Requests',
                          'Check all pending requests',
                          Icons.request_page,
                          const Color(0xFFFF9800),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RequestsManagementScreen(),
                            ),
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
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

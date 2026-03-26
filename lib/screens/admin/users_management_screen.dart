import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({Key? key}) : super(key: key);

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  String _filterRole = 'all';
  String _filterKyc = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            stops: const [0.0, 0.25, 0.25],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Users Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage all platform users',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Statistics Cards
              StreamBuilder(
                stream: _usersRef.onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> statsSnapshot) {
                  int totalUsers = 0;
                  int farmers = 0;
                  int traders = 0;
                  int pendingKyc = 0;

                  if (statsSnapshot.hasData && statsSnapshot.data!.snapshot.value != null) {
                    var usersData = statsSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    totalUsers = usersData.length;
                    farmers = usersData.values.where((u) => u['role'] == 'farmer').length;
                    traders = usersData.values.where((u) => u['role'] == 'trader').length;
                    pendingKyc = usersData.values.where((u) => u['kycStatus'] == 'pending').length;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMiniStatCard(
                            totalUsers.toString(),
                            'Total',
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStatCard(
                            farmers.toString(),
                            'Farmers',
                            Icons.agriculture,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStatCard(
                            traders.toString(),
                            'Traders',
                            Icons.store,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStatCard(
                            pendingKyc.toString(),
                            'Pending',
                            Icons.pending_actions,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Search and Filters Section
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by name or phone...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Filter Chips
                          Row(
                            children: [
                              Expanded(
                                child: _buildFilterChip(
                                  'Role',
                                  _filterRole,
                                  ['all', 'farmer', 'trader'],
                                  ['All', 'Farmers', 'Traders'],
                                  Icons.person_outline,
                                  (val) => setState(() => _filterRole = val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFilterChip(
                                  'KYC',
                                  _filterKyc,
                                  ['all', 'pending', 'approved', 'rejected'],
                                  ['All', 'Pending', 'Approved', 'Rejected'],
                                  Icons.verified_user,
                                  (val) => setState(() => _filterKyc = val),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Users List
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: StreamBuilder(
                    stream: _usersRef.onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF104f22)),
                        );
                      }

                      if (snapshot.data!.snapshot.value == null) {
                        return _buildEmptyState();
                      }

                      var usersData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      var usersList = usersData.entries.where((entry) {
                        var user = entry.value as Map<dynamic, dynamic>;
                        if (_filterRole != 'all' && user['role'] != _filterRole) return false;
                        if (_filterKyc != 'all' && user['kycStatus'] != _filterKyc) return false;
                        if (_searchQuery.isNotEmpty) {
                          var name = (user['name'] ?? '').toString().toLowerCase();
                          var phone = (user['phone'] ?? '').toString().toLowerCase();
                          if (!name.contains(_searchQuery) && !phone.contains(_searchQuery)) return false;
                        }
                        return true;
                      }).toList();

                      if (usersList.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: usersList.length,
                        itemBuilder: (context, index) {
                          var userId = usersList[index].key;
                          var user = usersList[index].value as Map<dynamic, dynamic>;
                          return _buildUserCard(userId, user);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<String> values,
    List<String> labels,
    IconData icon,
    Function(String) onChanged,
  ) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF104f22)),
                const SizedBox(width: 8),
                Text(
                  labels[values.indexOf(currentValue)],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
      itemBuilder: (context) => List.generate(
        values.length,
        (index) => PopupMenuItem(
          value: values[index],
          child: Text(labels[index]),
        ),
      ),
    );
  }

  Widget _buildUserCard(String userId, Map<dynamic, dynamic> user) {
    final isBlocked = user['isBlocked'] == true;
    final kycStatus = user['kycStatus'] ?? 'pending';
    final role = user['role'] ?? 'farmer';
    final roleColor = role == 'farmer' ? Colors.green : Colors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // User Info Section
          InkWell(
            onTap: () => _viewUserProfile(userId, user),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Profile Image
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: roleColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: roleColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: roleColor.withOpacity(0.1),
                      backgroundImage: user['profileImage'] != null
                          ? NetworkImage(user['profileImage'])
                          : null,
                      child: user['profileImage'] == null
                          ? Icon(
                              role == 'farmer' ? Icons.agriculture : Icons.store,
                              size: 36,
                              color: roleColor,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user['name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E2E2E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              user['phone'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${user['village'] ?? 'N/A'}, ${user['state'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (role == 'trader' && user['mandiName'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.store, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  user['mandiName'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // KYC Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getKycColor(kycStatus).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getKycColor(kycStatus).withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      kycStatus.toUpperCase(),
                      style: TextStyle(
                        color: _getKycColor(kycStatus),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blocked Warning
          if (isBlocked)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.block, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'This user is blocked',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (kycStatus == 'pending') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateKycStatus(userId, 'approved'),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Approve', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateKycStatus(userId, 'rejected'),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Reject', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleBlockUser(userId, isBlocked),
                    icon: Icon(
                      isBlocked ? Icons.lock_open : Icons.block,
                      size: 16,
                    ),
                    label: Text(
                      isBlocked ? 'Unblock' : 'Block',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isBlocked ? Colors.orange : Colors.grey[700],
                      side: BorderSide(
                        color: isBlocked ? Colors.orange : Colors.grey[400]!,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Color _getKycColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _updateKycStatus(String userId, String status) async {
    await _usersRef.child(userId).update({
      'kycStatus': status,
      'updatedAt': ServerValue.timestamp,
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KYC status updated to $status'),
          backgroundColor: const Color(0xFF104f22),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _toggleBlockUser(String userId, bool isBlocked) async {
    await _usersRef.child(userId).update({
      'isBlocked': !isBlocked,
      'updatedAt': ServerValue.timestamp,
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBlocked ? 'User unblocked successfully' : 'User blocked successfully'),
          backgroundColor: isBlocked ? Colors.orange : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _viewUserProfile(String userId, Map<dynamic, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserProfileBottomSheet(userId: userId, userData: user),
    );
  }
}

class UserProfileBottomSheet extends StatelessWidget {
  final String userId;
  final Map<dynamic, dynamic> userData;

  const UserProfileBottomSheet({
    Key? key,
    required this.userId,
    required this.userData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final role = userData['role'] ?? 'farmer';
    final canMakeAdmin = role == 'farmer' || role == 'trader';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.green.shade100,
                          backgroundImage: userData['profileImage'] != null
                              ? NetworkImage(userData['profileImage'])
                              : null,
                          child: userData['profileImage'] == null
                              ? Icon(Icons.person, size: 40, color: Colors.green.shade700)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData['name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoTile(Icons.phone, 'Phone', userData['phone'] ?? 'N/A'),
                    _buildInfoTile(Icons.location_on, 'Village', userData['village'] ?? 'N/A'),
                    _buildInfoTile(Icons.map, 'State', userData['state'] ?? 'N/A'),
                    if (role == 'trader' && userData['mandiName'] != null)
                      _buildInfoTile(Icons.store, 'Mandi', userData['mandiName']),
                    const SizedBox(height: 24),
                    if (canMakeAdmin)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _makeAdmin(context, userId, userData);
                          },
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Make Admin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makeAdmin(BuildContext context, String userId, Map<dynamic, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.purple),
            SizedBox(width: 12),
            Text('Make Admin'),
          ],
        ),
        content: Text(
          'Are you sure you want to make "${user['name']}" an admin? This will give them full access to the admin panel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseDatabase.instance.ref('users').child(userId).update({
        'role': 'Admin',
        'updatedAt': ServerValue.timestamp,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User promoted to Admin successfully'),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

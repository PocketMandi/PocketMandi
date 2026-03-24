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
      appBar: AppBar(
        title: const Text('Users Management'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF104f22), Color(0xFF1a7a33)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          StreamBuilder(
            stream: _usersRef.onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> statsSnapshot) {
              if (!statsSnapshot.hasData || statsSnapshot.data!.snapshot.value == null) {
                return const SizedBox();
              }

              var usersData = statsSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              var totalUsers = usersData.length;
              var farmers = usersData.values.where((u) => u['role'] == 'farmer').length;
              var traders = usersData.values.where((u) => u['role'] == 'trader').length;
              var pendingKyc = usersData.values.where((u) => u['kycStatus'] == 'pending').length;

              return Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Total', totalUsers.toString(), Icons.people, Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard('Farmers', farmers.toString(), Icons.agriculture, Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard('Traders', traders.toString(), Icons.store, Colors.orange),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard('Pending', pendingKyc.toString(), Icons.pending, Colors.red),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _filterRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'farmer', child: Text('Farmers')),
                        DropdownMenuItem(value: 'trader', child: Text('Traders')),
                      ],
                      onChanged: (val) => setState(() => _filterRole = val!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _filterKyc,
                      decoration: const InputDecoration(
                        labelText: 'KYC',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: Icon(Icons.verified_user, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (val) => setState(() => _filterKyc = val!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _usersRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No users found'));
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
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: usersList.length,
                  itemBuilder: (context, index) {
                    var userId = usersList[index].key;
                    var user = usersList[index].value as Map<dynamic, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              user['role'] == 'farmer' ? Colors.green.shade50 : Colors.blue.shade50,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: user['role'] == 'farmer' ? Colors.green : Colors.blue,
                                        width: 3,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundImage: user['profileImage'] != null
                                          ? NetworkImage(user['profileImage'])
                                          : null,
                                      child: user['profileImage'] == null
                                          ? Icon(
                                              user['role'] == 'farmer' ? Icons.agriculture : Icons.store,
                                              size: 32,
                                              color: user['role'] == 'farmer' ? Colors.green : Colors.blue,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name'] ?? 'N/A',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              user['phone'] ?? 'N/A',
                                              style: TextStyle(color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: user['role'] == 'farmer' ? Colors.green : Colors.blue,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            user['role']?.toString().toUpperCase() ?? 'N/A',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getKycColor(user['kycStatus']),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getKycColor(user['kycStatus']).withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      user['kycStatus']?.toString().toUpperCase() ?? 'PENDING',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${user['village'] ?? 'N/A'}, ${user['state'] ?? 'N/A'}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                              if (user['role'] == 'trader') ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.store, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Mandi: ${user['mandiName'] ?? 'N/A'}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ],
                              if (user['isBlocked'] == true) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.block, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        'This user is blocked',
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (user['kycStatus'] == 'pending') ...[
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateKycStatus(userId, 'approved'),
                                        icon: const Icon(Icons.check_circle, size: 18),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateKycStatus(userId, 'rejected'),
                                        icon: const Icon(Icons.cancel, size: 18),
                                        label: const Text('Reject'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _toggleBlockUser(userId, user['isBlocked'] ?? false),
                                      icon: Icon(
                                        user['isBlocked'] == true ? Icons.lock_open : Icons.block,
                                        size: 18,
                                      ),
                                      label: Text(user['isBlocked'] == true ? 'Unblock' : 'Block'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: user['isBlocked'] == true
                                            ? Colors.orange
                                            : Colors.grey[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('KYC status updated to $status')),
    );
  }

  Future<void> _toggleBlockUser(String userId, bool isBlocked) async {
    await _usersRef.child(userId).update({
      'isBlocked': !isBlocked,
      'updatedAt': ServerValue.timestamp,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isBlocked ? 'User unblocked' : 'User blocked')),
    );
  }
}

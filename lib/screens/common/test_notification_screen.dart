import 'package:flutter/material.dart';
import 'package:poket_mandi/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class BroadcastNotificationScreen extends StatefulWidget {
  const BroadcastNotificationScreen({Key? key}) : super(key: key);

  @override
  State<BroadcastNotificationScreen> createState() => _BroadcastNotificationScreenState();
}

class _BroadcastNotificationScreenState extends State<BroadcastNotificationScreen> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final searchController = TextEditingController();
  bool isSending = false;
  String selectedAudience = 'all_users';
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  List<String> selectedUserIds = [];
  bool isLoadingUsers = false;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    // Don't load users initially, only when needed
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (allUsers.isNotEmpty) return; // Don't reload if already loaded
    
    setState(() => isLoadingUsers = true);
    try {
      final users = await NotificationService.getAllUsers(limit: 200); // Limit initial load
      setState(() {
        allUsers = users;
        filteredUsers = users;
        isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => isLoadingUsers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _searchUsers(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        setState(() => filteredUsers = allUsers);
        return;
      }
      
      setState(() => isLoadingUsers = true);
      try {
        final searchResults = await NotificationService.searchUsers(query);
        setState(() {
          filteredUsers = searchResults;
          isLoadingUsers = false;
        });
      } catch (e) {
        setState(() => isLoadingUsers = false);
      }
    });
  }

  Future<void> _sendBroadcastNotification() async {
    if (titleController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and message')),
      );
      return;
    }

    if (selectedAudience == 'specific_users' && selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    setState(() => isSending = true);

    try {
      final title = titleController.text.trim();
      final body = bodyController.text.trim();
      final data = {'type': 'broadcast', 'timestamp': DateTime.now().toString()};

      switch (selectedAudience) {
        case 'all_users':
          await NotificationService.sendNotificationToAllUsers(
            title: title,
            body: body,
            type: 'broadcast',
            data: data,
          );
          break;
        case 'farmers':
          await NotificationService.sendNotificationToFarmers(
            title: title,
            body: body,
            type: 'broadcast',
            data: data,
          );
          break;
        case 'traders':
          await NotificationService.sendNotificationToTraders(
            title: title,
            body: body,
            type: 'broadcast',
            data: data,
          );
          break;
        case 'specific_users':
          for (String userId in selectedUserIds) {
            await NotificationService.sendNotificationToUser(
              userId: userId,
              title: title,
              body: body,
              type: 'broadcast',
              data: data,
            );
          }
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast notification sent successfully!'),
            backgroundColor: Color(0xFF104f22),
          ),
        );
        titleController.clear();
        bodyController.clear();
        setState(() {
          selectedUserIds.clear();
          selectedAudience = 'all_users';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  Widget _buildAudienceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Audience',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E2E2E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('All Users (Farmers & Traders)'),
                value: 'all_users',
                groupValue: selectedAudience,
                onChanged: (value) => setState(() => selectedAudience = value!),
                activeColor: const Color(0xFF104f22),
              ),
              RadioListTile<String>(
                title: const Text('All Farmers'),
                value: 'farmers',
                groupValue: selectedAudience,
                onChanged: (value) => setState(() => selectedAudience = value!),
                activeColor: const Color(0xFF104f22),
              ),
              RadioListTile<String>(
                title: const Text('All Traders'),
                value: 'traders',
                groupValue: selectedAudience,
                onChanged: (value) => setState(() => selectedAudience = value!),
                activeColor: const Color(0xFF104f22),
              ),
              RadioListTile<String>(
                title: const Text('Specific Users'),
                value: 'specific_users',
                groupValue: selectedAudience,
                onChanged: (value) => setState(() => selectedAudience = value!),
                activeColor: const Color(0xFF104f22),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserSelector() {
    if (selectedAudience != 'specific_users') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Select Users',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E2E2E),
          ),
        ),
        const SizedBox(height: 12),
        // Search field
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search users by name or phone',
            filled: true,
            fillColor: const Color(0xFFF3F3F3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF104f22),
            ),
          ),
          onChanged: _searchUsers,
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            searchController.text.isEmpty 
                                ? 'Start typing to search users'
                                : 'No users found',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (allUsers.isEmpty)
                            TextButton(
                              onPressed: _loadUsers,
                              child: const Text('Load Users'),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isSelected = selectedUserIds.contains(user['id']);
                        return CheckboxListTile(
                          title: Text('${user['name']} (${user['role']})'),
                          subtitle: Text(user['phone']),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedUserIds.add(user['id']);
                              } else {
                                selectedUserIds.remove(user['id']);
                              }
                            });
                          },
                          activeColor: const Color(0xFF104f22),
                        );
                      },
                    ),
        ),
        if (selectedUserIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Text(
                  '${selectedUserIds.length} user(s) selected',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF104f22),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => selectedUserIds.clear());
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF104f22), Color(0xFF1a7a33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Broadcast Notifications',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Send messages to farmers and traders',
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
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notification Title',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Enter notification title',
                            filled: true,
                            fillColor: const Color(0xFFF3F3F3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.title,
                              color: Color(0xFF104f22),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Notification Message',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: bodyController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enter notification message',
                            filled: true,
                            fillColor: const Color(0xFFF3F3F3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.message,
                              color: Color(0xFF104f22),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildAudienceSelector(),
                        _buildUserSelector(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSending ? null : _sendBroadcastNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF104f22),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSending
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Send Broadcast Notification',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF104f22).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF104f22).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF104f22),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Testing Tips:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF104f22),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Make sure notifications are enabled in settings\n• Test will send notification to yourself\n• Check notification panel after sending',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

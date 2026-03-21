import 'package:flutter/material.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header with gradient
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF104f22), Color(0xFF0d3f1c)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // App bar
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Policies & Guidelines',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Tab bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFF8F9FA)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: const Color(0xFF104f22),
                        unselectedLabelColor: Colors.white.withOpacity(0.9),
                        labelStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        indicatorPadding: const EdgeInsets.all(4),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.privacy_tip_outlined, size: 14),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Privacy',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 14),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Guidelines',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.security_outlined, size: 14),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Data Policy',
                                    overflow: TextOverflow.ellipsis,
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
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPrivacyPolicy(),
                _buildCommunityGuidelines(),
                _buildDataPolicy(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicy() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Privacy Policy', Icons.privacy_tip_outlined),
              const SizedBox(height: 20),
              
              _buildPolicySection(
                '1. Introduction',
                'Poketmandi respects your privacy and is committed to protecting user data.',
              ),
              
              _buildPolicySection(
                '2. Information We Collect',
                '• Personal Information: Name, phone number, email, and address.\n'
                '• Business Information: Farm or trading details.\n'
                '• Usage Data: App activity and interaction data.',
              ),
              
              _buildPolicySection(
                '3. How We Use Information',
                'To operate the marketplace, improve services, communicate with users, and ensure secure transactions.',
              ),
              
              _buildPolicySection(
                '4. Data Sharing',
                'Poketmandi may share information with service providers such as payment gateways, logistics partners, or legal authorities if required by law.',
              ),
              
              _buildPolicySection(
                '5. Data Security',
                'We use reasonable security measures to protect user data from unauthorized access.',
              ),
              
              _buildPolicySection(
                '6. User Rights',
                'Users may request access, correction, or deletion of their personal data.',
              ),
              
              _buildPolicySection(
                '7. Policy Updates',
                'Poketmandi may update this policy periodically.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityGuidelines() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Community Guidelines', Icons.people_outline),
              const SizedBox(height: 20),
              
              _buildPolicySection(
                'Our Mission',
                'Poketmandi aims to create a fair and transparent agricultural marketplace connecting farmers and buyers.',
              ),
              
              _buildPolicySection(
                'Respectful Conduct',
                'Users must communicate respectfully and avoid abusive language or harassment.',
              ),
              
              _buildPolicySection(
                'Honest Listings',
                'All product listings must accurately represent the quality, quantity, and type of agricultural produce.',
              ),
              
              _buildPolicySection(
                'Prohibited Activities',
                'Fraud, fake listings, manipulation of prices, and illegal trading activities are strictly prohibited.',
              ),
              
              _buildPolicySection(
                'Dispute Resolution',
                'Users are encouraged to resolve disputes amicably. Poketmandi may assist when possible.',
              ),
              
              _buildPolicySection(
                'Enforcement',
                'Violation of these guidelines may result in warnings, suspension, or permanent removal from the platform.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataPolicy() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('User Data Policy', Icons.security_outlined),
              const SizedBox(height: 20),
              
              _buildPolicySection(
                'Purpose',
                'This policy explains how Poketmandi collects, processes, and manages user data.',
              ),
              
              _buildPolicySection(
                'Data Types',
                '• Personal Data: Name, phone number, and contact information.\n'
                '• Transaction Data: Product listings and transaction records.\n'
                '• Device Data: App usage and device identifiers.',
              ),
              
              _buildPolicySection(
                'Data Usage',
                'User data is used for account management, platform functionality, analytics, and fraud prevention.',
              ),
              
              _buildPolicySection(
                'Data Retention',
                'Poketmandi retains user data only as long as necessary for service delivery or legal compliance.',
              ),
              
              _buildPolicySection(
                'Data Protection',
                'Security measures such as encryption and controlled access are used to protect user data.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF104f22).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF104f22),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF104f22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
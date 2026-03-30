import 'package:flutter/material.dart';

void showFarmerCropDetails(BuildContext context, Map<dynamic, dynamic> crop) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF104f22), Color(0xFF1a7a33)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.agriculture, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crop Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          crop['cropType'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (crop['imageUrl'] != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          crop['imageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildDetailSection('Crop Information', [
                      _buildDetailRow(Icons.agriculture, 'Crop Type', crop['cropType'] ?? 'N/A'),
                      _buildDetailRow(Icons.shopping_basket, 'Quantity', '${crop['quantity'] ?? 'N/A'} ${crop['unit'] ?? ''}'),
                      _buildDetailRow(Icons.currency_rupee, 'Price', '₹${crop['pricePerUnit'] ?? 'N/A'}/${crop['unit'] ?? 'unit'}'),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Farmer Information', [
                      _buildDetailRow(Icons.person, 'Name', crop['userName'] ?? 'N/A'),
                      _buildDetailRow(Icons.phone, 'Phone', crop['userPhone'] ?? 'N/A'),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Additional Information', [
                      _buildDetailRow(Icons.access_time, 'Listed On', _formatDate(crop['createdAt'])),
                      _buildDetailRow(Icons.info, 'Status', crop['status'] ?? 'pending'),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildDetailSection(String title, List<Widget> children) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF104f22),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: children,
        ),
      ),
    ],
  );
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2E2E2E),
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

String _formatDate(dynamic timestamp) {
  if (timestamp == null) return 'N/A';
  try {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    return '${date.day}/${date.month}/${date.year}';
  } catch (e) {
    return 'N/A';
  }
}

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void showTraderRequestDetails(BuildContext context, Map<dynamic, dynamic> request) {
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
                  const Icon(Icons.store, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trader Request Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          request['cropName'] ?? 'N/A',
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
                    if (request['imageUrl'] != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          request['imageUrl'],
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
                    if (request['videoUrl'] != null) ...[
                      VideoPlayerWidget(videoUrl: request['videoUrl']),
                      const SizedBox(height: 20),
                    ],
                    _buildDetailSection('Crop Information', [
                      _buildDetailRow(Icons.grass, 'Crop Name', request['cropName'] ?? 'N/A'),
                      _buildDetailRow(Icons.shopping_basket, 'Quantity', '${request['quantity'] ?? 'N/A'} ${request['unit'] ?? ''}'),
                      _buildDetailRow(Icons.currency_rupee, 'Expected Price', '₹${request['expectedPrice'] ?? request['pricePerUnit'] ?? 'N/A'}/${request['unit'] ?? 'unit'}'),
                      if (request['qualityGrades'] != null)
                        _buildDetailRow(Icons.star, 'Quality Grades', (request['qualityGrades'] as List).join(', ')),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Trader Information', [
                      _buildDetailRow(Icons.person, 'Name', request['userName'] ?? 'N/A'),
                      _buildDetailRow(Icons.phone, 'Phone', request['userPhone'] ?? 'N/A'),
                      _buildDetailRow(Icons.store, 'Mandi', request['mandiName'] ?? (request['location']?['mandiName'] ?? 'N/A')),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Location Details', [
                      _buildDetailRow(Icons.location_city, 'State', request['location']?['state'] ?? 'N/A'),
                      _buildDetailRow(Icons.location_on, 'Village', request['location']?['village'] ?? 'N/A'),
                      _buildDetailRow(Icons.home, 'Delivery Address', request['selectedLocation'] ?? request['location']?['deliveryAddress'] ?? 'N/A'),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Additional Information', [
                      _buildDetailRow(Icons.access_time, 'Requested On', _formatDate(request['createdAt'])),
                      _buildDetailRow(Icons.info, 'Status', request['status'] ?? 'pending'),
                    ]),
                    if (request['message'] != null && request['message'].toString().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.message, size: 18, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Message',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              request['message'],
                              style: const TextStyle(fontSize: 14, color: Color(0xFF2E2E2E)),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('Failed to load video', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF104f22)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
              size: 64,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
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

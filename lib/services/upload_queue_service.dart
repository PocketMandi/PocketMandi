import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';
import 'package:poket_mandi/services/notification_service.dart';
import 'dart:convert';

class UploadQueueService {
  static const String _queueKey = 'upload_queue';

  /// Add upload to queue
  static Future<void> addToQueue({
    required String userId,
    required String recordId,
    required String recordPath,
    required int timestamp,
    String? imagePath,
    String? videoPath,
    String? userName,
    String? cropName,
    String? notificationType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey) ?? '[]';
    final List<dynamic> queue = jsonDecode(queueJson);

    queue.add({
      'userId': userId,
      'recordId': recordId,
      'recordPath': recordPath,
      'timestamp': timestamp,
      'imagePath': imagePath,
      'videoPath': videoPath,
      'userName': userName,
      'cropName': cropName,
      'notificationType': notificationType,
      'retryCount': 0,
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    });

    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  /// Process all pending uploads
  static Future<void> processPendingUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey) ?? '[]';
    final List<dynamic> queue = jsonDecode(queueJson);

    if (queue.isEmpty) return;

    print('📦 Processing ${queue.length} pending uploads...');

    final List<dynamic> remainingQueue = [];

    for (var item in queue) {
      try {
        final success = await _processUpload(item);
        if (!success) {
          // Keep in queue if failed and retry count < 3
          if ((item['retryCount'] ?? 0) < 3) {
            item['retryCount'] = (item['retryCount'] ?? 0) + 1;
            remainingQueue.add(item);
          } else {
            // Mark as failed after 3 retries
            await _markAsFailed(item);
          }
        }
      } catch (e) {
        print('Upload error: $e');
        if ((item['retryCount'] ?? 0) < 3) {
          item['retryCount'] = (item['retryCount'] ?? 0) + 1;
          remainingQueue.add(item);
        } else {
          await _markAsFailed(item);
        }
      }
    }

    // Save remaining queue
    await prefs.setString(_queueKey, jsonEncode(remainingQueue));
    print('✅ Upload processing complete. ${remainingQueue.length} items remaining.');
  }

  /// Process single upload
  static Future<bool> _processUpload(Map<String, dynamic> item) async {
    try {
      String? imageUrl;
      String? videoUrl;

      final ref = FirebaseDatabase.instance.ref(item['recordPath']);

      // Upload image
      if (item['imagePath'] != null) {
        final imageFile = File(item['imagePath']);
        if (await imageFile.exists()) {
          final imageRef = FirebaseStorage.instance
              .ref()
              .child('crop_images/${item['userId']}_${item['timestamp']}.jpg');

          await imageRef.putFile(imageFile).timeout(
            const Duration(seconds: 60),
          );
          imageUrl = await imageRef.getDownloadURL();
        }
      }

      // Upload video
      if (item['videoPath'] != null) {
        final videoFile = File(item['videoPath']);
        if (await videoFile.exists()) {
          File videoToUpload = videoFile;

          // Compress video
          try {
            final info = await VideoCompress.compressVideo(
              videoFile.path,
              quality: VideoQuality.LowQuality,
              deleteOrigin: false,
              includeAudio: true,
            );
            if (info != null && info.file != null) {
              videoToUpload = info.file!;
            }
          } catch (e) {
            print('Compression failed: $e');
          }

          final videoRef = FirebaseStorage.instance
              .ref()
              .child('crop_videos/${item['userId']}_${item['timestamp']}.mp4');

          await videoRef.putFile(videoToUpload).timeout(
            const Duration(seconds: 120),
          );
          videoUrl = await videoRef.getDownloadURL();
        }
      }

      // Update database
      await ref.update({
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
        'uploadStatus': 'completed',
        'updatedAt': ServerValue.timestamp,
      });

      // Send notification
      if (item['notificationType'] != null && item['userName'] != null) {
        await NotificationService.sendNotificationToAdmins(
          title: item['notificationType'] == 'crop_order'
              ? 'New Crop Order'
              : 'New Crop Request',
          body: '${item['userName']} ${item['notificationType'] == 'crop_order' ? 'ordered' : 'requested'} ${item['cropName'] ?? 'crop'}',
          type: item['notificationType'],
          data: {'orderId': item['recordId']},
        );
      }

      print('✅ Upload completed: ${item['recordId']}');
      return true;
    } catch (e) {
      print('❌ Upload failed: ${item['recordId']} - $e');
      return false;
    }
  }

  /// Mark upload as failed
  static Future<void> _markAsFailed(Map<String, dynamic> item) async {
    try {
      final ref = FirebaseDatabase.instance.ref(item['recordPath']);
      await ref.update({
        'uploadStatus': 'failed',
        'uploadError': 'Failed after 3 retries',
        'updatedAt': ServerValue.timestamp,
      });
      print('❌ Marked as failed: ${item['recordId']}');
    } catch (e) {
      print('Error marking as failed: $e');
    }
  }

  /// Retry specific upload
  static Future<bool> retryUpload(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey) ?? '[]';
    final List<dynamic> queue = jsonDecode(queueJson);

    final item = queue.firstWhere(
      (item) => item['recordId'] == recordId,
      orElse: () => null,
    );

    if (item == null) return false;

    // Update status to uploading
    try {
      final ref = FirebaseDatabase.instance.ref(item['recordPath']);
      await ref.update({
        'uploadStatus': 'uploading',
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating status: $e');
    }

    return await _processUpload(item);
  }

  /// Clear completed uploads from queue
  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  /// Get pending upload count
  static Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey) ?? '[]';
    final List<dynamic> queue = jsonDecode(queueJson);
    return queue.length;
  }
}

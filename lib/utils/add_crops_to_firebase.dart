import 'package:firebase_database/firebase_database.dart';

Future<void> addAllCropsToFirebase() async {
  try {
    print('Starting to add crops to Firebase...');
    
    final crops = [
      {"id": 1, "name": "Potato (आलू)"},
      {"id": 2, "name": "Tomato (टमाटर)"},
      {"id": 3, "name": "Onion (प्याज़)"},
      {"id": 4, "name": "Cauliflower (फूलगोभी)"},
      {"id": 5, "name": "Cabbage (पत्तागोभी)"},
      {"id": 6, "name": "Brinjal / Eggplant (बैंगन)"},
      {"id": 7, "name": "Peas (मटर)"},
      {"id": 8, "name": "Okra / Lady Finger (भिंडी)"},
      {"id": 9, "name": "Bitter Gourd (करेला)"},
      {"id": 10, "name": "Bottle Gourd (लौकी)"},
      {"id": 11, "name": "Ridge Gourd (तोरी / तुरई)"},
      {"id": 12, "name": "Pumpkin (कद्दू)"},
      {"id": 13, "name": "Capsicum (शिमला मिर्च)"},
      {"id": 14, "name": "Green Chili (हरी मिर्च)"},
      {"id": 15, "name": "Ginger (अदरक)"},
      {"id": 16, "name": "Garlic (लहसुन)"},
      {"id": 17, "name": "Beetroot (चुकंदर)"},
      {"id": 18, "name": "Amla (आंवला)"},
      {"id": 19, "name": "Avocado (एवोकाडो)"},
      {"id": 20, "name": "Banana (केला)"},
      {"id": 21, "name": "Beans (सेम)"},
      {"id": 22, "name": "Broccoli (ब्रोकोली)"},
      {"id": 23, "name": "Coconut (नारियल)"},
      {"id": 24, "name": "Cucumber (खीरा)"},
      {"id": 25, "name": "Grapes (अंगूर)"},
      {"id": 26, "name": "Guava (अमरूद)"},
      {"id": 27, "name": "Jackfruit (कटहल)"},
      {"id": 28, "name": "Lemon (नींबू)"},
      {"id": 29, "name": "Litchi (लीची)"},
      {"id": 30, "name": "Maize (Corn) (मक्का)"},
      {"id": 31, "name": "Mango (आम)"},
      {"id": 32, "name": "Orange (संतरा)"},
      {"id": 33, "name": "Papaya (पपीता)"},
      {"id": 34, "name": "Peanut (Groundnut) (मूंगफली)"},
      {"id": 35, "name": "Pomegranate (अनार)"},
      {"id": 36, "name": "Sweet Potato (शकरकंद)"},
      {"id": 37, "name": "Turmeric (हल्दी)"},
      {"id": 38, "name": "Watermelon (तरबूज)"},
    ];

    final ref = FirebaseDatabase.instance.ref('allcrops');

    for (var crop in crops) {
      await ref.child(crop['id'].toString()).set(crop);
      print('Added: ${crop['name']}');
    }

    print('✅ All crops added successfully!');
  } catch (e) {
    print('❌ Error adding crops: $e');
  }
}

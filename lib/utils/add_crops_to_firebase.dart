import 'package:firebase_database/firebase_database.dart';

Future<void> addAllCropsToFirebase() async {
  try {
    print('Starting to add crops to Firebase...');

    final crops = [
      {
        "id": 1,
        "name": "Tomato (टमाटर)",
        "image":
            "https://firebasestorage.googleapis.com/v0/b/mypocketmandi.firebasestorage.app/o/crop_images%2F-On_vSYTLpMotLFhIHPC_1773385472978.jpg?alt=media&token=60ef57a0-36dc-4aa1-a88c-0126f1972b0d",
        "category": "vegetable",
      },
      {
        "id": 2,
        "name": "Brinjal / Eggplant (बैंगन)",
        "image":
            "https://firebasestorage.googleapis.com/v0/b/mypocketmandi.firebasestorage.app/o/crop_images%2FWhatsApp%20Image%202026-03-14%20at%2010.14.37%20PM%20(1).jpeg?alt=media&token=117c2be6-5c9a-467a-b1db-7d6d901f2cff",
        "category": "vegetable",
      },
      {
        "id": 3,
        "name": "Bottle Gourd (लौकी)",
        "image":
            "https://firebasestorage.googleapis.com/v0/b/mypocketmandi.firebasestorage.app/o/crop_images%2FWhatsApp%20Image%202026-03-14%20at%2010.14.37%20PM.jpeg?alt=media&token=77d7747a-fbf2-42ca-a4d4-64fa7b83bef3",
        "category": "vegetable",
      },
      {
        "id": 4,
        "name": "Green Chili (हरी मिर्च)",
        "image":
            "https://firebasestorage.googleapis.com/v0/b/mypocketmandi.firebasestorage.app/o/crop_images%2FWhatsApp%20Image%202026-03-14%20at%2010.15.05%20PM%20(2).jpeg?alt=media&token=24d8232e-e3f8-414b-89d3-ba5c922c195f",
        "category": "vegetable",
      },
      {
        "id": 5,
        "name": "Capsicum (शिमला मिर्च)",
        "image":
            "https://firebasestorage.googleapis.com/v0/b/mypocketmandi.firebasestorage.app/o/crop_images%2FWhatsApp%20Image%202026-03-14%20at%2010.14.37%20PM%20(2).jpeg?alt=media&token=18e5cf52-a330-44b5-8062-9c47dc0e8315",
        "category": "vegetable",
      },
      {
        "id": 6,
        "name": "Cucumber (खीरा)",
        "image":
            "https://firebasestorage.googleapis.com/v0/b/mypocketmandi.firebasestorage.app/o/crop_images%2FWhatsApp%20Image%202026-03-14%20at%2010.14.37%20PM%20(3).jpeg?alt=media&token=4bf3a0e5-ba56-41d9-a402-1f0256a80db5",
        "category": "vegetable",
      },
      {
        "id": 7,
        "name": "Watermelon (तरबूज)",
        "image":
            "https://firebasestorage.googleapis.com/v0/b/mypocketmandi.firebasestorage.app/o/crop_images%2FWhatsApp%20Image%202026-03-14%20at%2010.15.05%20PM%20(1).jpeg?alt=media&token=a1c4d1ff-a9d7-497c-a38a-5eb1c6612f25",
        "category": "fruit",
      },
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

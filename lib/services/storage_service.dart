import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw 'Failed to pick image. Please try again.';
    }
  }

  // Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw 'Failed to take photo. Please try again.';
    }
  }

  // Upload order image
  Future<String> uploadOrderImage(XFile imageFile, String userId) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      String filePath = 'orders/$userId/$fileName';

      // Create reference to storage location
      Reference ref = _storage.ref().child(filePath);

      // Upload file
      File file = File(imageFile.path);
      UploadTask uploadTask = ref.putFile(file);

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload image. Please try again.';
    }
  }

  // Upload user profile image
  Future<String> uploadProfileImage(XFile imageFile, String userId) async {
    try {
      String fileName = 'profile_$userId.jpg';
      String filePath = 'profiles/$userId/$fileName';

      // Create reference to storage location
      Reference ref = _storage.ref().child(filePath);

      // Upload file
      File file = File(imageFile.path);
      UploadTask uploadTask = ref.putFile(file);

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload profile image. Please try again.';
    }
  }

  // Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Silently fail - image might not exist
    }
  }

  // Show image source selection dialog
  Future<XFile?> pickImage() async {
    // This method can be called from UI to show options
    // For now, we'll default to gallery
    // In the UI, you can show a dialog to choose between camera and gallery
    return await pickImageFromGallery();
  }
}

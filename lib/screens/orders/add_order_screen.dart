import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/storage_service.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _storageService = StorageService();

  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _itemNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      XFile? image;
      if (source == ImageSource.camera) {
        image = await _storageService.pickImageFromCamera();
      } else {
        image = await _storageService.pickImageFromGallery();
      }

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadOrderImage(
          _selectedImage!,
          authProvider.user!.id,
        );
      }

      // Create order
      final success = await orderProvider.createOrder(
        userId: authProvider.user!.id,
        userName: authProvider.user!.name,
        itemName: _itemNameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
        imageUrl: imageUrl,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Failed to add order'),
            backgroundColor: Colors.red,
          ),
        );
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
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Order'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _isUploading ? null : _showImageSourceDialog,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photo (Optional)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Item Name
              TextFormField(
                controller: _itemNameController,
                enabled: !_isUploading,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  prefixIcon: Icon(Icons.restaurant_menu),
                  hintText: 'e.g., Pancakes with syrup',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                enabled: !_isUploading,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'e.g., 12.50',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                enabled: !_isUploading,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.numbers),
                  hintText: 'e.g., 1',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isUploading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Adding Order...'),
                        ],
                      )
                    : const Text('Add Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/restaurant.dart';

class AddRestaurantToGroupScreen extends StatefulWidget {
  final String groupId;

  const AddRestaurantToGroupScreen({super.key, required this.groupId});

  @override
  State<AddRestaurantToGroupScreen> createState() =>
      _AddRestaurantToGroupScreenState();
}

class _AddRestaurantToGroupScreenState
    extends State<AddRestaurantToGroupScreen> {
  bool _showCustomForm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Restaurant'),
      ),
      body: _showCustomForm
          ? _CustomRestaurantForm(
              groupId: widget.groupId,
              onCancel: () {
                setState(() {
                  _showCustomForm = false;
                });
              },
            )
          : _RestaurantSelection(
              groupId: widget.groupId,
              onAddCustom: () {
                setState(() {
                  _showCustomForm = true;
                });
              },
            ),
    );
  }
}

class _RestaurantSelection extends StatefulWidget {
  final String groupId;
  final VoidCallback onAddCustom;

  const _RestaurantSelection({
    required this.groupId,
    required this.onAddCustom,
  });

  @override
  State<_RestaurantSelection> createState() => _RestaurantSelectionState();
}

class _RestaurantSelectionState extends State<_RestaurantSelection> {
  String? _addingRestaurantId;

  Future<void> _addRestaurantToGroup(
    BuildContext context,
    Restaurant restaurant,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in')),
      );
      return;
    }

    setState(() {
      _addingRestaurantId = restaurant.id;
    });

    final success = await groupProvider.addRestaurant(
      groupId: widget.groupId,
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      restaurantDescription: restaurant.description,
      restaurantApiUrl: restaurant.apiUrl,
      restaurantImageUrl: restaurant.imageUrl,
      addedBy: authProvider.user!.id,
      addedByName: authProvider.user!.name,
    );

    if (mounted) {
      setState(() {
        _addingRestaurantId = null;
      });
    }

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant added successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                groupProvider.errorMessage ?? 'Failed to add restaurant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context);
    final restaurants = restaurantProvider.restaurants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a Restaurant',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose from available restaurants or add a custom one',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Restaurant list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              final isAdding = _addingRestaurantId == restaurant.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: restaurant.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            restaurant.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.restaurant, size: 40),
                          ),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.restaurant),
                        ),
                  title: Text(
                    restaurant.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: restaurant.description != null
                      ? Text(
                          restaurant.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: isAdding
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle, color: Colors.green),
                  onTap: isAdding ? null : () => _addRestaurantToGroup(context, restaurant),
                  enabled: !isAdding,
                ),
              );
            },
          ),
        ),

        // Add custom restaurant button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addingRestaurantId == null ? widget.onAddCustom : null,
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Restaurant'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomRestaurantForm extends StatefulWidget {
  final String groupId;
  final VoidCallback onCancel;

  const _CustomRestaurantForm({
    required this.groupId,
    required this.onCancel,
  });

  @override
  State<_CustomRestaurantForm> createState() => _CustomRestaurantFormState();
}

class _CustomRestaurantFormState extends State<_CustomRestaurantForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _apiUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _apiUrlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _addRestaurant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in')),
      );
      return;
    }

    final success = await groupProvider.addRestaurant(
      groupId: widget.groupId,
      restaurantId: DateTime.now().millisecondsSinceEpoch.toString(),
      restaurantName: _nameController.text.trim(),
      restaurantDescription: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      restaurantApiUrl: _apiUrlController.text.trim().isNotEmpty
          ? _apiUrlController.text.trim()
          : null,
      restaurantImageUrl: _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : null,
      addedBy: authProvider.user!.id,
      addedByName: authProvider.user!.name,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant added successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                groupProvider.errorMessage ?? 'Failed to add restaurant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button
            Row(
              children: [
                TextButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to list'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Custom Restaurant',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Restaurant name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                hintText: 'Enter restaurant name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a restaurant name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // API URL
            TextFormField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                labelText: 'Menu API URL (Optional)',
                hintText: 'https://api.example.com/menu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Image URL
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (Optional)',
                hintText: 'https://example.com/image.jpg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'About Custom Restaurants',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Custom restaurants are specific to this group\n'
                      '• Add a menu API URL if available\n'
                      '• Without API, members can add custom items',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Add button
            ElevatedButton(
              onPressed: groupProvider.isLoading ? null : _addRestaurant,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: groupProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Add Restaurant',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

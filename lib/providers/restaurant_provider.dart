import 'package:flutter/foundation.dart';
import '../models/restaurant.dart';
import '../models/menu_category.dart';
import '../models/modifier.dart';
import '../models/allergen.dart';
import '../services/restaurant_service.dart';

class RestaurantProvider extends ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  // Available restaurants
  final List<Restaurant> _restaurants = [
    Restaurant(
      id: '1',
      name: 'Shawerma House',
      apiUrl: 'https://cdn.getsolo.io/apps/production/5bGE93qdVUP-menu-9614.json',
      imageUrl: 'https://cdn.getsolo.io/175896048668d79b6608ebc_%D8%AA%D8%B7%D8%A8%D9%8A%D9%82-02.jpg',
      description: 'Best shawarma in town',
    ),
  ];

  // State
  Restaurant? _selectedRestaurant;
  List<MenuCategory> _categories = [];
  Map<int, ModifierGroup> _modifierGroups = {};
  Map<int, Modifier> _modifiers = {};
  Map<int, Allergen> _allergens = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Restaurant> get restaurants => _restaurants;
  Restaurant? get selectedRestaurant => _selectedRestaurant;
  List<MenuCategory> get categories => _categories;
  Map<int, ModifierGroup> get modifierGroups => _modifierGroups;
  Map<int, Modifier> get modifiers => _modifiers;
  Map<int, Allergen> get allergens => _allergens;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Select a restaurant and fetch its menu
  Future<void> selectRestaurant(Restaurant restaurant) async {
    _selectedRestaurant = restaurant;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final menuData = await _restaurantService.fetchMenuData(restaurant.apiUrl);
      _categories = menuData.categories;
      _modifierGroups = menuData.modifierGroups;
      _modifiers = menuData.modifiers;
      _allergens = menuData.allergens;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _categories = [];
      _modifierGroups = {};
      _modifiers = {};
      _allergens = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get modifiers for a modifier group
  List<Modifier> getModifiersForGroup(ModifierGroup group) {
    return group.modifierIds
        .where((id) => _modifiers.containsKey(id))
        .map((id) => _modifiers[id]!)
        .toList();
  }

  // Get allergens for an item
  List<Allergen> getAllergensForItem(List<int> allergenIds) {
    return allergenIds
        .where((id) => _allergens.containsKey(id))
        .map((id) => _allergens[id]!)
        .toList();
  }

  // Get modifier groups for an item
  List<ModifierGroup> getModifierGroupsForItem(List<int> groupIds) {
    return groupIds
        .where((id) => _modifierGroups.containsKey(id))
        .map((id) => _modifierGroups[id]!)
        .toList();
  }

  // Clear selection
  void clearSelection() {
    _selectedRestaurant = null;
    _categories = [];
    _modifierGroups = {};
    _modifiers = {};
    _allergens = {};
    _error = null;
    notifyListeners();
  }

  // Refresh menu data
  Future<void> refreshMenu() async {
    if (_selectedRestaurant != null) {
      await selectRestaurant(_selectedRestaurant!);
    }
  }
}

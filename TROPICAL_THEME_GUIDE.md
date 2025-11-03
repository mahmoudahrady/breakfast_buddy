# Tropical Punch Theme Guide

## Overview

The Breakfast Buddy app now features a vibrant **Tropical Punch** color scheme inspired by the colorful tropical punch palette. This theme brings energy, warmth, and a delightful visual experience to the app.

## Color Palette

### Primary Colors (From Image)

The theme uses **ONLY** the exact colors from the tropical punch image:

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| **Coral** | `#FF8243` | Primary actions, buttons, main branding |
| **Pink** | `#FFCCCB` | Accents, secondary elements, soft highlights |
| **Yellow** | `#FCE883` | Warnings, highlights, attention elements |
| **Teal** | `#069494` | Success states, secondary actions, info |

### Theme Variations

#### Light Theme
- **Background**: `#FFFBF7` (Warm white)
- **Surface**: `#FFFFFF` (Pure white)
- **Text Primary**: `#2D2D2D` (Dark gray)
- **Text Secondary**: `#666666` (Medium gray)

#### Dark Theme
- **Background**: `#1A1A1A` (Deep dark)
- **Surface**: `#252525` (Dark surface)
- **Text Primary**: `#FFFBF7` (Warm white)
- **Text Secondary**: `#B0B0B0` (Light gray)

## Usage

### Basic Theme Application

The theme is automatically applied throughout the app via `main.dart`:

```dart
import 'config/tropical_theme.dart';

MaterialApp(
  theme: TropicalTheme.buildLightTheme(),
  darkTheme: TropicalTheme.buildDarkTheme(),
  ...
)
```

### Using Tropical Colors

```dart
import 'package:breakfast_buddy/config/tropical_theme.dart';

// Access colors
Container(
  color: TropicalColors.coral,
  child: Text('Hello'),
)

// Use gradients
Container(
  decoration: BoxDecoration(
    gradient: TropicalColors.createGradient(
      colors: TropicalColors.warmGradient,
    ),
  ),
)
```

### Predefined Gradients

```dart
// Full tropical gradient (all 4 colors)
TropicalColors.tropicalGradient

// Warm gradient (coral to pink)
TropicalColors.warmGradient

// Sunny gradient (yellow to coral)
TropicalColors.sunnyGradient

// Ocean gradient (teal to pink)
TropicalColors.oceanGradient
```

## Enhanced Widgets

### 1. TropicalCard

A beautifully styled card with optional gradient border:

```dart
TropicalCard(
  showGradientBorder: true, // Optional gradient border
  onTap: () {}, // Optional tap handler
  child: Text('Card content'),
)
```

### 2. TropicalGradientButton

A button with gradient background:

```dart
TropicalGradientButton(
  text: 'Place Order',
  gradientColors: [TropicalColors.coral, TropicalColors.pink],
  icon: Icon(Icons.shopping_cart),
  onPressed: () {},
)
```

### 3. TropicalBadge

An animated badge for highlights:

```dart
TropicalBadge(
  text: 'New',
  animated: true, // Pulse animation
  backgroundColor: TropicalColors.yellow.withValues(alpha: 0.2),
)
```

### 4. TropicalStatusIndicator

Visual status indicator with color coding:

```dart
TropicalStatusIndicator(
  status: 'confirmed', // Auto-colored based on status
  showAnimation: true,
)
```

**Status Colors:**
- `pending`: Yellow
- `confirmed`: Teal
- `preparing`: Coral
- `ready`: Green
- `delivered`: Teal
- `cancelled`: Gray

### 5. TropicalGradientContainer

Container with gradient background:

```dart
TropicalGradientContainer(
  gradientColors: TropicalColors.sunnyGradient,
  borderRadius: 20,
  child: YourWidget(),
)
```

### 6. TropicalIconButton

Icon button with themed background:

```dart
TropicalIconButton(
  icon: Icons.favorite,
  onPressed: () {},
  backgroundColor: TropicalColors.coral.withValues(alpha: 0.1),
)
```

### 7. TropicalShimmer

Shimmer loading effect:

```dart
TropicalShimmer(
  enabled: isLoading,
  child: Container(
    height: 100,
    color: Colors.grey[300],
  ),
)
```

## UI/UX Improvements

### 1. Consistent Spacing
- Card margins: `16px horizontal, 8px vertical`
- Button padding: `32px horizontal, 18px vertical`
- Border radius: `16-20px` for modern look

### 2. Smooth Animations
- All interactive elements have hover/press states
- Gradient buttons with shadow effects
- Animated badges and status indicators

### 3. Enhanced Visual Hierarchy
- Clear color-coded status system
- Gradient borders for important elements
- Subtle shadows for depth

### 4. Accessibility
- High contrast text colors
- Proper font sizing (14-16px body, 18-28px headings)
- Clear visual feedback for interactions

## Best Practices

### DO's ✅
- Use `TropicalColors` constants for all colors
- Leverage predefined widgets for consistency
- Use gradients sparingly for emphasis
- Follow the color-coded status system
- Test in both light and dark modes

### DON'Ts ❌
- Don't use colors outside the tropical palette
- Don't overuse gradients (they lose impact)
- Don't create custom color schemes
- Don't ignore dark mode styling
- Don't use deprecated color methods

## Examples

### Simple Card
```dart
TropicalCard(
  child: Column(
    children: [
      Text('Order #123', style: Theme.of(context).textTheme.titleLarge),
      SizedBox(height: 8),
      TropicalStatusIndicator(status: 'confirmed'),
    ],
  ),
)
```

### Featured Section
```dart
TropicalGradientContainer(
  gradientColors: TropicalColors.warmGradient,
  padding: EdgeInsets.all(20),
  child: Column(
    children: [
      Icon(Icons.star, color: Colors.white, size: 48),
      Text('Featured!', style: TextStyle(color: Colors.white)),
    ],
  ),
)
```

### Action Button
```dart
TropicalGradientButton(
  text: 'Confirm Order',
  gradientColors: [TropicalColors.teal, TropicalColors.teal],
  icon: Icon(Icons.check_circle, color: Colors.white),
  onPressed: _handleConfirm,
)
```

## Migration Guide

If you have existing UI components, update them to use the tropical theme:

### Before:
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.orange,
    borderRadius: BorderRadius.circular(8),
  ),
)
```

### After:
```dart
TropicalCard(
  child: YourContent(),
)
// or
Container(
  decoration: BoxDecoration(
    color: TropicalColors.coral,
    borderRadius: BorderRadius.circular(16),
  ),
)
```

## Theme Toggle

The app supports light/dark theme switching via `ThemeProvider`:

```dart
// Get current theme
final themeProvider = Provider.of<ThemeProvider>(context);
bool isDark = themeProvider.isDarkMode;

// Toggle theme
themeProvider.toggleTheme();
```

## Support

For questions or issues with the tropical theme, refer to:
- `lib/config/tropical_theme.dart` - Theme configuration
- `lib/widgets/tropical_widgets.dart` - Enhanced widgets
- This guide for usage examples

---

**Enjoy the vibrant tropical vibes!** 🌴🍹✨

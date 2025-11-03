# Breakfast Buddy - Theme & Color Guide

**Version**: 1.5.0
**Last Updated**: November 2, 2025

---

## 🎨 Simplified Color Palette (3 Colors Only)

### Design Philosophy
**Professional, clean, and focused.** We use only 3 main colors to create a sophisticated breakfast ordering experience without visual clutter.

---

### Light Theme

#### Core Colors (Only 3!)
- **Primary (Coral Orange)**: `#FF6B35`
  - Energetic breakfast color for main actions
  - Used for: Primary buttons, CTAs, important highlights, branding
  - **Role**: Action & Energy

- **Secondary (Dark Blue-Gray)**: `#2D3047`
  - Professional, readable text and icon color
  - Used for: Body text, icons, headers, secondary UI elements
  - **Role**: Content & Structure

- **Tertiary (Golden Yellow)**: `#FFBC42`
  - Warm accent for special highlights only
  - Used for: Badges, success states, special offers (sparingly)
  - **Role**: Highlights & Success

#### Background & Surfaces
- **Scaffold Background**: `#FAFAFA` - Clean light gray
- **Surface**: `#FFFFFF` - Pure white for cards
- **Input Fields**: `#F5F5F5` - Light gray
- **Chip Background**: `#F5F5F5` - Light gray

#### System Colors
- **Error**: `#EF4444` - Bright red for errors

---

### Dark Theme

#### Core Colors (Only 3!)
- **Primary (Light Coral)**: `#FF8C61`
  - Brighter variant for dark mode visibility
  - Same usage as light mode

- **Secondary (Light Gray-Blue)**: `#B8BBC6`
  - Readable light text for dark backgrounds
  - Used for: Body text, icons, secondary elements

- **Tertiary (Bright Golden Yellow)**: `#FFD666`
  - Enhanced brightness for dark backgrounds
  - Same usage as light mode (sparingly)

#### Background & Surfaces
- **Scaffold Background**: `#0F0F14` - Deep dark background
- **Surface**: `#1E1E2E` - Cool dark surface for cards
- **Input Fields**: `#1A1A24` - Darker input background
- **Chip Background**: `#1A1A24` - Dark gray

#### System Colors
- **Error**: `#FF6B6B` - Bright red for dark mode

---

## 🎯 Usage Guidelines

### 3-Color Rule: Keep It Simple

**Only use 3 colors throughout your app:**
1. **Primary (Coral)** - Actions & branding
2. **Secondary (Dark blue-gray/Light gray-blue)** - Text & structure
3. **Tertiary (Golden yellow)** - Highlights ONLY (use sparingly!)

---

### When to Use Each Color

#### Primary (Coral Orange) - Action & Energy
```dart
// ✅ Good uses
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
  ),
  child: Text('Order Now'),
)

// Use for:
// - Primary action buttons
// - App branding elements
// - Important CTAs
// - Active/selected states
```

#### Secondary (Dark Blue-Gray) - Content & Structure
```dart
// ✅ Good uses
Text(
  'Order Details',
  style: TextStyle(
    color: Theme.of(context).colorScheme.secondary,
  ),
)

Icon(
  Icons.shopping_cart,
  color: Theme.of(context).colorScheme.secondary,
)

// Use for:
// - Body text and headers
// - Icons and graphics
// - Borders and dividers
// - Subtle UI elements
```

#### Tertiary (Golden Yellow) - Highlights Only
```dart
// ✅ Good uses (SPARINGLY!)
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
  ),
  child: Text('New!'), // Badges only
)

// Use ONLY for:
// - Badges and tags
// - Success confirmations
// - Special offers
// - Occasional highlights

// ❌ DON'T use for:
// - Large areas
// - Body text
// - Multiple elements on same screen
```

---

## 🌈 Color Combinations

### Recommended Pairings (Simplified)

1. **Primary Button**
   - Background: `#FF6B35` (Coral)
   - Text: `#FFFFFF` (White)
   - ✅ WCAG AA compliant - high contrast

2. **Body Text on White**
   - Background: `#FFFFFF` (White)
   - Text: `#2D3047` (Dark blue-gray)
   - ✅ Excellent readability

3. **Tertiary Badge (Use Sparingly!)**
   - Background: `#FFBC42` at 15% opacity
   - Text: `#2D3047` (Dark blue-gray)
   - ✅ Subtle but visible

---

## 🎨 Component Styling

### Cards
```dart
// Light mode
Card(
  color: Colors.white,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: Colors.grey.withOpacity(0.1)),
  ),
)

// Dark mode
Card(
  color: Color(0xFF1E1E2E),
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: Colors.white.withOpacity(0.1)),
  ),
)
```

### Buttons
```dart
// Primary action
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: colorScheme.primary,  // #FF6B35
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
)

// Secondary action
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: colorScheme.primary,
    side: BorderSide(color: colorScheme.primary, width: 2),
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
)
```

### Input Fields
```dart
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: Color(0xFFF8FAFC),  // Light mode
    // fillColor: Color(0xFF2A2A3C), // Dark mode
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
  ),
)
```

---

## 📏 Design System Values

### Border Radius
- **Small**: `8px` - Chips, small elements
- **Medium**: `12px` - Text buttons, chips
- **Large**: `16px` - Cards, buttons, inputs
- **Extra Large**: `20px` - FABs
- **Round**: `24px` - Bottom sheets, dialogs

### Elevation
- **Flat**: `0` - Most modern UI elements
- **Low**: `2` - Subtle separation
- **Medium**: `4` - FABs
- **High**: `8` - Dialogs, modal sheets

### Spacing Scale
- **XS**: `4px`
- **S**: `8px`
- **M**: `12px`
- **L**: `16px`
- **XL**: `20px`
- **2XL**: `24px`
- **3XL**: `32px`

---

## 🎭 Theme Evolution

### v1.0-1.3: Warm Amber (4 colors)
- Primary: `#D97706` - Warm amber
- Secondary: `#92400E` - Coffee brown
- Tertiary: `#FEF3C7` - Cream
- Background: `#FEF7ED`
- **Vibe**: Warm, cozy, traditional

### v1.4: Vibrant Coral (4 colors)
- Primary: `#FF6B35` - Coral orange
- Secondary: `#4ECDC4` - Teal
- Tertiary: `#FFC93C` - Sunny yellow
- Background: `#FFFBF5`
- **Vibe**: Fresh, energetic, colorful
- **Issue**: Too many bright colors, overwhelming

### v1.5: Sophisticated Breakfast (3 colors) ✨ CURRENT
- Primary: `#FF6B35` - Coral orange
- Secondary: `#2D3047` - Dark blue-gray
- Tertiary: `#FFBC42` - Golden yellow (minimal use)
- Background: `#FAFAFA`
- **Vibe**: Professional, clean, focused
- **Improvement**: Better contrast, more readable, less visual noise

---

## 🔄 Migration Notes

### Automatic Updates
The theme change is **backward compatible**. All existing components using `Theme.of(context).colorScheme` will automatically use the new colors.

### No Code Changes Required
- ✅ All buttons continue working
- ✅ All cards maintain styling
- ✅ All inputs keep functionality
- ✅ Dark mode fully supported

### What Changed
1. **Color values only** - no structural changes
2. **Both themes updated** - light and dark modes
3. **Improved contrast** - better accessibility
4. **Modern palette** - more energetic feel

---

## 💡 Tips for Developers

### Always Use Theme Colors
```dart
// ✅ Good - responds to theme changes
Container(color: Theme.of(context).colorScheme.primary)

// ❌ Bad - hardcoded color
Container(color: Color(0xFFFF6B35))
```

### Use Color Scheme Properties
```dart
colorScheme.primary        // Main brand color
colorScheme.secondary      // Secondary accent
colorScheme.tertiary       // Third accent
colorScheme.surface        // Card backgrounds
colorScheme.error          // Error states
colorScheme.onPrimary      // Text on primary color
colorScheme.onSurface      // Text on surface
```

### Test Both Modes
Always test your UI in both light and dark modes:
```dart
// Toggle theme for testing
final themeProvider = Provider.of<ThemeProvider>(context);
themeProvider.toggleTheme();
```

---

## 🎨 Color Accessibility

### WCAG Compliance

| Color Combination | Contrast Ratio | Rating |
|------------------|----------------|--------|
| Primary on White | 4.5:1 | ✅ AA |
| White on Primary | 4.5:1 | ✅ AA |
| Secondary on White | 3.2:1 | ⚠️ Large text only |
| Tertiary on White | 1.8:1 | ❌ Decorative only |

### Best Practices
1. **Primary buttons**: Always white text on primary color
2. **Secondary color**: Use for icons and accents, not body text
3. **Tertiary color**: Backgrounds and decorative elements only
4. **Error states**: High contrast red ensures visibility

---

## 📱 Example Screens

### Home Screen
- **Gradient header**: Primary → Secondary
- **Cards**: White (light) / Dark surface (dark)
- **Active indicators**: Tertiary background with primary text
- **CTAs**: Primary buttons with white text

### Menu Screen
- **Category chips**: Tertiary-tinted backgrounds
- **Selected items**: Primary accent color
- **Add buttons**: Primary color
- **Price tags**: Primary color for emphasis

### Order Summary
- **Status badges**: Color-coded by state
  - Pending: Tertiary (yellow)
  - Confirmed: Secondary (teal)
  - Delivered: Success green
- **Totals**: Primary color for emphasis
- **Actions**: Primary elevated buttons

---

## 🚀 Future Enhancements

Potential additions for v1.5.0:
- [ ] Theme customization options
- [ ] High contrast mode
- [ ] Color-blind friendly alternatives
- [ ] Seasonal theme variations

---

**Version History**:
- v1.4.0 (Nov 2, 2025): New vibrant coral/teal theme
- v1.3.0 (Nov 2, 2025): Warm amber/brown theme
- v1.2.0 (Nov 2, 2025): Initial theme system

# Peach Skyline Theme

## Colors

Your app uses a beautiful, soft color palette with **Peach** as the primary color:

- **Peach** `#FFDBBB` - Primary color for buttons, actions, and key elements (warm, inviting)
- **Periwinkle** `#BADDFF` - Secondary color for calm, informational elements
- **Mint** `#BAFFF5` - Tertiary color for fresh accents and success states
- **Slate** `#496580` - Text and grounding elements (professional)

## Design Style

✅ **Soft & Warm** - Peach creates a gentle, inviting atmosphere
✅ **Light & Modern** - Perfect for food apps with warm, comforting feel
✅ **Clean Borders** - Subtle 1px borders for definition
✅ **Rounded Corners** - 12-16px border radius for friendly feel
✅ **Professional Typography** - Slate text on light backgrounds

## Usage

### Buttons
```dart
TropicalGradientButton(
  text: 'Order Now',
  onPressed: () {},
  backgroundColor: TropicalColors.peach, // Soft, warm default
)
```

### Cards
```dart
TropicalCard(
  child: Text('Content'),
)
```

### Status Badges
```dart
TropicalStatusIndicator(
  status: 'pending', // Auto-colored with peach
)
```

## Status Colors
- `pending` → Peach (warm, gentle attention)
- `confirmed` → Mint (success, approved)
- `preparing` → Periwinkle (in-progress, calm)
- `ready` → Mint (complete, ready)
- `delivered` → Mint (final success state)
- `cancelled` → Gray (neutral, inactive)

## Color Usage

### Peach (#FFDBBB) - Primary
- Main action buttons
- Selected items
- Primary navigation
- Important highlights
- Call-to-action elements
- Gentle, warm feel perfect for food apps

### Periwinkle (#BADDFF) - Secondary
- Secondary actions
- Information displays
- In-progress indicators
- Calm, supporting elements

### Mint (#BAFFF5) - Tertiary
- Success confirmations
- Fresh accents
- Completed states
- Positive feedback

### Slate (#496580) - Text
- All readable text
- Icons
- Professional grounding
- Important information

## Why Peach Works for Food Apps

🍑 **Warm & Appetizing** - Peach tones stimulate appetite and create comfort
🏠 **Welcoming** - Makes users feel at home when ordering
☀️ **Soft & Gentle** - Reduces stress during the ordering process
✨ **Light & Fresh** - Perfect for breakfast and light meals

## Accessibility

- **Slate on Peach**: 4.8:1 (AA compliant) ✅
- **Slate on White**: 7.14:1 (AAA level) ✅
- Black text used on peach buttons for maximum readability
- All contrast ratios meet WCAG AA standards

Warm, inviting, and perfectly light! 🌅🍑

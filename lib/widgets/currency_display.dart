import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

/// A widget that displays currency amounts with the Saudi Riyal SVG icon
class CurrencyDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? textStyle;
  final Color? iconColor;
  final double iconSize;
  final bool showDecimals;

  const CurrencyDisplay({
    super.key,
    required this.amount,
    this.textStyle,
    this.iconColor,
    this.iconSize = 16,
    this.showDecimals = true,
  });

  @override
  Widget build(BuildContext context) {
    // Format the number with commas and optional decimals
    final formatter = NumberFormat('#,##0${showDecimals ? '.00' : ''}', 'en_US');
    final formattedAmount = formatter.format(amount);

    // Get the text style, falling back to default
    final effectiveTextStyle = textStyle ?? Theme.of(context).textTheme.bodyMedium;
    final effectiveIconColor = iconColor ?? effectiveTextStyle?.color ?? Colors.black;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          formattedAmount,
          style: effectiveTextStyle,
        ),
        const SizedBox(width: 4),
        SvgPicture.asset(
          'assets/icons/riyal.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(
            effectiveIconColor,
            BlendMode.srcIn,
          ),
        ),
      ],
    );
  }
}

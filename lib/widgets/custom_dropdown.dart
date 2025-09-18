import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final String? label;

  const CustomDropdown({
    super.key,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.isExpanded = true,
    this.padding,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String? safeHint = hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: safeHint != null && safeHint.isNotEmpty
                  ? Text(
                      safeHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'Georgia',
                      ),
                    )
                  : null,
              items: items,
              onChanged: onChanged,
              isExpanded: isExpanded,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              dropdownColor: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }
}

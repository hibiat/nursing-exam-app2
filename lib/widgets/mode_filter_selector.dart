import 'package:flutter/material.dart';

/// モードフィルタ選択ウィジェット
class ModeFilterSelector extends StatelessWidget {
  const ModeFilterSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final String selectedMode; // 'all', 'required', 'general'
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeButton(
          label: '全て',
          mode: 'all',
          isSelected: selectedMode == 'all',
          onTap: () => onModeChanged('all'),
          theme: theme,
        ),
        const SizedBox(width: 8),
        _ModeButton(
          label: '必修のみ',
          mode: 'required',
          isSelected: selectedMode == 'required',
          onTap: () => onModeChanged('required'),
          theme: theme,
        ),
        const SizedBox(width: 8),
        _ModeButton(
          label: '一般のみ',
          mode: 'general',
          isSelected: selectedMode == 'general',
          onTap: () => onModeChanged('general'),
          theme: theme,
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.mode,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final String mode;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

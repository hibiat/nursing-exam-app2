import 'package:flutter/material.dart';

/// 期間選択ウィジェット
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final int selectedPeriod; // 日数
  final ValueChanged<int> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PeriodButton(
          label: '1週間',
          days: 7,
          isSelected: selectedPeriod == 7,
          onTap: () => onPeriodChanged(7),
          theme: theme,
        ),
        const SizedBox(width: 8),
        _PeriodButton(
          label: '1ヶ月',
          days: 30,
          isSelected: selectedPeriod == 30,
          onTap: () => onPeriodChanged(30),
          theme: theme,
        ),
        const SizedBox(width: 8),
        _PeriodButton(
          label: '3ヶ月',
          days: 90,
          isSelected: selectedPeriod == 90,
          onTap: () => onPeriodChanged(90),
          theme: theme,
        ),
      ],
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.days,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final int days;
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

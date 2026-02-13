import 'package:flutter/material.dart';

class SourceAttributionSection extends StatelessWidget {
  const SourceAttributionSection({super.key});

  static const String mhlwCopyrightUrl = 'https://www.mhlw.go.jp/chosakuken/';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('出典・著作権', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          '本アプリの一部問題は、看護師国家試験の過去問題を参考に改題した学習用コンテンツです。\n'
          '出典: 厚生労働省「看護師国家試験」\n'
          '著作権の取り扱いは厚生労働省の規定に準拠しています。\n'
          '規定ページ: $mhlwCopyrightUrl',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

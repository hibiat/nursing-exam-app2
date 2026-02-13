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
          '本アプリには、厚生労働省が実施する看護師国家試験の過去問題を掲載しています。\n'
          'これらの原問題の著作権は厚生労働省に帰属します。\n'
          '\n'
          'また、本アプリには、過去問題を参考に学習目的で再構成・解説を加えたオリジナル問題も含まれています。\n'
          '再構成問題および解説部分の著作権は本アプリ制作者に帰属します。\n'
          '\n'
          '看護師国家試験問題の利用にあたっては、厚生労働省の著作権に関する方針に基づいて掲載しています。\n'
          '\n'
          '出典：厚生労働省「看護師国家試験」\n'
          '著作権に関する方針：$mhlwCopyrightUrl',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

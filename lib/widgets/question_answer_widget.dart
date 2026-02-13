import 'package:flutter/material.dart';
import '../models/question.dart';

/// 問題形式に応じた解答UIを表示するウィジェット
class QuestionAnswerWidget extends StatefulWidget {
  const QuestionAnswerWidget({
    super.key,
    required this.question,
    required this.onAnswer,
    this.enabled = true,
  });

  final Question question;
  final Function(dynamic answer) onAnswer;
  final bool enabled;

  @override
  State<QuestionAnswerWidget> createState() => _QuestionAnswerWidgetState();
}

class _QuestionAnswerWidgetState extends State<QuestionAnswerWidget> {
  // 単一選択の選択状態
  int? _selectedSingleChoice;
  
  // 複数選択の選択状態
  Set<int> _selectedMultipleChoices = {};
  
  // 数値入力の各桁の値
  List<int?> _numericDigits = [];

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  void didUpdateWidget(QuestionAnswerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _initializeState();
    }
  }

  void _initializeState() {
    _selectedSingleChoice = null;
    _selectedMultipleChoices = {};
    
    // 数値入力の桁数を初期化
    final digits = widget.question.answer.digits ?? 2;
    _numericDigits = List.filled(digits, null);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.question.format) {
      case 'single_choice':
        return _buildSingleChoice();
      case 'multiple_choice':
        return _buildMultipleChoice();
      case 'numeric_input':
        return _buildNumericInput();
      default:
        return _buildSingleChoice();
    }
  }

  /// 単一選択UIを構築
  Widget _buildSingleChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.question.choices.map((choice) {
        final isSelected = _selectedSingleChoice == choice.index;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton(
            onPressed: widget.enabled
                ? () {
                    setState(() {
                      _selectedSingleChoice = choice.index;
                    });
                    widget.onAnswer(choice.index);
                  }
                : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : null,
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: 2,
                      ),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${choice.index}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(choice.text)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 複数選択UIを構築
  Widget _buildMultipleChoice() {
    final requiredCount = widget.question.answer.count ?? 2;
    final selectedCount = _selectedMultipleChoices.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 選択数の表示
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$requiredCount つ選んでください（現在 $selectedCount/$requiredCount 選択中）',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        
        // 選択肢
        ...widget.question.choices.map((choice) {
          final isSelected = _selectedMultipleChoices.contains(choice.index);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              onPressed: widget.enabled
                  ? () {
                      setState(() {
                        if (isSelected) {
                          _selectedMultipleChoices.remove(choice.index);
                        } else {
                          if (_selectedMultipleChoices.length < requiredCount) {
                            _selectedMultipleChoices.add(choice.index);
                          }
                        }
                      });
                      
                      // 必要な数だけ選択されたら解答を通知
                      if (_selectedMultipleChoices.length == requiredCount) {
                        widget.onAnswer(_selectedMultipleChoices.toList()..sort());
                      }
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: 2,
                        ),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Text(
                              '${choice.index}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(choice.text)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// 数値入力UIを構築（ボタン式マークシート形式）
  Widget _buildNumericInput() {
    final digits = widget.question.answer.digits ?? 2;
    final unit = widget.question.answer.unit ?? '';
    final decimalRule = widget.question.answer.decimalRule;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 解答指示と注意書き
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '解答: 数値を入力してください',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (decimalRule != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '※ ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      decimalRule,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              if (unit.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '単位: $unit',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // マークシート形式の数値入力（ボタン式）
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 各桁の入力
            ...List.generate(digits, (digitIndex) {
              return Row(
                children: [
                  _buildDigitColumn(digitIndex),
                  // 桁の間に%を表示（最後の桁の後に表示）
                  if (digitIndex == digits - 1 && unit.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text(
                        unit,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
      ],
    );
  }

  /// 1桁分の入力列を構築
  Widget _buildDigitColumn(int digitIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // 桁ラベル
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${digitIndex + 1}桁目',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // 0-9のボタン
          Container(
            width: 70,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              children: List.generate(10, (number) {
                final isSelected = _numericDigits[digitIndex] == number;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      onPressed: widget.enabled
                          ? () {
                              setState(() {
                                _numericDigits[digitIndex] = number;
                              });
                              _checkNumericComplete();
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 数値入力が完了したかチェック
  void _checkNumericComplete() {
    if (_numericDigits.every((digit) => digit != null)) {
      // すべての桁が入力されたら数値を計算
      int result = 0;
      for (int i = 0; i < _numericDigits.length; i++) {
        result = result * 10 + _numericDigits[i]!;
      }
      widget.onAnswer(result);
    }
  }
}
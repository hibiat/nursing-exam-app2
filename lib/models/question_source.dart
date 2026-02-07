import 'package:flutter/material.dart';

class QuestionSource {
  const QuestionSource({
    required this.type,
    this.examNumber,
    this.session,
    this.year,
    this.originalNumber,
    this.createdAt,
    this.author,
  });

  final String type;
  final int? examNumber; 
  final String? session; 
  final int? year;
  final String? originalNumber;
  final String? createdAt; 
  final String? author;

  factory QuestionSource.fromJson(Map<String, dynamic> json) {
    return QuestionSource(
      type: json['type'] as String? ?? 'unknown',
      examNumber: json['exam_number'] as int?,
      session: json['session'] as String?,
      year: json['year'] as int?,
      originalNumber: json['original_number'] as String?,
      createdAt: json['created_at'] as String?,
      author: json['author'] as String?,
    );
  }

   String toDisplayText() {
    switch (type) {
      case 'past_exam':
        if (examNumber == null || session == null) {
          return '過去問（改題）';
        }
        final sessionText = session == 'am' ? '午前' : '午後';
        return '第${examNumber}回 $sessionText（改題）';
      
      case 'prediction':
        return year != null ? '$year年度予想問題' : '予想問題';
      
      case 'original':
        return 'オリジナル問題';
      
      default:
        return '';
    }
  }

  String toCompactText() {
    switch (type) {
      case 'past_exam':
        if (examNumber == null) return '過去問';
        final s = session == 'am' ? '午前' : session == 'pm' ? '午後' : '';
        return '第${examNumber}回$s';
      case 'prediction':
        return '予想';
      case 'original':
        return 'オリジナル';
      default:
        return '';
    }
  }

  IconData getIcon() {
    switch (type) {
      case 'past_exam':
        return Icons.history_edu;
      case 'prediction':
        return Icons.psychology;
      case 'original':
        return Icons.lightbulb_outline;
      default:
        return Icons.quiz;
    }
  }


  Color getIconColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (type) {
      case 'past_exam':
        return cs.primary;
      case 'prediction':
        return cs.tertiary;
      case 'original':
        return cs.secondary;
      default:
        return cs.onSurfaceVariant;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (examNumber != null) 'exam_number': examNumber,
      if (session != null) 'session': session,
      if (year != null) 'year': year,
      if (originalNumber != null) 'original_number': originalNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (author != null) 'author': author,
    };
  }
}
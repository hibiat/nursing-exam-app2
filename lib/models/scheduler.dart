import 'dart:math';

import 'question.dart';
import 'question_state.dart';
import 'skill_state.dart';

class Scheduler {
  const Scheduler();

  String? selectNextQuestion({
    required List<Question> candidates,
    required Map<String, QuestionState> questionStates,
    required Map<String, SkillState> skillStates,
    required DateTime now,
  }) {
    if (candidates.isEmpty) return null;

    final due = <Question>[];
    final newOnes = <Question>[];
    final rest = <Question>[];

    for (final question in candidates) {
      final state = questionStates[question.id];
      if (state == null) {
        newOnes.add(question);
      } else if (!state.dueAt.isAfter(now)) {
        due.add(question);
      } else {
        rest.add(question);
      }
    }

    if (due.isNotEmpty) {
      return _pickMostLapses(due, questionStates);
    }

    if (newOnes.isNotEmpty) {
      return _pickWeakSkill(newOnes, skillStates) ?? newOnes.first.id;
    }

    if (rest.isNotEmpty) {
      return _pickWeakSkill(rest, skillStates) ?? rest.first.id;
    }

    return null;
  }

  String _pickMostLapses(
    List<Question> questions,
    Map<String, QuestionState> questionStates,
  ) {
    questions.sort((a, b) {
      final lapsesA = questionStates[a.id]?.lapses ?? 0;
      final lapsesB = questionStates[b.id]?.lapses ?? 0;
      return lapsesB.compareTo(lapsesA);
    });
    return questions.first.id;
  }

  String? _pickWeakSkill(List<Question> questions, Map<String, SkillState> skillStates) {
    if (questions.isEmpty) return null;
    final scored = questions
        .map((question) {
          final theta = skillStates[question.subdomainId]?.theta ?? 0;
          return MapEntry(question, theta);
        })
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final weakest = scored.first.value;
    final weakestQuestions = scored
        .where((entry) => entry.value == weakest)
        .map((entry) => entry.key)
        .toList();

    return weakestQuestions[Random().nextInt(weakestQuestions.length)].id;
  }
}

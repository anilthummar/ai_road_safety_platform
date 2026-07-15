import 'package:ai_road_safety_platform/features/risk_analysis/domain/entities/risk_entities.dart';
import 'package:ai_road_safety_platform/features/risk_analysis/domain/rules/risk_rule.dart';

/// Default aggregator: max rule score + highest-level wins, with recommendations.
class DefaultRiskRuleEngine implements RiskRuleEngine {
  /// Creates [DefaultRiskRuleEngine].
  DefaultRiskRuleEngine({required List<RiskRule> rules}) : _rules = List.unmodifiable(rules);

  final List<RiskRule> _rules;

  @override
  List<RiskRule> get rules => _rules;

  @override
  RiskAssessment evaluate(RiskInputSnapshot input) {
    final hits = <RiskRuleHit>[];
    for (final rule in _rules) {
      final hit = rule.evaluate(input);
      if (hit != null && hit.score > 0) {
        hits.add(hit);
      }
    }

    hits.sort((a, b) => b.score.compareTo(a.score));

    final score = hits.isEmpty
        ? 0.0
        : hits.map((h) => h.score).reduce((a, b) => a > b ? a : b);

    var level = RiskLevelX.fromScore(score);
    for (final hit in hits) {
      if (hit.level.rank > level.rank) {
        level = hit.level;
      }
    }

    final recommendations = _buildRecommendations(hits, level);

    return RiskAssessment(
      level: level,
      score: score.clamp(0, 100),
      inputs: input,
      triggeredRules: hits,
      recommendations: recommendations,
      evaluatedAt: DateTime.now(),
    );
  }

  List<RiskRecommendation> _buildRecommendations(
    List<RiskRuleHit> hits,
    RiskLevel level,
  ) {
    final byRule = <String, RiskRecommendation>{};
    for (final hit in hits) {
      final message = hit.recommendation;
      if (message == null || message.isEmpty) continue;
      byRule[hit.ruleId] = RiskRecommendation(
        priority: hit.level.rank * 100 + hit.score.round(),
        ruleId: hit.ruleId,
        message: message,
      );
    }

    // Baseline guidance when overall level is elevated but rules were silent on text.
    if (byRule.isEmpty && level != RiskLevel.low) {
      byRule['baseline'] = RiskRecommendation(
        priority: level.rank * 100,
        ruleId: 'baseline',
        message: switch (level) {
          RiskLevel.medium => 'Reduce speed and increase following distance.',
          RiskLevel.high =>
            'Hazard elevated — prepare to stop and avoid flooded areas.',
          RiskLevel.extreme =>
            'Extreme hazard — stop when safe and do not enter flooded roadway.',
          RiskLevel.low => 'Continue with normal caution.',
        },
      );
    }

    final list = byRule.values.toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return list;
  }
}

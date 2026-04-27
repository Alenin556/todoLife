class SalarySplitDraft {
  const SalarySplitDraft({
    required this.salary,
    required this.percents,
    required this.customAmounts,
  });

  final double salary;
  /// Percent per category (0..100).
  final Map<String, int> percents;
  /// Custom category -> fixed amount.
  final Map<String, double> customAmounts;

  Map<String, Object?> toJson() => {
        'salary': salary,
        'percents': percents,
        'customAmounts': customAmounts,
      };

  static SalarySplitDraft fromJson(Map<String, Object?> j) {
    final rawPercents = j['percents'];
    final percents = <String, int>{};
    if (rawPercents is Map) {
      for (final e in rawPercents.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is num) percents[k] = v.toInt();
      }
    }
    final rawCustom = j['customAmounts'];
    final customAmounts = <String, double>{};
    if (rawCustom is Map) {
      for (final e in rawCustom.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is num) customAmounts[k] = v.toDouble();
      }
    }
    final salaryRaw = j['salary'];
    final salary = salaryRaw is num ? salaryRaw.toDouble() : 0.0;
    return SalarySplitDraft(
      salary: salary,
      percents: percents,
      customAmounts: customAmounts,
    );
  }
}

class SalarySplitSaved {
  const SalarySplitSaved({
    required this.savedAtMs,
    required this.draft,
  });

  final int savedAtMs;
  final SalarySplitDraft draft;

  Map<String, Object?> toJson() => {
        'savedAtMs': savedAtMs,
        'draft': draft.toJson(),
      };

  static SalarySplitSaved fromJson(Map<String, Object?> j) {
    final savedAtMs = (j['savedAtMs'] as int?) ?? 0;
    final d = j['draft'];
    final draft = d is Map
        ? SalarySplitDraft.fromJson(d.map((k, v) => MapEntry(k.toString(), v)))
        : const SalarySplitDraft(salary: 0, percents: {}, customAmounts: {});
    return SalarySplitSaved(savedAtMs: savedAtMs, draft: draft);
  }
}


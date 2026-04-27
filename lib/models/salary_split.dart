enum SalarySplitMode {
  percent,
  amount,
}

class SalarySplitDraft {
  const SalarySplitDraft({
    required this.salary,
    required this.percents,
    required this.customAmounts,
    required this.mode,
    required this.manualAmounts,
  });

  final double salary;
  /// Percent per category (0..100).
  final Map<String, int> percents;
  /// Custom category -> fixed amount.
  final Map<String, double> customAmounts;
  /// How the budget is edited: by percent or by fixed amounts.
  final SalarySplitMode mode;
  /// Fixed amounts per category for [SalarySplitMode.amount].
  /// Applies to built-in categories; custom categories are still stored in [customAmounts].
  final Map<String, double> manualAmounts;

  Map<String, Object?> toJson() => {
        'salary': salary,
        'percents': percents,
        'customAmounts': customAmounts,
        'mode': mode.name,
        'manualAmounts': manualAmounts,
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

    final rawMode = j['mode'];
    final mode = switch (rawMode) {
      'amount' => SalarySplitMode.amount,
      _ => SalarySplitMode.percent,
    };

    final rawManual = j['manualAmounts'];
    final manualAmounts = <String, double>{};
    if (rawManual is Map) {
      for (final e in rawManual.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is num) manualAmounts[k] = v.toDouble();
      }
    }

    final salaryRaw = j['salary'];
    final salary = salaryRaw is num ? salaryRaw.toDouble() : 0.0;
    return SalarySplitDraft(
      salary: salary,
      percents: percents,
      customAmounts: customAmounts,
      mode: mode,
      manualAmounts: manualAmounts,
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
        : const SalarySplitDraft(
            salary: 0,
            percents: {},
            customAmounts: {},
            mode: SalarySplitMode.percent,
            manualAmounts: {},
          );
    return SalarySplitSaved(savedAtMs: savedAtMs, draft: draft);
  }
}


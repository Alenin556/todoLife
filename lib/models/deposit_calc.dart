import 'dart:math';

class DepositInput {
  const DepositInput({
    required this.principal,
    required this.ratePercentPerYear,
    required this.termValue,
    required this.termUnit,
    this.compoundsPerYear = 12,
  });

  final double principal;
  final double ratePercentPerYear;
  final double termValue;
  final DepositTermUnit termUnit;
  final int compoundsPerYear;
}

enum DepositTermUnit { months, years }

class DepositResult {
  const DepositResult({required this.total, required this.profit});

  final double total;
  final double profit;
}

DepositResult calculateDeposit(DepositInput input) {
  final p = input.principal;
  final r = input.ratePercentPerYear / 100.0;
  final n = input.compoundsPerYear;

  final tYears = switch (input.termUnit) {
    DepositTermUnit.months => input.termValue / 12.0,
    DepositTermUnit.years => input.termValue,
  };

  if (p <= 0 || r <= 0 || tYears <= 0 || n <= 0) {
    return const DepositResult(total: 0, profit: 0);
  }

  final total = p * pow(1 + (r / n), n * tYears);
  return DepositResult(total: total, profit: total - p);
}


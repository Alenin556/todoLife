import 'package:flutter/material.dart';

import 'deposit_calculator_screen.dart';
import 'salary_split_screen.dart';
import 'savings_plan_screen.dart';

/// Вкладки: распределение ЗП, депозитный калькулятор, план регулярных взносов.
class FinanceRootScreen extends StatefulWidget {
  const FinanceRootScreen({super.key});

  @override
  State<FinanceRootScreen> createState() => _FinanceRootScreenState();
}

class _FinanceRootScreenState extends State<FinanceRootScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Средства'),
              Tab(text: 'Калькулятор вклада'),
              Tab(text: 'План вкладов'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _KeepAliveTab(child: SalarySplitScreen()),
              _KeepAliveTab(child: DepositCalculatorScreen()),
              _KeepAliveTab(child: SavingsPlanScreen()),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

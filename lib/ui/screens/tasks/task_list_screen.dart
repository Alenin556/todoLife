import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../scope/app_state_scope.dart';
import '../../../models/task_item.dart';

enum TaskKind { daily, long }

extension TaskKindX on TaskKind {
  String get label {
    switch (this) {
      case TaskKind.daily:
        return 'Задачи на день';
      case TaskKind.long:
        return 'Долгосрочные задачи';
    }
  }

  String get routeSegment {
    switch (this) {
      case TaskKind.daily:
        return 'daily';
      case TaskKind.long:
        return 'long';
    }
  }

  static TaskKind? tryParse(String? v) {
    switch (v) {
      case 'daily':
        return TaskKind.daily;
      case 'long':
        return TaskKind.long;
      default:
        return null;
    }
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskKind _kind = TaskKind.daily;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final kindParam = GoRouterState.of(context).uri.queryParameters['kind'];
    _kind = TaskKindX.tryParse(kindParam) ?? TaskKind.daily;
    _initialized = true;
  }

  Future<void> _openAddMenu() async {
    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 1000, 16, 16),
      items: const [
        PopupMenuItem(
          value: 'daily',
          child: ListTile(
            leading: Icon(Icons.add),
            title: Text('Задача на день'),
          ),
        ),
        PopupMenuItem(
          value: 'long',
          child: ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Долгосрочная задача'),
          ),
        ),
      ],
    );
    if (!mounted || selected == null) return;
    context.go('/tasks/edit?kind=$selected');
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    // Non-blocking freshness check; if date changed, state will notify.
    appState.ensureDailyTasksFresh();

    final hasLong = appState.tasks(TaskKind.long).isNotEmpty;
    final effectiveKind = (!hasLong && _kind == TaskKind.long) ? TaskKind.daily : _kind;
    if (effectiveKind != _kind) _kind = effectiveKind;

    final items = appState.tasks(_kind);
    final doneCount = items.where((t) => t.done).length;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddMenu,
          child: const Icon(Icons.add),
        ),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _kind == TaskKind.daily ? _todayLabel() : _kind.label,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Сбросить все',
                          onPressed: items.isEmpty
                              ? null
                              : () async {
                                  final yes = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Сбросить все задачи?'),
                                      content: Text(
                                        _kind == TaskKind.daily
                                            ? 'Будут удалены все задачи на день.'
                                            : 'Будут удалены все долгосрочные задачи.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Отмена'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Сбросить'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (yes == true) {
                                    await appState.clearTasks(_kind);
                                  }
                                },
                          icon: const Icon(Icons.delete_sweep_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (hasLong)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SegmentedButton<TaskKind>(
                          segments: const [
                            ButtonSegment(
                              value: TaskKind.daily,
                              label: Text('Сегодня'),
                            ),
                            ButtonSegment(
                              value: TaskKind.long,
                              label: Text('Долгосрочные'),
                            ),
                          ],
                          selected: {_kind},
                          onSelectionChanged: (s) {
                            final next = s.first;
                            setState(() => _kind = next);
                            context.go('/tasks?kind=${next.routeSegment}');
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text('Выполнено: $doneCount из ${items.length}'),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Пока нет задач.\nНажмите + чтобы добавить.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _TaskTile(
                      kind: _kind,
                      item: item,
                      onToggle: (v) => appState.toggleTaskDone(
                        _kind,
                        item.id,
                        v,
                      ),
                      onEdit: () => context.go(
                        '/tasks/edit?kind=${_kind.routeSegment}&id=${Uri.encodeComponent(item.id)}',
                      ),
                      onDelete: () => appState.deleteTask(_kind, item.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _todayLabel() {
  final now = DateTime.now();
  final f = DateFormat('EEEE, d MMMM', 'ru_RU');
  final s = f.format(now);
  final capped = s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
  return 'Сегодня: $capped';
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.kind,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskKind kind;
  final TaskItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final deadlineLabel = (kind == TaskKind.long &&
            item.deadlineDateKey != null &&
            item.deadlineDateKey!.trim().isNotEmpty)
        ? 'Дедлайн: ${item.deadlineDateKey}'
        : null;

    return Dismissible(
      key: ValueKey('${kind.routeSegment}-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onEdit,
          child: Row(
            children: [
              Checkbox(
                value: item.done,
                onChanged: (v) => onToggle(v ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.text),
                      if (deadlineLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            deadlineLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Редактировать',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Удалить',
                onPressed: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Удалить задачу?'),
                      content: Text(item.text),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Отмена'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                  );
                  if (yes == true) onDelete();
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


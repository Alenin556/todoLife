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

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key, required this.kind});

  final TaskKind kind;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final items = appState.tasks(kind);
    final doneCount = items.where((t) => t.done).length;
    if (kind == TaskKind.daily) {
      // Non-blocking freshness check; if date changed, state will notify.
      appState.ensureDailyTasksFresh();
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.go('/tasks/${kind.routeSegment}/edit'),
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
                    Text(
                      kind == TaskKind.daily
                          ? _todayLabel()
                          : kind.label,
                      style: Theme.of(context).textTheme.headlineSmall,
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
                      kind: kind,
                      item: item,
                      onToggle: (v) => appState.toggleTaskDone(
                        kind,
                        item.id,
                        v,
                      ),
                      onEdit: () => context.go(
                        '/tasks/${kind.routeSegment}/edit?id=${Uri.encodeComponent(item.id)}',
                      ),
                      onDelete: () => appState.deleteTask(kind, item.id),
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
          onLongPress: () async {
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
          child: CheckboxListTile(
            value: item.done,
            onChanged: (v) => onToggle(v ?? false),
            title: Text(item.text),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ),
    );
  }
}


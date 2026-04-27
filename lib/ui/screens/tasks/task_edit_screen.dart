import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../scope/app_state_scope.dart';
import 'task_list_screen.dart';

class TaskEditScreen extends StatefulWidget {
  const TaskEditScreen({super.key, required this.kind, this.taskId});

  final TaskKind kind;
  final String? taskId;

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  TextEditingController? _c;
  bool _initialized = false;
  DateTime? _deadline;
  String _initialText = '';
  String? _initialDeadlineKey;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final appState = AppStateScope.of(context);
    final existing = widget.taskId == null
        ? null
        : appState.findTask(widget.kind, widget.taskId!);
    _initialText = (existing?.text ?? '').trim();
    _c = TextEditingController(text: existing?.text ?? '');
    if (widget.kind == TaskKind.long && existing?.deadlineDateKey != null) {
      _deadline = DateTime.tryParse(existing!.deadlineDateKey!);
      _initialDeadlineKey = existing.deadlineDateKey;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final c = _c;
    if (c == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    final title = widget.taskId == null ? 'Новая задача' : 'Редактирование задачи';

    Future<void> handleBack() async {
      String? deadlineKey;
      if (widget.kind == TaskKind.long && _deadline != null) {
        final d = _deadline!;
        deadlineKey =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }
      final dirty =
          c.text.trim() != _initialText || deadlineKey != _initialDeadlineKey;
      if (dirty) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Изменения не сохранены'),
            content: const Text('Выйти без сохранения?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Остаться'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Выйти'),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
      if (!context.mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/tasks?kind=${widget.kind.routeSegment}');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: handleBack,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.kind.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: c,
                decoration: const InputDecoration(
                  labelText: 'Текст задачи',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              if (widget.kind == TaskKind.long) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final initial = _deadline ?? now;
                    final picked = await showDatePicker(
                      context: context,
                      locale: const Locale('ru', 'RU'),
                      initialDate: initial,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 10),
                    );
                    if (picked == null) return;
                    setState(() => _deadline = picked);
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _deadline == null
                        ? 'Добавить дедлайн'
                        : 'Дедлайн: ${DateFormat('d MMMM yyyy', 'ru_RU').format(_deadline!)}',
                  ),
                ),
                if (_deadline != null)
                  TextButton(
                    onPressed: () => setState(() => _deadline = null),
                    child: const Text('Убрать дедлайн'),
                  ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  String? deadlineKey;
                  if (widget.kind == TaskKind.long && _deadline != null) {
                    final d = _deadline!;
                    deadlineKey =
                        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                  }
                  await appState.upsertTask(
                    widget.kind,
                    id: widget.taskId,
                    text: c.text,
                    deadlineDateKey: deadlineKey,
                  );
                  if (!context.mounted) return;
                  context.go('/tasks?kind=${widget.kind.routeSegment}');
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


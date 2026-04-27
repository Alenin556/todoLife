import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    _c = TextEditingController(text: existing?.text ?? '');
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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await appState.upsertTask(
                    widget.kind,
                    id: widget.taskId,
                    text: c.text,
                  );
                  if (!context.mounted) return;
                  context.go('/tasks/${widget.kind.routeSegment}');
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


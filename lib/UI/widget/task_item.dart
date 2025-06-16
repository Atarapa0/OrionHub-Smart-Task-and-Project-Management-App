import 'package:flutter/material.dart';
import '../../data/models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskItem({
    super.key,
    required this.task,
    required this.index,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        onDelete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${task.title} silindi'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: task.status == 'completed'
              ? Colors.green.shade50
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: task.status == 'completed'
                ? Colors.green.shade200
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.status == 'completed'
                    ? Colors.green.shade500
                    : Colors.transparent,
                border: Border.all(
                  color: task.status == 'completed'
                      ? Colors.green.shade500
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: task.status == 'completed'
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: task.status == 'completed'
                            ? Colors.grey.shade600
                            : Colors.black87,
                        decoration: task.status == 'completed'
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: task.status == 'completed'
                        ? Colors.grey.shade500
                        : Colors.grey.shade600,
                    decoration: task.status == 'completed'
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (task.category != null && task.category!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        task.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (task.dueDate != null) ...[
                    Icon(Icons.schedule, size: 16, color: _getDueDateColor()),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getDueDateColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    Color color;
    String text;

    switch (task.priority) {
      case 'high':
        color = Colors.red;
        text = 'Yüksek';
        break;
      case 'medium':
        color = Colors.orange;
        text = 'Orta';
        break;
      case 'low':
        color = Colors.green;
        text = 'Düşük';
        break;
      default:
        color = Colors.grey;
        text = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: _getTextColor(color),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getTextColor(Color color) {
    if (color == Colors.red) return Colors.red.shade700;
    if (color == Colors.orange) return Colors.orange.shade700;
    if (color == Colors.green) return Colors.green.shade700;
    return Colors.grey.shade700;
  }

  Color _getDueDateColor() {
    if (task.dueDate == null) return Colors.grey.shade600;

    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red.shade600; // Geçmiş
    } else if (difference == 0) {
      return Colors.orange.shade600; // Bugün
    } else if (difference <= 3) {
      return Colors.amber.shade600; // 3 gün içinde
    } else {
      return Colors.grey.shade600; // Normal
    }
  }

  String _formatDueDate() {
    if (task.dueDate == null) return '';

    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return '${difference.abs()} gün geçti';
    } else if (difference == 0) {
      if (task.dueTime != null) {
        return 'Bugün ${task.dueTime}';
      }
      return 'Bugün';
    } else if (difference == 1) {
      if (task.dueTime != null) {
        return 'Yarın ${task.dueTime}';
      }
      return 'Yarın';
    } else {
      final dateStr = '${dueDate.day}/${dueDate.month}';
      if (task.dueTime != null) {
        return '$dateStr ${task.dueTime}';
      }
      return dateStr;
    }
  }
}

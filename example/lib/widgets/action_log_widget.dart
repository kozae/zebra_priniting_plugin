import 'package:flutter/material.dart';

class ActionLogWidget extends StatelessWidget {
  final List<String> actionLog;
  final VoidCallback onClearLogs;

  const ActionLogWidget({
    super.key,
    required this.actionLog,
    required this.onClearLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Action Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: onClearLogs,
                  tooltip: 'Clear Logs',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: actionLog.length,
                itemBuilder: (context, index) {
                  final log = actionLog[index];
                  final isError = log.contains('ERROR:');
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: isError ? Colors.red : Colors.black87,
                      ),
                    ),
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

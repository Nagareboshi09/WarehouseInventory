import 'package:flutter/material.dart';

extension FilterExtension on State {
  Widget buildFilterWidget({
    required List<DropdownMenuItem<String>> filterOptions,
    required Function(String, String) onFilterApplied,
    Function()? onReset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Filter by:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            hint: const Text('Select Filter'),
            items: filterOptions,
            onChanged: (value) {
              if (value == null) return;
              TextEditingController filterController = TextEditingController();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Filter by $value'),
                  content: TextField(
                    controller: filterController,
                    decoration: const InputDecoration(hintText: 'Enter value'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final text = filterController.text.trim();
                        if (text.isNotEmpty) {
                          onFilterApplied(value, text);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              );
            },
          ),
          if (onReset != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onReset,
              tooltip: 'Reset Filter',
            ),
          ],
        ],
      ),
    );
  }
}
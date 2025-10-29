// lib/presentation/widgets/dictionary_language_dialog.dart
import 'package:flutter/material.dart';

class DictionaryLanguageDialog extends StatefulWidget {
  final Function(String language, bool remember) onLanguageSelected;

  const DictionaryLanguageDialog({
    super.key,
    required this.onLanguageSelected,
  });

  @override
  State<DictionaryLanguageDialog> createState() => _DictionaryLanguageDialogState();
}

class _DictionaryLanguageDialogState extends State<DictionaryLanguageDialog> {
  String _selectedLanguage = 'english';
  bool _rememberLanguage = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Select Dictionary Language'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Choose the language for the Quran Dictionary:'),
          const SizedBox(height: 16),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'english',
            groupValue: _selectedLanguage,
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Assamese'),
            value: 'assamese',
            groupValue: _selectedLanguage,
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Remember my choice'),
            subtitle: const Text('Don\'t show this dialog again'),
            value: _rememberLanguage,
            onChanged: (value) {
              setState(() {
                _rememberLanguage = value!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onLanguageSelected(_selectedLanguage, _rememberLanguage);
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
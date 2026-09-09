import 'package:flutter/material.dart';
import '../../domain/entities/retry_policy.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.currentPolicy,
  });

  final RetryPolicy currentPolicy;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late RetryMode _retryMode;

  final TextEditingController _minutesController =
      TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();

    _retryMode = widget.currentPolicy.mode;

    if (widget.currentPolicy.maxDuration != null) {
      _minutesController.text =
          widget.currentPolicy.maxDuration!.inMinutes.toString();
    }
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  void _save() {
    RetryPolicy policy;

    if (_retryMode == RetryMode.untilConnected) {
      policy = const RetryPolicy.untilConnected();
    } else {
      final minutes =
          int.tryParse(_minutesController.text) ?? 10;

      policy = RetryPolicy.maxDuration(
        Duration(minutes: minutes),
      );
    }

    Navigator.pop(context, policy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RadioGroup<RetryMode>(
              groupValue: _retryMode,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _retryMode = value;
                });
              },
              child: Column(
                children: const [
                  RadioListTile<RetryMode>(
                    title: Text('Retry until connected'),
                    value: RetryMode.untilConnected,
                  ),
                  RadioListTile<RetryMode>(
                    title: Text('Stop retrying after'),
                    value: RetryMode.maxDuration,
                  ),
                ],
              ),
            ),

            if (_retryMode == RetryMode.maxDuration)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maximum retry duration',
                    suffixText: 'minutes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

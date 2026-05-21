import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';

/// Shows a bottom sheet for the worker to describe extra work and quote a price.
/// The sheet calls [onSubmit] with `{description, amount, approved: false}`.
void showExtraWorkSheet(
  BuildContext context, {
  required void Function(Map<String, dynamic> extraWork) onSubmit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _ExtraWorkSheet(onSubmit: onSubmit),
  );
}

class _ExtraWorkSheet extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSubmit;

  const _ExtraWorkSheet({required this.onSubmit});

  @override
  State<_ExtraWorkSheet> createState() => _ExtraWorkSheetState();
}

class _ExtraWorkSheetState extends State<_ExtraWorkSheet> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final extraWork = <String, dynamic>{
      'description': _descController.text.trim(),
      'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
      'approved': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    Navigator.of(context).pop();
    widget.onSubmit(extraWork);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: WorkerColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Add Extra Work', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Describe the additional work and estimated cost. '
              'The customer must approve before you proceed.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            // ── Description ──────────────────────────────────────────────
            Text('Description', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'e.g. Replace faulty MCB and rewire socket',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please describe the extra work';
                }
                if (v.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // ── Estimated cost ───────────────────────────────────────────
            Text('Estimated Cost (PKR)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: '500',
                prefixText: 'PKR  ',
                prefixStyle: TextStyle(
                  color: WorkerColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter an estimated cost';
                }
                final amount = double.tryParse(v.trim()) ?? 0;
                if (amount <= 0) return 'Cost must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 28),
            // ── Info banner ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WorkerColors.warningLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded,
                      size: 18, color: WorkerColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Customer will be notified and must approve before work begins.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: WorkerColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Submit button ────────────────────────────────────────────
            SizedBox(
              height: WorkerSizes.minTouchTarget,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit for Customer Approval'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

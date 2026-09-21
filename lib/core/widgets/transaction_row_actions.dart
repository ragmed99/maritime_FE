import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

class AmountDescriptionInput {
  const AmountDescriptionInput(this.amount, this.description);
  final double amount;
  final String description;
}

Future<AmountDescriptionInput?> showTransactionEditDialog(
  BuildContext context, {
  required double amount,
  required String description,
}) async {
  final amountController = TextEditingController(
    text: amount.toStringAsFixed(2),
  );
  final descriptionController = TextEditingController(text: description);
  final s = AppLocalizations.of(context);
  final input = await showDialog<AmountDescriptionInput>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(s.editTransaction),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: s.amountMru),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(labelText: s.description),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(
              amountController.text.replaceAll(',', '.'),
            );
            if (value != null && value >= 0) {
              Navigator.pop(
                dialogContext,
                AmountDescriptionInput(
                  value,
                  descriptionController.text.trim(),
                ),
              );
            }
          },
          child: Text(s.save),
        ),
      ],
    ),
  );
  amountController.dispose();
  descriptionController.dispose();
  return input;
}

Future<bool> confirmLinkedTransactionChange(
  BuildContext context, {
  required bool deleting,
}) async {
  final s = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(deleting ? s.deleteTransaction : s.editTransaction),
          content: Text(
            deleting
                ? '${s.deleteTransactionConfirmation}\n\nCette action modifiera également les comptes liés.'
                : 'Confirmer la modification ? Les comptes liés seront recalculés.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(deleting ? s.delete : s.save),
            ),
          ],
        ),
      ) ??
      false;
}

class TransactionRowActions extends StatelessWidget {
  const TransactionRowActions({
    required this.onEdit,
    required this.onDelete,
    super.key,
  });
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        tooltip: AppLocalizations.of(context).edit,
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined, size: 19),
      ),
      IconButton(
        tooltip: AppLocalizations.of(context).delete,
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline, size: 19),
      ),
    ],
  );
}

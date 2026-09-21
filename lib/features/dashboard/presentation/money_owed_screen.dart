import 'package:flutter/material.dart';

import '../../../core/formatters/money_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_view.dart';
import '../application/dashboard_controller.dart';
import '../domain/dashboard_models.dart';

class MoneyOwedScreen extends StatelessWidget {
  const MoneyOwedScreen({required this.controller, super.key});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final arabic = Localizations.localeOf(context).languageCode == 'ar';
      if (controller.status == DashboardStatus.loading ||
          controller.status == DashboardStatus.idle) {
        return AppStateView.loading();
      }
      if (controller.status == DashboardStatus.error ||
          controller.data == null) {
        return AppStateView.error(
          message: arabic
              ? 'تعذر تحميل الديون والقروض'
              : 'Impossible de charger les dettes et prêts',
          retryLabel: arabic ? 'إعادة المحاولة' : 'Réessayer',
          onRetry: controller.load,
        );
      }
      final data = controller.data!;
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _TotalCard(
                  label: arabic
                      ? 'المبالغ المستحقة لنا'
                      : 'Montants qui nous sont dus',
                  value: data.metrics.peopleOweUs,
                  color: context.moneyColors.positive,
                ),
                _TotalCard(
                  label: arabic
                      ? 'المبالغ التي علينا'
                      : 'Montants que nous devons',
                  value: data.metrics.weOwePeople,
                  color: context.moneyColors.negative,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (data.positions.isEmpty)
              AppStateView.empty(
                message: arabic
                    ? 'لا توجد ديون أو قروض'
                    : 'Aucune dette ni aucun prêt',
                icon: Icons.balance_outlined,
              )
            else
              ...data.positions.map(
                (position) => _PositionCard(position: position),
              ),
          ],
        ),
      );
    },
  );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text(
              formatMru(value, Localizations.localeOf(context).toString()),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.position});
  final FinancialPosition position;

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final receivable = position.theyOweUs > 0;
    final value = receivable ? position.theyOweUs : position.weOweThem;
    final kind = switch (position.kind) {
      'client' => arabic ? 'عميل' : 'Client',
      'partner' => arabic ? 'شريك' : 'Partenaire',
      _ => arabic ? 'مالك' : 'Propriétaire',
    };
    final direction = receivable
        ? (arabic ? 'مدين لنا' : 'Nous doit')
        : (arabic ? 'ندين له' : 'Nous lui devons');
    final color = receivable
        ? context.moneyColors.positive
        : context.moneyColors.negative;
    return Card(
      child: ListTile(
        leading: Icon(
          receivable ? Icons.call_received : Icons.call_made,
          color: color,
        ),
        title: Text(
          position.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$kind • $direction'),
        trailing: Text(
          formatMru(value, Localizations.localeOf(context).toString()),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

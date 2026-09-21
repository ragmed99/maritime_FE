import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/formatters/money_formatter.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../ships/application/ships_controller.dart';
import '../../ships/domain/ship_models.dart';

class ShipStatisticsScreen extends StatefulWidget {
  const ShipStatisticsScreen({required this.controller, super.key});

  final ShipsController controller;

  @override
  State<ShipStatisticsScreen> createState() => _ShipStatisticsScreenState();
}

class _ShipStatisticsScreenState extends State<ShipStatisticsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.status == LoadStatus.idle) {
      widget.controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.status == LoadStatus.loading) {
          return AppStateView.loading();
        }
        if (widget.controller.status == LoadStatus.error) {
          return AppStateView.error(
            message: s.shipsLoadError,
            retryLabel: s.retry,
            onRetry: widget.controller.load,
          );
        }
        final ships = [
          ...widget.controller.ships,
        ]..sort((a, b) => b.financials.revenue.compareTo(a.financials.revenue));
        if (ships.isEmpty) {
          return AppStateView.empty(
            message: s.noShips,
            icon: Icons.bar_chart_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: widget.controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                arabic
                    ? 'ترتيب مداخيل السفن'
                    : 'Classement des recettes des navires',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                arabic
                    ? 'مقارنة إجمالي مداخيل كل سفينة'
                    : 'Comparaison du total des recettes de chaque navire',
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _OutcomeChart(ships: ships),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutcomeChart extends StatelessWidget {
  const _OutcomeChart({required this.ships});

  final List<ShipRecord> ships;

  String _axisNumber(double value) {
    if (value >= 1000000) {
      final number = value / 1000000;
      return '${number.toStringAsFixed(number >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final number = value / 1000;
      return '${number.toStringAsFixed(number >= 10 ? 0 : 1)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final maxOutcome = ships.fold<double>(
      0,
      (maximum, ship) =>
          ship.financials.revenue > maximum ? ship.financials.revenue : maximum,
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    final scheme = Theme.of(context).colorScheme;
    final colors = <Color>[
      const Color(0xFF4169E1),
      const Color(0xFF21C52B),
      const Color(0xFFD90F3D),
      const Color(0xFFA842C2),
      const Color(0xFFFF8C00),
      const Color(0xFF0CA6A6),
      const Color(0xFF8D8D8D),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const chartHeight = 360.0;
        const plotHeight = 280.0;
        final availableWidth = constraints.maxWidth - 64;
        final contentWidth = ships.length * 96.0 > availableWidth
            ? ships.length * 96.0
            : availableWidth;
        return SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                height: chartHeight,
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    SizedBox(
                      height: plotHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          6,
                          (index) => Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: Text(
                              _axisNumber(maxOutcome * (5 - index) / 5),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: contentWidth,
                    height: chartHeight,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 28,
                          left: 0,
                          right: 0,
                          height: plotHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (_) => Divider(
                                height: 1,
                                color: scheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: ships.indexed.map((entry) {
                            final rank = entry.$1 + 1;
                            final ship = entry.$2;
                            final ratio = maxOutcome <= 0
                                ? 0.0
                                : ship.financials.revenue / maxOutcome;
                            final color = colors[entry.$1 % colors.length];
                            return SizedBox(
                              width: 96,
                              height: chartHeight,
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 28,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          formatMru(
                                            ship.financials.revenue,
                                            locale,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: plotHeight,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        width: 58,
                                        height: ratio == 0
                                            ? 2
                                            : plotHeight * ratio,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              color.withValues(alpha: 0.78),
                                              color,
                                            ],
                                          ),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(5),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '#$rank ${ship.name}',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

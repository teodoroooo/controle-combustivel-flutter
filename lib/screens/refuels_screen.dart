import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/refuel_stats.dart';
import '../utils/formatters.dart';
import 'refuel_form_screen.dart';

/// Lista de abastecimentos (mais recente primeiro) com seus indicadores.
class RefuelsScreen extends StatelessWidget {
  const RefuelsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, RefuelStats s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir abastecimento?'),
        content: Text('Abastecimento de ${formatDateTime(s.refuel.dateTime)} '
            '(${formatCurrency(s.refuel.totalPrice)}).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await AppScope.of(context).deleteRefuel(s.refuel.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = AppScope.of(context).stats.reversed.toList();
    final theme = Theme.of(context);

    if (stats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_gas_station_outlined,
                  size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              const Text(
                'Nenhum abastecimento registrado.\n'
                'Toque em "Abastecer" para adicionar o primeiro.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: stats.length,
      itemBuilder: (context, i) {
        final s = stats[i];
        final r = s.refuel;
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RefuelFormScreen(refuel: r),
            )),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(r.fuelType.label),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(formatDateTime(r.dateTime),
                            style: theme.textTheme.bodyMedium),
                      ),
                      Text(formatCurrency(r.totalPrice),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, s),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatDecimal(r.liters)} L × '
                    '${formatPricePerLiter(r.pricePerLiter)}/L  •  '
                    '${formatKm(r.odometer)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  if (s.hasIndicators)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _Badge(
                            icon: Icons.route,
                            text: '+${formatKm(s.distance!)}'),
                        _Badge(
                            icon: Icons.eco_outlined,
                            text: '${formatDecimal(s.kmPerLiter!)} km/L'),
                        _Badge(
                            icon: Icons.payments_outlined,
                            text: '${formatCurrency(s.costPerKm!)}/km'),
                      ],
                    )
                  else
                    Text(
                      'Referência inicial (sem km/L e R\$/km)',
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.outline),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12, color: scheme.onSecondaryContainer)),
        ],
      ),
    );
  }
}

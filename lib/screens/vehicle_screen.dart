import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../utils/formatters.dart';
import 'vehicle_form_screen.dart';

/// Exibe o veículo cadastrado ou convida o usuário a cadastrar um.
class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final controller = AppScope.of(context);
    final count = controller.refuels.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Excluir veículo?'),
        content: Text(
          'O veículo ${controller.vehicle!.displayName} e '
          '${count == 1 ? 'o 1 abastecimento associado' : 'os $count abastecimentos associados'} '
          'serão removidos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteVehicle();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veículo e abastecimentos excluídos.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final vehicle = controller.vehicle;
    final theme = Theme.of(context);

    if (vehicle == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car_filled_outlined,
                  size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Nenhum veículo cadastrado',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Cadastre seu veículo para começar a registrar os '
                'abastecimentos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar veículo'),
              ),
            ],
          ),
        ),
      );
    }

    final summary = controller.summary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.directions_car,
                          size: 30, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vehicle.brandName,
                              style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary)),
                          Text(vehicle.modelName,
                              style: theme.textTheme.titleLarge),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _InfoRow(label: 'Marca', value: vehicle.brandName),
                _InfoRow(label: 'Modelo', value: vehicle.modelName),
                _InfoRow(label: 'Ano', value: '${vehicle.year}'),
                _InfoRow(
                  label: 'Cilindrada',
                  value: '${vehicle.engineDisplacement.toStringAsFixed(1)} L',
                ),
                _InfoRow(
                  label: 'Abastecimentos',
                  value: '${summary.refuelCount}',
                ),
                _InfoRow(
                  label: 'Total gasto',
                  value: formatCurrency(summary.totalSpent),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _confirmDelete(context),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Excluir veículo'),
        ),
        const SizedBox(height: 8),
        Text(
          'Para cadastrar outro veículo, exclua o atual. '
          'Os abastecimentos associados também serão removidos.',
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

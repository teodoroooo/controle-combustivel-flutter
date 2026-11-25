import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import 'dashboard_screen.dart';
import 'refuel_form_screen.dart';
import 'refuels_screen.dart';
import 'vehicle_screen.dart';

/// Tela principal com navegação inferior entre Veículo, Abastecimentos e
/// Dashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Meu veículo', 'Abastecimentos', 'Dashboard'];

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    final Widget body;
    if (controller.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (!controller.hasVehicle && _index != 0) {
      body = _NoVehicle(onGoToVehicle: () => setState(() => _index = 0));
    } else {
      body = switch (_index) {
        0 => const VehicleScreen(),
        1 => const RefuelsScreen(),
        _ => const DashboardScreen(),
      };
    }

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: body,
      floatingActionButton: _index == 1 && controller.hasVehicle
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const RefuelFormScreen(),
              )),
              icon: const Icon(Icons.local_gas_station),
              label: const Text('Abastecer'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Veículo',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined),
            selectedIcon: Icon(Icons.local_gas_station),
            label: 'Abastecimentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}

class _NoVehicle extends StatelessWidget {
  const _NoVehicle({required this.onGoToVehicle});

  final VoidCallback onGoToVehicle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_crash_outlined,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text(
              'Cadastre um veículo para registrar abastecimentos '
              'e ver os indicadores.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onGoToVehicle,
              child: const Text('Ir para Veículo'),
            ),
          ],
        ),
      ),
    );
  }
}

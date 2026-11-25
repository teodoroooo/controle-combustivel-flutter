import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/vehicle.dart';
import '../services/fipe_api_service.dart';
import '../utils/formatters.dart';

/// Formulário de cadastro do veículo. Marcas e modelos vêm da BrasilAPI.
class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key, this.api});

  final FipeApiService? api;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  late final FipeApiService _api = widget.api ?? FipeApiService();
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _displacementCtrl = TextEditingController();

  List<FipeItem> _brands = [];
  List<FipeItem> _models = [];
  FipeItem? _brand;
  FipeItem? _model;
  int? _year;

  bool _loadingBrands = true;
  bool _loadingModels = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _displacementCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _loadingBrands = true;
      _error = null;
    });
    try {
      final brands = await _api.fetchBrands();
      if (!mounted) return;
      setState(() => _brands = brands);
    } on FipeApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingBrands = false);
    }
  }

  Future<void> _selectBrand(FipeItem? brand) async {
    if (brand == null || brand == _brand) return;
    setState(() {
      _brand = brand;
      _model = null;
      _models = [];
      _modelCtrl.clear();
      _loadingModels = true;
      _error = null;
    });
    try {
      final models = await _api.fetchModels(brand.code);
      if (!mounted || _brand != brand) return;
      setState(() => _models = models);
    } on FipeApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted && _brand == brand) setState(() => _loadingModels = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_brand == null || _model == null) {
      setState(() => _error = 'Selecione a marca e o modelo da lista.');
      return;
    }
    setState(() => _saving = true);
    final vehicle = Vehicle(
      brandCode: _brand!.code,
      brandName: _brand!.name,
      modelCode: _model!.code,
      modelName: _model!.name,
      year: _year!,
      engineDisplacement: parseDecimal(_displacementCtrl.text)!,
    );
    try {
      await AppScope.of(context).saveVehicle(vehicle);
      if (mounted) Navigator.of(context).pop();
    } on StateError catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = [for (var y = currentYear + 1; y >= 1950; y--) y];

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar veículo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: Text(_error!),
                  trailing: TextButton(
                    onPressed: _brand == null
                        ? _loadBrands
                        : () {
                            final b = _brand;
                            _brand = null;
                            _selectBrand(b);
                          },
                    child: const Text('Tentar novamente'),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) => DropdownMenu<FipeItem>(
                key: const Key('brandDropdown'),
                controller: _brandCtrl,
                width: constraints.maxWidth,
                menuHeight: 320,
                enabled: !_loadingBrands && _brands.isNotEmpty,
                enableFilter: true,
                requestFocusOnTap: true,
                label: Text(_loadingBrands ? 'Carregando marcas...' : 'Marca'),
                leadingIcon: const Icon(Icons.factory_outlined),
                onSelected: _selectBrand,
                dropdownMenuEntries: [
                  for (final b in _brands)
                    DropdownMenuEntry(value: b, label: b.name),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) => DropdownMenu<FipeItem>(
                key: ValueKey('modelDropdown-${_brand?.code}'),
                controller: _modelCtrl,
                width: constraints.maxWidth,
                menuHeight: 320,
                enabled: _brand != null && !_loadingModels,
                enableFilter: true,
                requestFocusOnTap: true,
                label: Text(_loadingModels
                    ? 'Carregando modelos...'
                    : _brand == null
                        ? 'Modelo (selecione a marca)'
                        : 'Modelo'),
                leadingIcon: const Icon(Icons.directions_car_outlined),
                onSelected: (m) => setState(() => _model = m),
                dropdownMenuEntries: [
                  for (final m in _models)
                    DropdownMenuEntry(value: m, label: m.name),
                ],
              ),
            ),
            if (_loadingModels)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _year,
              decoration: const InputDecoration(
                labelText: 'Ano',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(),
              ),
              menuMaxHeight: 320,
              items: [
                for (final y in years)
                  DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: (y) => setState(() => _year = y),
              validator: (v) => v == null ? 'Selecione o ano' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _displacementCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cilindrada do motor (litros)',
                hintText: 'Ex.: 1.0, 1.6, 2.0',
                suffixText: 'L',
                prefixIcon: Icon(Icons.speed_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final value = parseDecimal(v);
                if (value == null) return 'Informe a cilindrada';
                if (value <= 0 || value > 10) {
                  return 'Informe um valor entre 0,1 e 10 litros';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar veículo'),
            ),
            const SizedBox(height: 12),
            Text(
              'Marcas e modelos: tabela FIPE via BrasilAPI.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

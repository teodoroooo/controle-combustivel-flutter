import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/refuel.dart';
import '../utils/formatters.dart';

/// Formulário para registrar (ou editar) um abastecimento.
class RefuelFormScreen extends StatefulWidget {
  const RefuelFormScreen({super.key, this.refuel});

  /// Quando informado, o formulário edita este abastecimento.
  final Refuel? refuel;

  @override
  State<RefuelFormScreen> createState() => _RefuelFormScreenState();
}

class _RefuelFormScreenState extends State<RefuelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceCtrl;
  late final TextEditingController _odometerCtrl;
  late final TextEditingController _litersCtrl;
  late FuelType _fuelType;
  late DateTime _dateTime;
  String? _odometerError;

  bool get _editing => widget.refuel != null;

  @override
  void initState() {
    super.initState();
    final r = widget.refuel;
    String fmt(double? v, int digits) =>
        v == null ? '' : v.toStringAsFixed(digits).replaceAll('.', ',');
    _fuelType = r?.fuelType ?? FuelType.gasolina;
    _dateTime = r?.dateTime ?? DateTime.now();
    _priceCtrl = TextEditingController(text: fmt(r?.pricePerLiter, 2));
    _odometerCtrl = TextEditingController(text: fmt(r?.odometer, 0));
    _litersCtrl = TextEditingController(text: fmt(r?.liters, 2));
    for (final c in [_priceCtrl, _litersCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _odometerCtrl.dispose();
    _litersCtrl.dispose();
    super.dispose();
  }

  double? get _total {
    final price = parseDecimal(_priceCtrl.text);
    final liters = parseDecimal(_litersCtrl.text);
    if (price == null || liters == null) return null;
    return price * liters;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;
    setState(() => _dateTime = DateTime(
        date.year, date.month, date.day, _dateTime.hour, _dateTime.minute));
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;
    setState(() => _dateTime = DateTime(_dateTime.year, _dateTime.month,
        _dateTime.day, time.hour, time.minute));
  }

  String? _positive(String? v, String field) {
    final value = parseDecimal(v);
    if (value == null) return 'Informe $field';
    if (value <= 0) return 'Deve ser maior que zero';
    return null;
  }

  Future<void> _save() async {
    setState(() => _odometerError = null);
    if (!_formKey.currentState!.validate()) return;
    final controller = AppScope.of(context);
    final refuel = Refuel(
      id: widget.refuel?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      fuelType: _fuelType,
      pricePerLiter: parseDecimal(_priceCtrl.text)!,
      odometer: parseDecimal(_odometerCtrl.text)!,
      liters: parseDecimal(_litersCtrl.text)!,
      dateTime: _dateTime,
    );
    final error = controller.validateOdometer(refuel);
    if (error != null) {
      setState(() => _odometerError = error);
      return;
    }
    await controller.upsertRefuel(refuel);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_editing
          ? 'Abastecimento atualizado.'
          : 'Abastecimento de ${formatCurrency(refuel.totalPrice)} registrado.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _total;
    const border = OutlineInputBorder();

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar abastecimento' : 'Novo abastecimento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Combustível', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<FuelType>(
              segments: [
                for (final f in FuelType.values)
                  ButtonSegment(value: f, label: Text(f.label)),
              ],
              selected: {_fuelType},
              onSelectionChanged: (s) => setState(() => _fuelType = s.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('priceField'),
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Preço por litro',
                prefixText: 'R\$ ',
                prefixIcon: Icon(Icons.attach_money),
                border: border,
              ),
              validator: (v) => _positive(v, 'o preço por litro'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('litersField'),
              controller: _litersCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Litros abastecidos',
                suffixText: 'L',
                prefixIcon: Icon(Icons.water_drop_outlined),
                border: border,
              ),
              validator: (v) => _positive(v, 'a quantidade de litros'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('odometerField'),
              controller: _odometerCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quilometragem (hodômetro)',
                suffixText: 'km',
                prefixIcon: const Icon(Icons.speed),
                border: border,
                errorText: _odometerError,
                errorMaxLines: 3,
              ),
              validator: (v) {
                final value = parseDecimal(v);
                if (value == null) return 'Informe a quilometragem';
                if (value < 0) return 'Não pode ser negativa';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(formatDateTime(_dateTime).split(' ').first),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(formatDateTime(_dateTime).split(' ').last),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Valor total',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer)),
                    Text(
                      total == null ? '—' : formatCurrency(total),
                      key: const Key('totalText'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar abastecimento'),
            ),
          ],
        ),
      ),
    );
  }
}

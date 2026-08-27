import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/result.dart';
import '../data/models/invoice.dart';
import '../data/repositories/invoice_repository.dart';
import '../viewmodels/invoice_form_view_model.dart';
import '../viewmodels/session_view_model.dart';

/// Formulario de creación y edición de facturas.
///
/// Devuelve la [Invoice] guardada al hacer `pop`, o `null` si se cancela.
class InvoiceFormView extends StatelessWidget {
  const InvoiceFormView({this.existing, super.key});

  final Invoice? existing;

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionViewModel>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ChangeNotifierProvider<InvoiceFormViewModel>(
      create: (context) => InvoiceFormViewModel(
        repository: context.read<InvoiceRepository>(),
        user: user,
        existing: existing,
      ),
      child: const _InvoiceForm(),
    );
  }
}

class _InvoiceForm extends StatefulWidget {
  const _InvoiceForm();

  @override
  State<_InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<_InvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _supplierController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<InvoiceFormViewModel>();
    _numberController = TextEditingController(text: viewModel.number);
    _supplierController = TextEditingController(text: viewModel.supplierName);
    _taxIdController = TextEditingController(text: viewModel.supplierTaxId);
    _notesController = TextEditingController(text: viewModel.notes);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _supplierController.dispose();
    _taxIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickIssueDate(InvoiceFormViewModel viewModel) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.issueDate,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Fecha de emisión',
    );
    if (picked != null) viewModel.setIssueDate(picked);
  }

  Future<void> _editItem(
    InvoiceFormViewModel viewModel, {
    int? index,
  }) async {
    final item = await showModalBottomSheet<InvoiceItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemEditorSheet(
        initial: index == null ? null : viewModel.items[index],
      ),
    );
    if (item == null) return;
    if (index == null) {
      viewModel.addItem(item);
    } else {
      viewModel.replaceItem(index, item);
    }
  }

  Future<void> _save(InvoiceFormViewModel viewModel, {required bool submit}) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result =
        submit ? await viewModel.saveAndSubmit() : await viewModel.save();
    if (!mounted) return;
    switch (result) {
      case Ok<Invoice>(:final value):
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              submit
                  ? 'Factura ${value.number} enviada a revisión.'
                  : 'Borrador ${value.number} guardado.',
            ),
          ),
        );
        Navigator.of(context).pop(value);
      case Err<Invoice>(:final failure):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InvoiceFormViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(viewModel.title)),
      body: AbsorbPointer(
        absorbing: viewModel.isBusy,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Número de factura',
                  hintText: 'FE-1006',
                  prefixIcon: Icon(Icons.tag),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: viewModel.validateNumber,
                onChanged: viewModel.setNumber,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Proveedor',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: viewModel.validateSupplierName,
                onChanged: viewModel.setSupplierName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxIdController,
                decoration: const InputDecoration(
                  labelText: 'NIT / documento',
                  hintText: '900123456-7',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                keyboardType: TextInputType.text,
                validator: viewModel.validateSupplierTaxId,
                onChanged: viewModel.setSupplierTaxId,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _pickIssueDate(viewModel),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de emisión',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  child: Text(Formatters.date(viewModel.issueDate)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Ítems', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _editItem(viewModel),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              if (viewModel.items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    viewModel.itemsError ?? '',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              else
                ...List.generate(viewModel.items.length, (index) {
                  final item = viewModel.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.description),
                      subtitle: Text(
                        '${item.quantity} × ${Formatters.money(item.unitPriceCents)}'
                        '  ·  IVA ${Formatters.percent(item.taxRate)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Formatters.money(item.totalCents),
                            style: theme.textTheme.labelLarge,
                          ),
                          IconButton(
                            tooltip: 'Editar ítem',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editItem(viewModel, index: index),
                          ),
                          IconButton(
                            tooltip: 'Quitar ítem',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => viewModel.removeItemAt(index),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              _TotalsCard(
                subtotalCents: viewModel.subtotalCents,
                taxCents: viewModel.taxCents,
                totalCents: viewModel.totalCents,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onChanged: viewModel.setNotes,
              ),
              if (viewModel.hasError) ...[
                const SizedBox(height: 16),
                Text(
                  viewModel.errorMessage!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: viewModel.isBusy
                    ? null
                    : () => _save(viewModel, submit: true),
                icon: const Icon(Icons.send),
                label: const Text('Guardar y enviar a revisión'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: viewModel.isBusy
                    ? null
                    : () => _save(viewModel, submit: false),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar borrador'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.subtotalCents,
    required this.taxCents,
    required this.totalCents,
  });

  final int subtotalCents;
  final int taxCents;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(
                label,
                style: bold
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                value,
                style: bold
                    ? theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)
                    : theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            row('Subtotal', Formatters.money(subtotalCents)),
            row('IVA', Formatters.money(taxCents)),
            const Divider(height: 16),
            row('Total', Formatters.money(totalCents), bold: true),
          ],
        ),
      ),
    );
  }
}

/// Hoja inferior para crear o editar un ítem de la factura.
class _ItemEditorSheet extends StatefulWidget {
  const _ItemEditorSheet({this.initial});

  final InvoiceItem? initial;

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late double _taxRate;

  static const List<double> _taxOptions = [0.0, 0.05, 0.19];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _descriptionController = TextEditingController(text: initial?.description);
    _quantityController =
        TextEditingController(text: (initial?.quantity ?? 1).toString());
    _priceController = TextEditingController(
      text: initial == null ? '' : Formatters.centsToInput(initial.unitPriceCents),
    );
    _taxRate = initial?.taxRate ?? 0.19;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final quantity = int.parse(_quantityController.text.trim());
    final cents = Formatters.centsFromInput(_priceController.text)!;
    Navigator.of(context).pop(
      InvoiceItem(
        description: _descriptionController.text.trim(),
        quantity: quantity,
        unitPriceCents: cents,
        taxRate: _taxRate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initial == null ? 'Nuevo ítem' : 'Editar ítem',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Describe el ítem.'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final quantity = int.tryParse((value ?? '').trim());
                      if (quantity == null || quantity <= 0) {
                        return 'Cantidad inválida.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio unitario',
                      prefixText: r'$ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final cents = Formatters.centsFromInput(value ?? '');
                      if (cents == null || cents <= 0) {
                        return 'Precio inválido.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<double>(
              initialValue: _taxRate,
              decoration: const InputDecoration(labelText: 'IVA'),
              items: _taxOptions
                  .map(
                    (rate) => DropdownMenuItem<double>(
                      value: rate,
                      child: Text(Formatters.percent(rate)),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _taxRate = value ?? _taxRate),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Guardar ítem')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

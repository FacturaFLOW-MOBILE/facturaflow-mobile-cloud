import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../core/formatters.dart';
import '../core/result.dart';
import '../data/models/invoice.dart';
import '../data/repositories/invoice_repository.dart';
import '../viewmodels/invoice_detail_view_model.dart';
import '../viewmodels/session_view_model.dart';
import 'widgets/empty_state.dart';
import 'widgets/status_chip.dart';

/// Detalle de una factura con las acciones del flujo de aprobación.
///
/// Hace `pop(true)` si la factura cambió, para que la lista se recargue.
class InvoiceDetailView extends StatelessWidget {
  const InvoiceDetailView({required this.invoiceId, this.initial, super.key});

  final String invoiceId;
  final Invoice? initial;

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionViewModel>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ChangeNotifierProvider<InvoiceDetailViewModel>(
      create: (context) => InvoiceDetailViewModel(
        repository: context.read<InvoiceRepository>(),
        user: user,
        invoiceId: invoiceId,
        initial: initial,
      )..load(),
      child: const _InvoiceDetail(),
    );
  }
}

class _InvoiceDetail extends StatelessWidget {
  const _InvoiceDetail();

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<Result<dynamic>> Function() action,
    required String successMessage,
    bool popOnSuccess = false,
  }) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await action();
    messenger.hideCurrentSnackBar();
    switch (result) {
      case Ok<dynamic>():
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
        if (popOnSuccess) navigator.pop(true);
      case Err<dynamic>(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _reject(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = context.read<InvoiceDetailViewModel>();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    if (reason == null) return;
    final result = await viewModel.reject(reason);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.fold(
            (invoice) => 'Factura ${invoice.number} rechazada.',
            (failure) => failure.message,
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Invoice invoice) async {
    final viewModel = context.read<InvoiceDetailViewModel>();
    final updated = await Navigator.of(context).pushNamed<dynamic>(
      AppRoutes.invoiceForm,
      arguments: InvoiceFormArgs(existing: invoice),
    );
    if (updated is Invoice) viewModel.applyUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InvoiceDetailViewModel>();
    final invoice = viewModel.invoice;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(viewModel.hasChanges);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(invoice?.number ?? 'Factura'),
          actions: [
            if (viewModel.canEdit && invoice != null)
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(context, invoice),
              ),
            if (viewModel.canDelete)
              IconButton(
                tooltip: 'Eliminar borrador',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmAndRun(
                  context,
                  title: 'Eliminar borrador',
                  message: '¿Eliminar definitivamente esta factura?',
                  confirmLabel: 'Eliminar',
                  action: viewModel.delete,
                  successMessage: 'Borrador eliminado.',
                  popOnSuccess: true,
                ),
              ),
          ],
        ),
        body: switch ((invoice, viewModel.hasError)) {
          (null, true) => EmptyState(
              icon: Icons.error_outline,
              title: 'No se pudo cargar la factura',
              message: viewModel.errorMessage,
              actionLabel: 'Reintentar',
              onAction: viewModel.load,
            ),
          (null, false) => const Center(child: CircularProgressIndicator()),
          (final Invoice value, _) => _DetailBody(invoice: value),
        },
        bottomNavigationBar: invoice == null
            ? null
            : _ActionBar(
                viewModel: viewModel,
                onSubmit: () => _confirmAndRun(
                  context,
                  title: 'Enviar a revisión',
                  message:
                      'La factura pasará al contador y no podrás editarla hasta '
                      'que sea revisada.',
                  confirmLabel: 'Enviar',
                  action: viewModel.submit,
                  successMessage: 'Factura enviada a revisión.',
                ),
                onApprove: () => _confirmAndRun(
                  context,
                  title: 'Aprobar factura',
                  message:
                      'Confirmas que ${invoice.number} cumple con los soportes '
                      'y puede pagarse.',
                  confirmLabel: 'Aprobar',
                  action: () => viewModel.approve(),
                  successMessage: 'Factura aprobada.',
                ),
                onReject: () => _reject(context),
                onReopen: () => _confirmAndRun(
                  context,
                  title: 'Reabrir factura',
                  message:
                      'Volverá a estado borrador para que puedas corregirla.',
                  confirmLabel: 'Reabrir',
                  action: viewModel.reopen,
                  successMessage: 'Factura reabierta como borrador.',
                ),
              ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<InvoiceDetailViewModel>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                invoice.supplierName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            StatusChip(status: invoice.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'NIT ${invoice.supplierTaxId}',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        if (invoice.status == InvoiceStatus.rechazada &&
            invoice.rejectionReason != null)
          _Banner(
            icon: Icons.cancel_outlined,
            background: theme.colorScheme.errorContainer,
            foreground: theme.colorScheme.onErrorContainer,
            title: 'Factura rechazada',
            message: invoice.rejectionReason!,
          ),
        if (viewModel.blockedReason != null)
          _Banner(
            icon: Icons.info_outline,
            background: theme.colorScheme.secondaryContainer,
            foreground: theme.colorScheme.onSecondaryContainer,
            title: 'Estado del flujo',
            message: viewModel.blockedReason!,
          ),
        Card(
          child: Column(
            children: [
              _InfoRow(
                label: 'Emitida',
                value: Formatters.date(invoice.issueDate),
              ),
              const Divider(height: 1),
              _InfoRow(label: 'Creada por', value: invoice.createdByName),
              const Divider(height: 1),
              _InfoRow(
                label: 'Última actualización',
                value: Formatters.dateTime(invoice.updatedAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Ítems', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < invoice.items.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  title: Text(invoice.items[i].description),
                  subtitle: Text(
                    '${invoice.items[i].quantity} × '
                    '${Formatters.money(invoice.items[i].unitPriceCents)}'
                    '  ·  IVA ${Formatters.percent(invoice.items[i].taxRate)}',
                  ),
                  trailing: Text(
                    Formatters.money(invoice.items[i].totalCents),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _AmountRow(
                      label: 'Subtotal',
                      value: Formatters.money(invoice.subtotalCents),
                    ),
                    _AmountRow(
                      label: 'IVA',
                      value: Formatters.money(invoice.taxCents),
                    ),
                    const SizedBox(height: 8),
                    _AmountRow(
                      label: 'Total',
                      value: Formatters.money(invoice.totalCents),
                      emphasized: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (invoice.notes.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Notas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(invoice.notes),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text('Historial', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var i = invoice.history.length - 1; i >= 0; i--)
                  _HistoryTile(
                    event: invoice.history[i],
                    isLast: i == 0,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.event, required this.isLast});

  final InvoiceEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.description, style: theme.textTheme.bodyMedium),
                  Text(
                    '${event.actorName} · ${Formatters.dateTime(event.at)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (event.comment != null && event.comment!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '“${event.comment}”',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.viewModel,
    required this.onSubmit,
    required this.onApprove,
    required this.onReject,
    required this.onReopen,
  });

  final InvoiceDetailViewModel viewModel;
  final VoidCallback onSubmit;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final busy = viewModel.isBusy;
    final buttons = <Widget>[
      if (viewModel.canSubmit && viewModel.invoice?.status != InvoiceStatus.rechazada)
        Expanded(
          child: FilledButton.icon(
            onPressed: busy ? null : onSubmit,
            icon: const Icon(Icons.send),
            label: const Text('Enviar a revisión'),
          ),
        ),
      if (viewModel.canReopen)
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : onReopen,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Corregir'),
          ),
        ),
      if (viewModel.canReview) ...[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : onReject,
            icon: const Icon(Icons.close),
            label: const Text('Rechazar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: busy ? null : onApprove,
            icon: const Icon(Icons.check),
            label: const Text('Aprobar'),
          ),
        ),
      ],
    ];

    if (buttons.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy) const LinearProgressIndicator(minHeight: 2),
          if (busy) const SizedBox(height: 8),
          Row(children: buttons),
        ],
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _controller.text.trim();
    if (reason.length < 5) {
      setState(() => _error = 'Explica el motivo (mínimo 5 caracteres).');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rechazar factura'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Motivo del rechazo',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Rechazar')),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}

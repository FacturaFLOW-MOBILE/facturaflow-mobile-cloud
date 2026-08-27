import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_config.dart';
import '../app/routes.dart';
import '../core/formatters.dart';
import '../data/models/app_user.dart';
import '../data/models/invoice.dart';
import '../data/repositories/invoice_repository.dart';
import '../viewmodels/invoice_list_view_model.dart';
import '../viewmodels/session_view_model.dart';
import 'widgets/empty_state.dart';
import 'widgets/invoice_card.dart';

/// Pantalla principal: bandeja de facturas según el rol del usuario.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>();
    final user = session.user;
    if (user == null) {
      // La sesión se cerró mientras la pantalla estaba montada.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ChangeNotifierProvider<InvoiceListViewModel>(
      key: ValueKey(user.id),
      create: (context) => InvoiceListViewModel(
        repository: context.read<InvoiceRepository>(),
        user: user,
      )..load(),
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  Future<void> _openDetail(BuildContext context, Invoice invoice) async {
    final viewModel = context.read<InvoiceListViewModel>();
    final changed = await Navigator.of(context).pushNamed<dynamic>(
      AppRoutes.invoiceDetail,
      arguments: InvoiceDetailArgs(invoiceId: invoice.id, initial: invoice),
    );
    if (changed == true) await viewModel.refresh();
  }

  Future<void> _createInvoice(BuildContext context) async {
    final viewModel = context.read<InvoiceListViewModel>();
    final created = await Navigator.of(context).pushNamed<dynamic>(
      AppRoutes.invoiceForm,
      arguments: const InvoiceFormArgs(),
    );
    if (created != null) await viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InvoiceListViewModel>();
    final user = viewModel.user;
    final invoices = viewModel.visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FacturaFlow'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: viewModel.isBusy ? null : viewModel.refresh,
            icon: const Icon(Icons.refresh),
          ),
          _UserMenu(user: user),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: user.role.canCreateInvoices
          ? FloatingActionButton.extended(
              onPressed: () => _createInvoice(context),
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(viewModel: viewModel)),
            if (viewModel.isBusy && viewModel.all.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (viewModel.hasError && viewModel.all.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.cloud_off,
                  title: 'No se pudieron cargar las facturas',
                  message: viewModel.errorMessage,
                  actionLabel: 'Reintentar',
                  onAction: viewModel.load,
                ),
              )
            else if (invoices.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Sin facturas por aquí',
                  message: viewModel.statusFilter != null ||
                          viewModel.query.isNotEmpty
                      ? 'Ningún resultado con los filtros actuales.'
                      : _emptyMessageForScope(viewModel.scope),
                  actionLabel: viewModel.statusFilter != null ||
                          viewModel.query.isNotEmpty
                      ? 'Quitar filtros'
                      : null,
                  onAction: viewModel.statusFilter != null ||
                          viewModel.query.isNotEmpty
                      ? viewModel.clearFilters
                      : null,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList.separated(
                  itemCount: invoices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => InvoiceCard(
                    invoice: invoices[index],
                    onTap: () => _openDetail(context, invoices[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _emptyMessageForScope(InvoiceScope scope) => switch (scope) {
        InvoiceScope.propias =>
          'Crea tu primera factura con el botón "Nueva".',
        InvoiceScope.revision => 'No hay facturas esperando revisión.',
        InvoiceScope.todas => 'Todavía no hay facturas registradas.',
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.viewModel});

  final InvoiceListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = viewModel.countsByStatus;
    final config = context.read<AppConfig>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (config.demoMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 18,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Modo demostración: los datos son de ejemplo y se '
                        'reinician al cerrar la app.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'En revisión',
                  value: '${counts[InvoiceStatus.enviada] ?? 0}',
                  icon: Icons.hourglass_top,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  label: 'Aprobadas',
                  value: '${counts[InvoiceStatus.aprobada] ?? 0}',
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  label: 'Total aprobado',
                  value: Formatters.money(viewModel.approvedTotalCents),
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (viewModel.availableScopes.length > 1)
            SegmentedButton<InvoiceScope>(
              segments: viewModel.availableScopes
                  .map(
                    (scope) => ButtonSegment<InvoiceScope>(
                      value: scope,
                      label: Text(scope.label),
                    ),
                  )
                  .toList(),
              selected: {viewModel.scope},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  viewModel.setScope(selection.first),
            ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por número, proveedor o NIT',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: viewModel.setQuery,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: viewModel.statusFilter == null,
                  onSelected: (_) => viewModel.setStatusFilter(null),
                ),
                ...InvoiceStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text('${status.label} (${counts[status] ?? 0})'),
                      selected: viewModel.statusFilter == status,
                      onSelected: (selected) => viewModel
                          .setStatusFilter(selected ? status : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Cuenta',
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'salir') context.read<SessionViewModel>().signOut();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName, style: theme.textTheme.titleSmall),
              Text(user.email, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                user.role.label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'salir',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          user.initials,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

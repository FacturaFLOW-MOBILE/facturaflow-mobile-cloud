import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/models/invoice.dart';
import 'status_chip.dart';

/// Tarjeta de factura usada en el listado.
class InvoiceCard extends StatelessWidget {
  const InvoiceCard({required this.invoice, required this.onTap, super.key});

  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.number,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: invoice.status, compact: true),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                invoice.supplierName,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.date(invoice.issueDate),
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    Formatters.money(invoice.totalCents),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (invoice.status == InvoiceStatus.rechazada &&
                  invoice.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    invoice.rejectionReason!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

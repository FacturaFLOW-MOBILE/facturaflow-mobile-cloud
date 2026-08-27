import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/invoice_status.dart';

/// Etiqueta de color con el estado de la factura.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, this.compact = false, super.key});

  final InvoiceStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = AppTheme.statusColors(context, status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppTheme.statusIcon(status), size: compact ? 14 : 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: (compact
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.labelMedium)
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

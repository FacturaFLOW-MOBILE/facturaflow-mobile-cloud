import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/app_user.dart';
import '../models/invoice.dart';
import '../repositories/auth_repository.dart';

/// Datos demo cargados asincrónicamente desde un asset, solo al usarlos.
class DemoSeed {
  DemoSeed._(this.accounts, this.invoices);

  final List<DemoAccount> accounts;
  final List<Invoice> invoices;

  static Future<DemoSeed> load({AssetBundle? bundle, DateTime? now}) async {
    final text = await (bundle ?? rootBundle).loadString(
      'assets/demo/seed.json',
    );
    final json = jsonDecode(text) as Map<String, dynamic>;
    final accounts = (json['users'] as List)
        .map((entry) {
          final data = Map<String, dynamic>.from(entry as Map);
          final user = AppUser.fromJson(data);
          return DemoAccount(
            email: user.email,
            password: data['password'] as String,
            user: user,
          );
        })
        .toList(growable: false);
    final users = {
      for (final account in accounts) account.user.id: account.user,
    };
    final reference = now ?? DateTime.now();
    final invoices = (json['invoices'] as List)
        .map((entry) {
          final data = Map<String, dynamic>.from(entry as Map);
          final owner = users[data['ownerId']]!;
          final created = reference.subtract(
            Duration(days: data['daysAgo'] as int),
          );
          final history = <InvoiceEvent>[
            InvoiceEvent(
              at: created,
              actorId: owner.id,
              actorName: owner.fullName,
              status: InvoiceStatus.borrador,
              description: 'Factura creada',
            ),
            ...(data['history'] as List).map((entry) {
              final event = Map<String, dynamic>.from(entry as Map);
              final actor = users[event['actorId']]!;
              return InvoiceEvent(
                at: reference.subtract(
                  Duration(hours: event['hoursAgo'] as int),
                ),
                actorId: actor.id,
                actorName: actor.fullName,
                status: InvoiceStatus.fromId(event['status'] as String),
                description: event['description'] as String,
                comment: event['comment'] as String?,
              );
            }),
          ];
          return Invoice(
            id: data['id'] as String,
            number: data['number'] as String,
            supplierName: data['supplierName'] as String,
            supplierTaxId: data['supplierTaxId'] as String,
            issueDate: created,
            createdAt: created,
            updatedAt: history.last.at,
            createdById: owner.id,
            createdByName: owner.fullName,
            status: InvoiceStatus.fromId(data['status'] as String),
            notes: data['notes'] as String,
            rejectionReason: data['rejectionReason'] as String?,
            items: (data['items'] as List)
                .map(
                  (item) => InvoiceItem.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList(growable: false),
            history: history,
          );
        })
        .toList(growable: false);
    return DemoSeed._(accounts, invoices);
  }
}

import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/utils/daily_cash_calculator.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../domain/entities/daily_closing_entity.dart';
import '../../data/datasources/closing_remote_datasource.dart';
import '../../data/repositories/closing_repository_impl.dart';
import '../../../../core/providers/current_shop_provider.dart';
import '../../../../core/providers/user_shops_provider.dart';

// --- 1. REPOSITORIES POUR LA CLÔTURE (Supabase) ---
final closingRemoteDataSourceProvider = Provider((ref) {
  return ClosingRemoteDataSource(Supabase.instance.client);
});

final closingRepositoryProvider = Provider((ref) {
  final remoteDataSource = ref.read(closingRemoteDataSourceProvider);
  return ClosingRepositoryImpl(remoteDataSource);
});

// --- 2. MODÈLE DE DONNÉES DU DASHBOARD ---
class DashboardState {
  final double morningBalance;
  final double totalSales;
  final double totalWithdrawals;
  final double calculatedCash;
  final double grossProfit;
  final double netProfit;
  final int salesCount;
  final bool isClosed;
  final DailyClosingEntity? closingData;

  /// Un solde a-t-il été saisi aujourd'hui ? Distinct de `morningBalance == 0`,
  /// car 0 est une valeur légitime (caisse vide le matin) : sans ce drapeau,
  /// la boîte de saisie revient en boucle après un 0 enregistré.
  final bool hasMorningBalance;

  // NOUVEAU : Gestion de l'oubli de clôture
  final bool needsPreviousDayClosing;
  final DateTime? dateToClose;

  DashboardState({
    required this.morningBalance,
    required this.totalSales,
    required this.totalWithdrawals,
    required this.calculatedCash,
    required this.grossProfit,
    required this.netProfit,
    required this.salesCount,
    required this.isClosed,
    this.hasMorningBalance = false,
    this.closingData,
    this.needsPreviousDayClosing = false,
    this.dateToClose,
  });
}

/// Une journée passée est « en retard » si elle a eu de l'activité (vente ou
/// mouvement de caisse) et n'a jamais été clôturée. On regarde aussi la caisse
/// et pas seulement les ventes : un jour sans client mais avec un solde du
/// matin doit quand même être clôturé.
class PendingClosing {
  const PendingClosing({required this.date, required this.daysLate});

  final DateTime date;
  final int daysLate;

  /// Au-delà de quelques jours, le montant saisi est une reconstitution de
  /// mémoire : l'écart calculé ne doit pas être lu comme un vol.
  bool get isUnreliable => daysLate > 3;
}

final pendingClosingProvider = FutureProvider.family<PendingClosing?, DateTime>(
  (ref, date) async {
    final db = ref.watch(localDbProvider);
    // La boutique active. Les trois lectures qui suivent l'ignoraient : sur un
    // téléphone qui gère plusieurs boutiques, une journée déjà clôturée
    // ailleurs masquait celle qui restait à faire, et les ventes d'une
    // épicerie réclamaient la clôture d'une autre.
    final shopId = await ref.watch(currentShopIdProvider.future);
    if (shopId == null || shopId.isEmpty) return null;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (!startOfDay.isBefore(startOfToday)) return null; // jour en cours

    final closing =
        await (db.select(db.localDailyClosings)..where(
              (t) =>
                  t.shopId.equals(shopId) &
                  t.closingDate.isBetweenValues(startOfDay, endOfDay),
            ))
            .getSingleOrNull();
    if (closing != null) return null;

    final sales =
        await (db.select(db.localSales)..where(
              (t) =>
                  t.shopId.equals(shopId) &
                  t.createdAt.isBetweenValues(startOfDay, endOfDay),
            ))
            .get();
    final movements =
        await (db.select(db.localCashMovements)..where(
              (t) =>
                  t.shopId.equals(shopId) &
                  t.createdAt.isBetweenValues(startOfDay, endOfDay),
            ))
            .get();
    if (sales.isEmpty && movements.isEmpty) return null;

    return PendingClosing(
      date: startOfDay,
      daysLate: startOfToday.difference(startOfDay).inDays,
    );
  },
);

// --- 3. LE PROVIDER PRINCIPAL (100% LOCAL avec cache SharedPreferences) ---
final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(() {
      return DashboardNotifier();
    });

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    // Surtout PAS de `ref.watch(revisionDonneesLocalesProvider)` ici.
    //
    // Cet écran déclenche lui-même un téléchargement à chaque construction
    // (`_runBackgroundSync`), et le téléchargement incrémente ce compteur.
    // Le surveiller boucle : synchro → compteur → reconstruction → synchro,
    // un tour toutes les 700 ms, vu en vrai le 20/08/2026. Il n'en a pas
    // besoin — il invalide déjà `productProvider` une fois la synchro finie.
    return _fetchDashboardData();
  }

  // 👇 SYNCHRO AMÉLIORÉE (Récupère aussi le nom de la boutique)
  Future<void> _runBackgroundSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser != null) {
        await prefs.setString('cached_user_id', currentUser.id);

        // Toutes les boutiques du compte, pas « la » sienne : `.single()`
        // levait une exception dès la deuxième, et le client type en a trois.
        ref.invalidate(userShopsProvider);
        final boutiques = await ref.read(userShopsProvider.future);
        if (boutiques.isNotEmpty) {
          final active = await ref.read(currentShopIdProvider.future);
          // On ne rebascule jamais tout seul : si le patron a choisi une
          // boutique, il la retrouve. On ne choisit que faute de mieux.
          final choisie = boutiques.firstWhere(
            (boutique) => boutique.id == active,
            orElse: () => boutiqueParDefaut(boutiques)!,
          );

          // Par le notifier et non par les préférences : lui seul prévient les
          // écrans. Écrire la clé en douce laisserait la source unique sur son
          // ancienne valeur — donc les providers sur l'ancienne boutique.
          await ref.read(currentShopIdProvider.notifier).select(choisie.id);
          await prefs.setString('cached_shop_name', choisie.name);
        }
      }

      await ref.read(syncServiceProvider).pullDataFromSupabase();
    } catch (e) {
      print('Erreur réseau en arrière-plan : $e');
    }
  }

  Future<DashboardState> _fetchDashboardData() async {
    final db = ref.read(localDbProvider);
    final isOnline = ref.read(connectivityProvider).value ?? true;
    String shopId = await ref.read(currentShopIdProvider.future) ?? '';

    // 1. SI C'EST LA TOUTE PREMIÈRE CONNEXION
    final localProducts = shopId.isEmpty
        ? const <LocalProduct>[]
        : await (db.select(
            db.localProducts,
          )..where((row) => row.shopId.equals(shopId))).get();
    final isFirstLoad = localProducts.isEmpty;

    if (isOnline) {
      try {
        if (isFirstLoad) {
          await _runBackgroundSync();
          ref.invalidate(productProvider);
        } else {
          await _runBackgroundSync();
          ref.invalidate(productProvider);
        }
      } catch (e) {
        print(
          '⚠️ Synchro échouée, mais on charge quand même le cache local : $e',
        );
      }
    }

    // La toute première synchronisation renseigne cached_shop_id. Il faut le
    // relire ici : la valeur récupérée avant la synchronisation est encore
    // vide, même si SharedPreferences a été correctement mis à jour.
    shopId = await ref.read(currentShopIdProvider.future) ?? '';

    if (shopId.isEmpty && isFirstLoad) {
      throw Exception('Boutique introuvable. Connectez-vous à internet.');
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    // ==========================================
    // 2. VÉRIFICATION DE LA CLÔTURE DE LA VEILLE
    // ==========================================
    // On prend la journée non clôturée la PLUS ANCIENNE, pas la dernière :
    // après plusieurs jours d'oubli, il faut clôturer dans l'ordre
    // chronologique, sinon les journées intermédiaires resteraient trouées.
    final pastSales =
        await (db.select(db.localSales)
              ..where(
                (t) =>
                    t.shopId.equals(shopId) &
                    t.createdAt.isSmallerThanValue(startOfDay),
              )
              ..orderBy([(t) => drift.OrderingTerm(expression: t.createdAt)]))
            .get();
    final lastSale = pastSales.isEmpty ? null : pastSales.first;

    if (lastSale != null) {
      final lastSaleDate = DateTime(
        lastSale.createdAt.year,
        lastSale.createdAt.month,
        lastSale.createdAt.day,
      );

      if (lastSaleDate.isBefore(startOfDay)) {
        final startOfSaleDay = DateTime(
          lastSaleDate.year,
          lastSaleDate.month,
          lastSaleDate.day,
        );
        final endOfSaleDay = DateTime(
          lastSaleDate.year,
          lastSaleDate.month,
          lastSaleDate.day,
          23,
          59,
          59,
        );

        final existingClosing =
            await (db.select(db.localDailyClosings)..where(
                  (t) =>
                      t.shopId.equals(shopId) &
                      t.closingDate.isBetweenValues(
                        startOfSaleDay,
                        endOfSaleDay,
                      ),
                ))
                .getSingleOrNull();

        if (existingClosing == null) {
          return DashboardState(
            morningBalance: 0,
            totalSales: 0,
            totalWithdrawals: 0,
            calculatedCash: 0,
            grossProfit: 0,
            netProfit: 0,
            salesCount: 0,
            isClosed: false,
            needsPreviousDayClosing: true,
            dateToClose: lastSaleDate,
          );
        }
      }
    }

    // ==========================================
    // 3. LECTURE LOCALE DE LA JOURNÉE ACTUELLE
    // ==========================================
    // ✅ FIX : Utilisation de isBetweenValues au lieu de .year.equals()
    final todayClosing =
        await (db.select(db.localDailyClosings)..where(
              (t) =>
                  t.shopId.equals(shopId) &
                  t.closingDate.isBetweenValues(startOfDay, endOfDay),
            ))
            .getSingleOrNull();

    if (todayClosing != null && todayClosing.isClosed) {
      return DashboardState(
        morningBalance: todayClosing.morningBalance,
        totalSales: todayClosing.totalSales,
        totalWithdrawals: todayClosing.totalWithdrawals,
        calculatedCash: todayClosing.calculatedCash,
        grossProfit: todayClosing.grossProfit,
        netProfit: todayClosing.netProfit,
        salesCount: 0,
        isClosed: true,
      );
    }

    final localSales =
        await (db.select(db.localSales)..where(
              (t) =>
                  t.shopId.equals(shopId) &
                  t.createdAt.isBetweenValues(startOfDay, endOfDay),
            ))
            .get();

    // ✅ FIX : On trie par date décroissante pour prendre le solde le plus récent
    final localCashMovements =
        await (db.select(db.localCashMovements)
              ..where(
                (t) =>
                    t.shopId.equals(shopId) &
                    t.createdAt.isBetweenValues(startOfDay, endOfDay),
              )
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.createdAt,
                  mode: drift.OrderingMode.desc,
                ),
              ]))
            .get();

    final totals = _calculateTotals(localSales, localCashMovements);
    final hasMorningBalance = localCashMovements.any(
      (movement) => movement.type == 'morning_balance',
    );

    return DashboardState(
      hasMorningBalance: hasMorningBalance,
      morningBalance: totals.morningBalance,
      totalSales: totals.totalSales,
      totalWithdrawals: totals.totalWithdrawals,
      calculatedCash: totals.calculatedCash,
      grossProfit: totals.grossProfit,
      netProfit: totals.netProfit,
      salesCount: localSales.length,
      isClosed: false,
    );
  }

  DailyCashTotals _calculateTotals(
    List<LocalSale> sales,
    List<LocalCashMovement> movements,
  ) {
    return DailyCashCalculator.calculate(
      sales: sales.map(
        (sale) => SaleValue(amount: sale.totalAmount, profit: sale.totalProfit),
      ),
      movements: movements.map(
        (movement) => CashMovementValue(
          type: movement.type,
          amount: movement.amount,
          createdAt: movement.createdAt,
        ),
      ),
    );
  }

  // --- ACTIONS DU DASHBOARD ---

  /// Envoie ce qui est en file **sans** laisser une panne de réseau annuler
  /// l'écriture locale qui vient de réussir.
  ///
  /// Local-first : la base du téléphone fait foi. Laisser l'envoi remonter son
  /// erreur jusqu'à l'appelant faisait basculer l'écran en `AsyncError` alors
  /// que la saisie était bel et bien enregistrée. Le commerçant croyait que
  /// rien n'avait pris et recommençait — quatre fonds de caisse enregistrés
  /// pour une seule journée, constatés en test hors ligne le 18/08/2026. Sur
  /// la clôture, le même défaut aurait produit deux clôtures pour une journée,
  /// dont la seconde refusée par le serveur.
  Future<void> _envoyerSansBloquer() async {
    try {
      await ref.read(syncServiceProvider).processQueue();
    } catch (erreur) {
      debugPrint('[SYNC] envoi différé : $erreur');
    }
  }

  Future<void> saveMorningBalance(double amount) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(localDbProvider);
      final prefs = await SharedPreferences.getInstance();

      final shopId = await requireShopId(ref);
      final userId = prefs.getString('cached_user_id') ?? 'offline_user';

      final movementId = const Uuid().v4();
      final now = DateTime.now();

      await db
          .into(db.localCashMovements)
          .insert(
            LocalCashMovement(
              id: movementId,
              shopId: shopId,
              userId: userId,
              amount: amount,
              type: 'morning_balance',
              createdAt: now,
            ),
          );

      final payload = {
        'id': movementId,
        'shop_id': shopId,
        'user_id': userId,
        'amount': amount,
        'type': 'morning_balance',
        'created_at': now.toUtc().toIso8601String(),
      };
      await db.addToQueue('ADD_CASH_MOVEMENT', jsonEncode(payload));

      // L'affichage se rafraîchit AVANT l'envoi : le solde est déjà en base
      // locale, il doit apparaître tout de suite, réseau ou pas.
      state = AsyncValue.data(await _fetchDashboardData());
      await _envoyerSansBloquer();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Rouvre une journée clôturée : le commerçant ferme sa caisse à 18h et un
  /// client arrive à 19h. Sans ça, la vente ne serait pas enregistrée du tout.
  ///
  /// Le comptage précédent et son écart sont **écrits dans la note**, jamais
  /// effacés : recompter ne doit pas pouvoir faire disparaître un manquant.
  /// Réservé au Patron (route protégée), sinon un vendeur pourrait recompter
  /// jusqu'à masquer un écart gênant.
  Future<void> reopenDay(DateTime date) async {
    final db = ref.read(localDbProvider);
    // Rouvrir la journée de LA boutique active. Sans ce filtre, la requête
    // pouvait tomber sur la clôture d'une autre boutique du même téléphone.
    final shopId = await requireShopId(ref);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final closing =
        await (db.select(db.localDailyClosings)..where(
              (t) =>
                  t.shopId.equals(shopId) &
                  t.closingDate.isBetweenValues(startOfDay, endOfDay),
            ))
            .getSingleOrNull();
    if (closing == null) return;

    final now = DateTime.now();
    final trace =
        'Rouverte le ${DateFormat('dd/MM').format(now)} '
        'à ${DateFormat('HH:mm').format(now)}\n'
        '(comptage précédent : '
        '${(closing.physicalCash ?? 0).round()} F — '
        'écart : ${(closing.cashGap ?? 0).round()} F)';
    final mergedNote = [
      if (closing.note != null && closing.note!.trim().isNotEmpty)
        closing.note!.trim(),
      trace,
    ].join('\n');

    await (db.update(
      db.localDailyClosings,
    )..where((t) => t.id.equals(closing.id))).write(
      LocalDailyClosingsCompanion(
        isClosed: const drift.Value(false),
        note: drift.Value(mergedNote),
      ),
    );

    await db.addToQueue(
      'ADD_CLOSING',
      jsonEncode({
        'id': closing.id,
        'shop_id': closing.shopId,
        'user_id': closing.userId,
        'closing_date':
            "${startOfDay.year}-${startOfDay.month.toString().padLeft(2, '0')}-${startOfDay.day.toString().padLeft(2, '0')}",
        'morning_balance': closing.morningBalance,
        'total_sales': closing.totalSales,
        'total_withdrawals': closing.totalWithdrawals,
        'calculated_cash': closing.calculatedCash,
        'gross_profit': closing.grossProfit,
        'net_profit': closing.netProfit,
        'physical_cash': closing.physicalCash,
        'cash_gap': closing.cashGap,
        'is_closed': false,
        'note': mergedNote,
      }),
    );
    state = AsyncValue.data(await _fetchDashboardData());
    await _envoyerSansBloquer();
  }

  Future<void> closeDay(
    double physicalCash,
    String? note, {
    DateTime? specificDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(localDbProvider);
      final prefs = await SharedPreferences.getInstance();

      final shopId = await requireShopId(ref);
      final userId = prefs.getString('cached_user_id') ?? 'offline_user';

      final dateToClose = specificDate ?? DateTime.now();
      final startOfDay = DateTime(
        dateToClose.year,
        dateToClose.month,
        dateToClose.day,
      );
      final endOfDay = DateTime(
        dateToClose.year,
        dateToClose.month,
        dateToClose.day,
        23,
        59,
        59,
      );

      final localSales =
          await (db.select(db.localSales)..where(
                (t) =>
                    t.shopId.equals(shopId) &
                    t.createdAt.isBetweenValues(startOfDay, endOfDay),
              ))
              .get();
      final localCashMovements =
          await (db.select(db.localCashMovements)..where(
                (t) =>
                    t.shopId.equals(shopId) &
                    t.createdAt.isBetweenValues(startOfDay, endOfDay),
              ))
              .get();
      final totals = _calculateTotals(localSales, localCashMovements);
      final cashGap = physicalCash - totals.calculatedCash;

      final existingClosing =
          await (db.select(db.localDailyClosings)..where(
                (t) =>
                    t.shopId.equals(shopId) &
                    t.closingDate.isBetweenValues(startOfDay, endOfDay),
              ))
              .getSingleOrNull();
      final closingId = existingClosing?.id ?? const Uuid().v4();
      final normalizedClosingDate = startOfDay;

      // Refermer après une réouverture ne doit pas effacer la trace : on
      // conserve la note existante et on ajoute la nouvelle en dessous.
      final previousNote = existingClosing?.note?.trim();
      final mergedNote = [
        if (previousNote != null && previousNote.isNotEmpty) previousNote,
        if (note != null && note.trim().isNotEmpty) note.trim(),
      ].join('\n');
      final finalNote = mergedNote.isEmpty ? null : mergedNote;

      await db
          .into(db.localDailyClosings)
          .insert(
            LocalDailyClosing(
              id: closingId,
              shopId: shopId,
              userId: userId,
              closingDate: normalizedClosingDate,
              morningBalance: totals.morningBalance,
              totalSales: totals.totalSales,
              totalWithdrawals: totals.totalWithdrawals,
              calculatedCash: totals.calculatedCash,
              grossProfit: totals.grossProfit,
              netProfit: totals.netProfit,
              physicalCash: physicalCash,
              cashGap: cashGap,
              isClosed: true,
              note: finalNote,
            ),
            mode: drift.InsertMode.insertOrReplace,
          );

      final payload = {
        'id': closingId,
        'shop_id': shopId,
        'user_id': userId,
        'closing_date':
            "${dateToClose.year}-${dateToClose.month.toString().padLeft(2, '0')}-${dateToClose.day.toString().padLeft(2, '0')}",
        'morning_balance': totals.morningBalance,
        'total_sales': totals.totalSales,
        'total_withdrawals': totals.totalWithdrawals,
        'calculated_cash': totals.calculatedCash,
        'gross_profit': totals.grossProfit,
        'net_profit': totals.netProfit,
        'physical_cash': physicalCash,
        'cash_gap': cashGap,
        'is_closed': true,
        'note': finalNote,
      };
      await db.addToQueue('ADD_CLOSING', jsonEncode(payload));

      // La clôture est enregistrée en local : elle est faite. L'envoi et la
      // sauvegarde viennent après et ne peuvent plus la faire paraître ratée
      // — un commerçant qui reclôture hors ligne créerait un doublon que le
      // serveur refuserait ensuite, et sa journée resterait bloquée.
      state = AsyncValue.data(await _fetchDashboardData());
      await _envoyerSansBloquer();
      try {
        await ref.read(backupServiceProvider).createBackup();
      } catch (_) {
        // La clôture reste valide même si le stockage du téléphone est plein.
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

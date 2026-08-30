import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/providers/current_shop_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/utils/daily_cash_calculator.dart';
import '../../../dashboard/domain/entities/daily_closing_entity.dart';

class MonthlyReportState {
  final double totalSales;
  final double totalNetProfit;
  final double totalWithdrawals;
  final double totalCashGap;
  final double totalShortage;
  final double totalSurplus;
  final double cashAdjustedResult;
  final List<DailyClosingEntity> dailyClosings;

  /// Journées comptées dans ce bilan dont le tiroir n'a jamais été compté.
  ///
  /// Leurs ventes sont réelles et entrent dans les totaux — l'argent a bien
  /// été encaissé. Mais personne n'a vérifié la caisse ce jour-là : le total
  /// du mois est donc exact sur ce qui est entré, et muet sur ce qui a pu en
  /// sortir sans trace. L'écran le dit plutôt que de laisser croire à un
  /// chiffre vérifié.
  final int journeesNonCloturees;

  MonthlyReportState({
    required this.totalSales,
    required this.totalNetProfit,
    required this.totalWithdrawals,
    required this.totalCashGap,
    required this.totalShortage,
    required this.totalSurplus,
    required this.cashAdjustedResult,
    required this.dailyClosings,
    this.journeesNonCloturees = 0,
  });
}

// 👇 NOUVEAU : Lecture 100% Locale (Drift) 👇
final monthlyReportProvider =
    FutureProvider.family<MonthlyReportState, DateTime>((ref, date) async {
      final db = ref.read(localDbProvider);
      // La boutique active, SURVEILLÉE — le bilan doit se refaire quand on
      // change de boutique.
      //
      // Sans ce filtre, il additionnait les clôtures de toutes les boutiques
      // du téléphone : la journée du 21/08 d'une épicerie en vente simple
      // apparaissait dans le bilan d'une ferme en mode cycles. Le pull
      // fusionne sans jamais vider, donc la base locale les contient toutes.
      final shopId = await watchShopId(ref);

      // Définir le 1er et le dernier jour du mois
      final startDate = DateTime(date.year, date.month, 1);
      final endDate = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

      // Lire les clôtures locales de ce mois
      final localClosings =
          await (db.select(db.localDailyClosings)
                ..where(
                  (t) =>
                      t.shopId.equals(shopId) &
                      t.closingDate.isBetweenValues(startDate, endDate),
                )
                ..orderBy([(t) => OrderingTerm(expression: t.closingDate)]))
              .get();

      final closings = localClosings
          .map(
            (c) => DailyClosingEntity(
              id: c.id,
              shopId: c.shopId,
              userId: c.userId,
              closingDate: c.closingDate,
              morningBalance: c.morningBalance,
              totalSales: c.totalSales,
              totalWithdrawals: c.totalWithdrawals,
              calculatedCash: c.calculatedCash,
              grossProfit: c.grossProfit,
              netProfit: c.netProfit,
              physicalCash: c.physicalCash,
              cashGap: c.cashGap,
              isClosed: c.isClosed,
              note: c.note,
            ),
          )
          .toList();

      // Les journées VENDUES mais jamais clôturées.
      //
      // La clôture est devenue facultative avec la caisse continue : le
      // commerçant vend le mardi, oublie de clôturer, revend le mercredi — et
      // son argent se reporte tout seul, c'est voulu. Mais le bilan, lui, ne
      // lisait QUE les clôtures : ces journées-là disparaissaient du mois,
      // ventes comprises. Deux jours d'activité invisibles, sans un mot.
      //
      // On les reconstruit depuis les ventes et les mouvements. Elles entrent
      // dans les totaux du mois — l'argent a bien été encaissé — mais restent
      // `isClosed: false`, sans montant compté ni écart : personne n'a compté
      // le tiroir ce jour-là, et inventer un écart serait pire que de ne rien
      // afficher.
      final jourDeja = closings
          .map(
            (c) => DateTime(
              c.closingDate.year,
              c.closingDate.month,
              c.closingDate.day,
            ),
          )
          .toSet();

      final ventesDuMois =
          await (db.select(db.localSales)..where(
                (t) =>
                    t.shopId.equals(shopId) &
                    t.createdAt.isBetweenValues(startDate, endDate),
              ))
              .get();
      final mouvementsDuMois =
          await (db.select(db.localCashMovements)..where(
                (t) =>
                    t.shopId.equals(shopId) &
                    t.createdAt.isBetweenValues(startDate, endDate),
              ))
              .get();

      final ventesParJour = <DateTime, List<LocalSale>>{};
      for (final vente in ventesDuMois) {
        final jour = DateTime(
          vente.createdAt.year,
          vente.createdAt.month,
          vente.createdAt.day,
        );
        if (jourDeja.contains(jour)) continue;
        ventesParJour.putIfAbsent(jour, () => []).add(vente);
      }

      for (final entree in ventesParJour.entries) {
        final jour = entree.key;
        final sorties = mouvementsDuMois.where((m) {
          if (m.type != 'withdrawal') return false;
          final j = DateTime(
            m.createdAt.year,
            m.createdAt.month,
            m.createdAt.day,
          );
          return j == jour;
        });
        // Même règle que la caisse du jour : un déplacement d'argent ne
        // diminue pas le résultat, seule une dépense le fait.
        final depenses = sorties
            .where(
              (m) => !categoriesSansImpactSurLeBenefice.contains(m.category),
            )
            .fold<double>(0, (somme, m) => somme + m.amount);
        final toutesSorties = sorties.fold<double>(
          0,
          (somme, m) => somme + m.amount,
        );
        final ventes = entree.value.fold<double>(
          0,
          (somme, v) => somme + v.totalAmount,
        );
        final marge = entree.value.fold<double>(
          0,
          (somme, v) => somme + v.totalProfit,
        );

        closings.add(
          DailyClosingEntity(
            id: 'non-cloture-${jour.toIso8601String()}',
            shopId: shopId,
            userId: '',
            closingDate: jour,
            morningBalance: 0,
            totalSales: ventes,
            totalWithdrawals: toutesSorties,
            calculatedCash: 0,
            grossProfit: marge,
            netProfit: marge - depenses,
            // Personne n'a compté : pas de montant physique, donc pas d'écart.
            physicalCash: null,
            cashGap: null,
            isClosed: false,
            note: null,
          ),
        );
      }

      closings.sort((a, b) => a.closingDate.compareTo(b.closingDate));

      double totalSales = 0;
      double totalNetProfit = 0;
      double totalWithdrawals = 0;
      double totalCashGap = 0;
      double totalShortage = 0;
      double totalSurplus = 0;

      for (var closing in closings) {
        totalSales += closing.totalSales;
        totalNetProfit += closing.netProfit;
        totalWithdrawals += closing.totalWithdrawals;
        final gap = closing.cashGap ?? 0;
        totalCashGap += gap;
        if (gap < 0) {
          totalShortage += gap.abs();
        } else {
          totalSurplus += gap;
        }
      }

      return MonthlyReportState(
        totalSales: totalSales,
        totalNetProfit: totalNetProfit,
        totalWithdrawals: totalWithdrawals,
        totalCashGap: totalCashGap,
        totalShortage: totalShortage,
        totalSurplus: totalSurplus,
        cashAdjustedResult: totalNetProfit + totalCashGap,
        dailyClosings: closings,
        journeesNonCloturees: closings.where((c) => !c.isClosed).length,
      );
    });

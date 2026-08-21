import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incrémenté chaque fois qu'un téléchargement a réécrit la base locale.
///
/// Le pull remplit Drift, mais un provider qui a déjà résolu son `Future` ne
/// le sait pas : l'écran garde ce qu'il avait au moment de son build. Sur un
/// téléphone neuf ce « ce qu'il avait » est vide — le vendeur se connecte, les
/// produits arrivent trente secondes plus tard, et il faut fermer
/// l'application pour les voir. Deux bugs distincts en apparence (l'écran de
/// comptage vide, le stock vide chez le vendeur) n'étaient que ce silence.
///
/// Surveillé par `watchShopId()`, donc par tout provider lisant une table
/// téléchargée. La synchro n'est déclenchée que par un événement — reprise de
/// l'app, retour du réseau, connexion, changement de boutique — jamais par un
/// minuteur : le rafraîchissement ne peut donc pas clignoter en boucle.
///
/// Ce fichier n'importe rien d'autre que Riverpod exprès : `sync_service` et
/// `current_shop_provider` en dépendent tous les deux.
final revisionDonneesLocalesProvider = StateProvider<int>((ref) => 0);

/// ShopTrack TEST cible actuellement les boutiques du Cameroun (UTC+1 toute
/// l'année). Ces bornes évitent qu'un navigateur en France déplace une vente
/// au jour ou au mois suivant pendant l'heure d'été française.
DateTime debutJourCamerounUtc(DateTime jour) =>
    DateTime.utc(jour.year, jour.month, jour.day)
        .subtract(const Duration(hours: 1));

DateTime finJourCamerounUtc(DateTime jour) =>
    DateTime.utc(jour.year, jour.month, jour.day + 1)
        .subtract(const Duration(hours: 1));

DateTime debutMoisCamerounUtc(DateTime mois) =>
    DateTime.utc(mois.year, mois.month)
        .subtract(const Duration(hours: 1));

DateTime finMoisCamerounUtc(DateTime mois) =>
    DateTime.utc(mois.year, mois.month + 1)
        .subtract(const Duration(hours: 1));

DateTime dateCamerounMaintenant() {
  final instant = DateTime.now().toUtc().add(const Duration(hours: 1));
  return DateTime(instant.year, instant.month, instant.day);
}

DateTime heureCameroun(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 1));

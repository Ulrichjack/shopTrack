import 'package:flutter/foundation.dart';

/// La version de l'application, injectée à la compilation.
///
/// Elle était écrite en dur dans l'écran de profil, et affichait « v1.0.0 » sur
/// une application en 1.3.0. Ce n'est pas cosmétique : c'est la première chose
/// qu'on demande à un commerçant au téléphone quand quelque chose ne va pas.
/// Une fausse réponse envoie chercher dans le mauvais code.
///
/// Renseignée par le script de livraison :
///
/// ```
/// flutter build apk --release --split-per-abi \
///   --dart-define=VERSION_APP=$(grep '^version:' pubspec.yaml | cut -d' ' -f2)
/// ```
///
/// Sans cette option — un `flutter run` ordinaire — elle vaut « dev », ce qui
/// est la vérité : ce n'est pas une version livrée.
final versionApplication = ValueNotifier<String>(
  const String.fromEnvironment('VERSION_APP', defaultValue: 'dev'),
);

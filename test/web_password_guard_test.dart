import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/web/web_password_form.dart';

void main() {
  group('motDePasseProvisoireAChanger', () {
    test('bloque quand le marqueur est vrai', () {
      // Le patron a créé le compte, donc il connaît ce mot de passe. Tant
      // qu'il n'est pas remplacé, il peut ouvrir une session au nom de la
      // vendeuse — et l'historique d'audit attribuerait ces gestes à celle-ci.
      expect(
        motDePasseProvisoireAChanger(const {'must_change_password': true}),
        isTrue,
      );
    });

    test('laisse passer un compte normal', () {
      expect(motDePasseProvisoireAChanger(null), isFalse);
      expect(motDePasseProvisoireAChanger(const {}), isFalse);
      expect(
        motDePasseProvisoireAChanger(const {'must_change_password': false}),
        isFalse,
      );
    });

    test('n’enferme personne sur une valeur d’un autre type', () {
      // Un marqueur mal écrit côté serveur ne doit pas bloquer pour toujours
      // un compte qui n'a aucun écran pour s'en sortir.
      expect(
        motDePasseProvisoireAChanger(const {'must_change_password': 'true'}),
        isFalse,
      );
      expect(
        motDePasseProvisoireAChanger(const {'must_change_password': 1}),
        isFalse,
      );
    });
  });
}

---
name: android-emulator
description: "OBLIGATOIRE pour: lancer ou débloquer l'émulateur Android de ShopTrack. Déclencheurs: lancer l'émulateur, Pixel_5, écran noir, AVD bloqué, emulator-5554, ADB. NE PAS utiliser pour: corriger le code Flutter, créer un AVD ou effacer ses données sans demande explicite."
---

# Émulateur Android ShopTrack

## PRIMARY RESPONSIBILITY

Obtenir un `Pixel_5` visible, démarré et contrôlable par ADB, en conservant ses
données. Diagnostiquer l'ancienne instance avant d'en lancer une autre.

## USE THIS SKILL WHEN

- L'utilisateur demande de lancer ou relancer l'émulateur de ShopTrack.
- La fenêtre est noire, Android reste au démarrage ou l'AVD paraît bloqué.
- Le lancement échoue car une autre instance du même AVD existe.

## DO NOT USE THIS SKILL WHEN

- La demande concerne seulement `flutter run`, un bug applicatif ou les logs Dart.
- Il faut créer, mettre à jour ou supprimer un AVD.
- Il faut réinitialiser les données : `-wipe-data` exige un accord explicite.

## TRIGGERS

`émulateur`, `emulator`, `Pixel_5`, `AVD`, `écran noir`, `ADB`,
`emulator-5554`, `multiple emulators`, `boot bloqué`.

## OWNED DIRECTORIES

- Aucun fichier métier ShopTrack.
- Ce skill orchestre le SDK Android et l'AVD utilisateur sans les modifier.

## REQUIRED DEPENDENCIES

- `/home/jack/Android/Sdk/emulator/emulator`
- `/home/jack/Android/Sdk/platform-tools/adb`
- AVD `Pixel_5`
- Autorisation d'exécuter une application graphique et ADB hors sandbox.

## OPTIONAL DEPENDENCIES

- Flutter, seulement si l'utilisateur demande ensuite de lancer ShopTrack.

## RELATED DOCUMENTATION

- `AGENTS.md` pour les commandes et règles générales du projet.
- `CLAUDE.md` pour le workflow de développement ShopTrack.

## Procédure

1. Annoncer le diagnostic, puis vérifier sans modifier l'état :

   ```bash
   /home/jack/Android/Sdk/emulator/emulator -list-avds
   /home/jack/Android/Sdk/platform-tools/adb devices -l
   ```

2. Si `Pixel_5` est déjà attaché, ne pas lancer une deuxième instance. Vérifier :

   ```bash
   /home/jack/Android/Sdk/platform-tools/adb -s emulator-5554 shell getprop sys.boot_completed
   /home/jack/Android/Sdk/platform-tools/adb -s emulator-5554 shell input keyevent 224
   /home/jack/Android/Sdk/platform-tools/adb -s emulator-5554 shell wm dismiss-keyguard
   ```

   `sys.boot_completed=1` ne suffit pas si `input` ou `window` est introuvable :
   cette combinaison a déjà signalé une instance réellement bloquée.

3. Si l'instance est bloquée, l'arrêter proprement :

   ```bash
   /home/jack/Android/Sdk/platform-tools/adb -s emulator-5554 emu kill
   ```

   Attendre qu'elle disparaisse de `adb devices`. Ne pas tuer un autre appareil.

4. Lancer exactement le démarrage froid connu comme fiable :

   ```bash
   /home/jack/Android/Sdk/emulator/emulator -avd Pixel_5 -no-snapshot -gpu swiftshader_indirect -no-audio
   ```

   Garder le processus vivant dans une session PTY. Le démarrage complet peut
   prendre deux minutes ou davantage.

5. Attendre `Boot completed in ...`, puis confirmer avec ADB, réveiller l'écran
   et retirer le verrou comme à l'étape 2.

6. Annoncer seulement un succès vérifié : numéro ADB, démarrage complet et écran
   contrôlable. Proposer `flutter run` avec logs sans le lancer automatiquement.

## Cas particuliers et limites

- `Running multiple emulators with the same AVD` signifie qu'une ancienne
  instance existe. Ne pas contourner avec `-read-only` sauf demande de deux AVD.
- Une erreur `modem_nvram.json` n'est pas, seule, une preuve d'échec : le verdict
  vient du démarrage ADB et des services Android.
- Si le démarrage froid reste noir, recueillir les logs et demander l'accord
  avant toute réinitialisation. `-wipe-data` détruit les applications et données
  présentes dans l'émulateur.
- Les commandes graphiques et ADB peuvent nécessiter une approbation d'exécution ;
  la demander au moment de l'action, sans chercher à contourner la sandbox.

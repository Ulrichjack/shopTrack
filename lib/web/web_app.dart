import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../features/products/domain/catalogue_csv.dart';
import '../features/products/domain/entities/product_entity.dart';
import '../features/products/presentation/screens/barcode_scanner_screen.dart';

import 'web_product_form.dart';
import 'web_bilan_data.dart';
import 'web_cash_data.dart';
import 'web_cash_form.dart';
import 'web_cash_closing_form.dart';
import 'web_employees_page.dart';
import 'web_password_form.dart';
import 'web_archived_products.dart';
import 'web_cameroun_time.dart';
import 'web_product_edit_form.dart';
import 'web_product_detail.dart';
import 'web_taking_form.dart';
import 'web_journal_data.dart';
import 'web_mode_data.dart';
import 'web_navigation.dart';
import 'web_order_form.dart';
import 'web_order_price_form.dart';
import 'web_order_detail.dart';
import 'web_simple_sale_form.dart';
import 'web_simple_report_pdf.dart';
import 'web_stock_recharge_form.dart';
import 'web_theme.dart';

const _vertProfond = WebPalette.ink;
const _vertClair = WebPalette.mint;
const _fondWeb = WebPalette.canvas;

class _BoutiqueWeb {
  const _BoutiqueWeb(this.id, this.nom, this.role);
  final String id;
  final String nom;
  final String role;
}

class ShopTrackWebApp extends StatelessWidget {
  const ShopTrackWebApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ShopTrack TEST — Web',
    debugShowCheckedModeBanner: false,
    theme: webTheme(),
    home: const _WebAccueil(),
  );
}

class _WebAccueil extends StatefulWidget {
  const _WebAccueil();

  @override
  State<_WebAccueil> createState() => _WebAccueilState();
}

class _WebAccueilState extends State<_WebAccueil> {
  final _numero = TextEditingController();
  final _motDePasse = TextEditingController();
  final _confirmation = TextEditingController();
  final _nomBoutique = TextEditingController();
  final _recherche = TextEditingController();
  late final StreamSubscription<AuthState> _auth;
  List<_BoutiqueWeb> _boutiques = [];
  List<Map<String, dynamic>> _produits = [];
  WebJournalDay? _journal;
  WebInventaireData? _inventaire;
  WebCyclesData? _cycles;
  WebCommandeData? _commandes;
  WebBilanData? _bilan;
  WebCashData? _caisse;
  DateTime _jourJournal = dateCamerounMaintenant();
  DateTime _moisBilan = DateTime(
      dateCamerounMaintenant().year, dateCamerounMaintenant().month);
  WebPage _page = WebPage.accueil;
  _BoutiqueWeb? _boutique;
  bool _stockInitialAutorise = true;
  bool _modeInventaire = false;
  bool _modeCycles = false;
  bool _commandesActives = false;
  String? _erreur;
  bool _charge = false;
  bool _connexion = false;
  bool _inscription = false;
  bool _journalCharge = false;
  bool _modeCharge = false;
  bool _bilanCharge = false;
  bool _caisseCharge = false;
  bool _transfertCatalogue = false;
  String? _journalErreur;
  String? _modeErreur;
  String? _bilanErreur;
  String? _caisseErreur;
  int _requete = 0;
  int _requeteJournal = 0;
  int _requeteMode = 0;
  int _requeteBilan = 0;
  int _requeteCaisse = 0;

  SupabaseClient get _client => Supabase.instance.client;

  int get _valeurStockAchat => _produits.fold<int>(0, (total, produit) {
    final quantite = (produit['quantity'] as num?)?.toInt() ?? 0;
    final prixAchat = (produit['buy_price'] as num?)?.round() ?? 0;
    return total + prixAchat * quantite;
  });

  @override
  void initState() {
    super.initState();
    _auth = _client.auth.onAuthStateChange.listen((_) => _chargerBoutiques());
    if (_client.auth.currentSession != null) {
      _chargerBoutiques();
    }
  }

  @override
  void dispose() {
    _auth.cancel();
    _numero.dispose();
    _motDePasse.dispose();
    _confirmation.dispose();
    _nomBoutique.dispose();
    _recherche.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    final numero = _numero.text.replaceAll(' ', '').trim();
    if (numero.isEmpty || _motDePasse.text.isEmpty) {
      setState(() => _erreur = 'Saisis ton numéro et ton mot de passe.');
      return;
    }
    setState(() {
      _connexion = true;
      _erreur = null;
    });
    try {
      await _client.auth.signInWithPassword(
        email: '$numero@shoptrack.cm',
        password: _motDePasse.text.trim(),
      );
      _motDePasse.clear();
    } on AuthRetryableFetchException {
      if (mounted) {
        setState(
          () => _erreur =
              'Connexion réseau interrompue. Vérifie le Wi-Fi ou la 4G, puis réessaie.',
        );
      }
    } on AuthApiException catch (erreur) {
      if (mounted) {
        setState(
          () => _erreur = erreur.code == 'invalid_credentials'
              ? 'Numéro ou mot de passe incorrect.'
              : 'Connexion refusée par le serveur. Réessaie dans un instant.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _erreur = 'Connexion indisponible. Réessaie dans un instant.',
        );
      }
    } finally {
      if (mounted) setState(() => _connexion = false);
    }
  }

  Future<void> _creerCompte() async {
    final numero = _numero.text.replaceAll(' ', '').trim();
    final boutique = _nomBoutique.text.trim();
    final motDePasse = _motDePasse.text.trim();
    if (!RegExp(r'^[26]\d{8}$').hasMatch(numero)) {
      setState(() => _erreur = 'Entre un numéro camerounais de 9 chiffres.');
      return;
    }
    if (boutique.isEmpty) {
      setState(() => _erreur = 'Entre le nom de ta boutique.');
      return;
    }
    if (motDePasse.length < 6 || motDePasse != _confirmation.text.trim()) {
      setState(
        () => _erreur =
            'Utilise au moins 6 caractères et confirme le même mot de passe.',
      );
      return;
    }
    setState(() {
      _connexion = true;
      _erreur = null;
    });
    var compteCree = false;
    try {
      final reponse = await _client.auth.signUp(
        email: '$numero@shoptrack.cm',
        password: motDePasse,
      );
      final utilisateur = reponse.user;
      if (utilisateur == null || reponse.session == null) {
        throw StateError(
          'Le compte attend une confirmation email. '
          'La configuration du projet de test doit être corrigée.',
        );
      }
      compteCree = true;
      final nouvelleBoutique = await _client
          .from('shops')
          .insert({'owner_id': utilisateur.id, 'name': boutique})
          .select('id')
          .single();
      await _client.from('shop_members').insert({
        'shop_id': nouvelleBoutique['id'],
        'user_id': utilisateur.id,
        'role': 'owner',
      });
      _motDePasse.clear();
      _confirmation.clear();
      if (mounted) {
        setState(() => _inscription = false);
        await _chargerBoutiques();
      }
    } catch (erreur) {
      if (mounted) {
        setState(
          () => _erreur = compteCree
              ? 'Compte créé, mais la boutique n’a pas été ouverte. '
                    'Ne recrée pas le compte ; contacte le support de test.'
              : erreur is StateError
              ? erreur.message
              : erreur is AuthRetryableFetchException
              ? 'Connexion réseau interrompue. Vérifie le Wi-Fi ou la 4G, puis réessaie.'
              : erreur is AuthApiException
              ? 'Ce numéro est peut-être déjà utilisé ou le compte a été refusé.'
              : 'Création indisponible. Réessaie dans un instant.',
        );
      }
    } finally {
      if (mounted) setState(() => _connexion = false);
    }
  }

  Future<void> _ouvrirPageLegale(String page) async {
    final adresse = Uri.base.resolve('legal/$page.html');
    await launchUrl(adresse, webOnlyWindowName: '_blank');
  }

  Future<void> _chargerBoutiques() async {
    final generation = ++_requete;
    final user = _client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _boutiques = [];
          _boutique = null;
          _produits = [];
          _journal = null;
          _inventaire = null;
          _cycles = null;
          _commandes = null;
          _bilan = null;
          _caisse = null;
          _journalErreur = null;
          _erreur = null;
          _charge = false;
        });
      }
      return;
    }
    setState(() {
      _charge = true;
      _erreur = null;
    });
    try {
      final lignes = await _client
          .from('shop_members')
          .select('shop_id, role, shops(name)')
          .eq('user_id', user.id);
      if (!mounted || generation != _requete) return;
      final boutiques = (lignes as List).map((item) {
        final row = item as Map<String, dynamic>;
        final shop = row['shops'] as Map<String, dynamic>?;
        return _BoutiqueWeb(
          row['shop_id'] as String,
          (shop?['name'] as String?) ?? 'Boutique',
          (row['role'] as String?) ?? 'seller',
        );
      }).toList()..sort((a, b) => a.nom.compareTo(b.nom));
      final courante = boutiques
          .where((b) => b.id == _boutique?.id)
          .firstOrNull;
      final choisie = courante ?? (boutiques.isEmpty ? null : boutiques.first);
      setState(() {
        _boutiques = boutiques;
        _boutique = choisie;
        _charge = false;
      });
      if (choisie != null) await _chargerProduits(choisie);
    } catch (_) {
      if (mounted && generation == _requete) {
        setState(() {
          _charge = false;
          _erreur = 'Impossible de charger tes boutiques. Vérifie Internet.';
        });
      }
    }
  }

  Future<void> _chargerProduits(_BoutiqueWeb boutique) async {
    final generation = ++_requete;
    final changementBoutique = _boutique?.id != boutique.id;
    setState(() {
      _boutique = boutique;
      _charge = true;
      _erreur = null;
      _produits = [];
      if (changementBoutique) {
        _page = WebPage.accueil;
        _modeInventaire = false;
        _modeCycles = false;
        _commandesActives = false;
        _inventaire = null;
        _cycles = null;
        _commandes = null;
        _bilan = null;
        _caisse = null;
      }
    });
    _chargerJournal(boutique);
    try {
      final reglages = await _client
          .from('shop_settings')
          .select('sale_capture_mode, unit_mode, commandes_enabled')
          .eq('shop_id', boutique.id)
          .maybeSingle();
      final stockInitialAutorise =
          reglages?['sale_capture_mode'] != 'periodic' &&
          reglages?['unit_mode'] != 'hierarchical';
      final champs = boutique.role == 'owner' && stockInitialAutorise
          ? 'id, name, sell_price, buy_price, quantity, unit, barcode, min_quantity, photo_url, updated_at'
          : 'id, name, sell_price, quantity, unit, barcode, min_quantity, photo_url, updated_at';
      final lignes = <Map<String, dynamic>>[];
      // PostgREST limite une réponse à 1 000 lignes par défaut. Charger tout
      // le catalogue évite une valeur de stock ou une recherche tronquée.
      for (var debut = 0; ; debut += 500) {
        final page = await _client
            .from('products')
            .select(champs)
            .eq('shop_id', boutique.id)
            .isFilter('archived_at', null)
            .order('name')
            .order('id')
            .range(debut, debut + 499);
        lignes.addAll(page);
        if (page.length < 500) break;
      }
      if (mounted && generation == _requete) {
        setState(() {
          _produits = lignes;
          _modeInventaire = reglages?['sale_capture_mode'] == 'periodic';
          _modeCycles = reglages?['unit_mode'] == 'hierarchical';
          _commandesActives = reglages?['commandes_enabled'] == true;
          _stockInitialAutorise = stockInitialAutorise;
          if ((_modeInventaire && _page == WebPage.journal) ||
              (!_modeInventaire && _page == WebPage.inventaire) ||
              ((!_modeCycles || boutique.role != 'owner') &&
                  _page == WebPage.cycles) ||
              (!_commandesActives && _page == WebPage.commandes)) {
            _page = WebPage.accueil;
          }
          _charge = false;
        });
        _chargerDonneesMode(boutique);
        if (stockInitialAutorise) _chargerCaisse(boutique);
      }
    } catch (_) {
      if (mounted && generation == _requete) {
        setState(() {
          _charge = false;
          _erreur = 'Stock indisponible. Réessaie quand Internet revient.';
        });
      }
    }
  }

  Future<void> _chargerDonneesMode(_BoutiqueWeb boutique) async {
    final generation = ++_requeteMode;
    setState(() {
      _modeCharge = true;
      _modeErreur = null;
      _inventaire = null;
      _cycles = null;
      _commandes = null;
    });
    try {
      final inventaire = _modeInventaire
          ? await chargerInventaireWeb(_client, boutique.id)
          : null;
      final cycles = _modeCycles && boutique.role == 'owner'
          ? await chargerCyclesWeb(_client, boutique.id)
          : null;
      final commandes = _commandesActives
          ? await chargerCommandesWeb(_client, boutique.id)
          : null;
      if (!mounted ||
          generation != _requeteMode ||
          boutique.id != _boutique?.id) {
        return;
      }
      setState(() {
        _inventaire = inventaire;
        _cycles = cycles;
        _commandes = commandes;
        _modeCharge = false;
      });
    } catch (_) {
      if (!mounted ||
          generation != _requeteMode ||
          boutique.id != _boutique?.id) {
        return;
      }
      setState(() {
        _modeCharge = false;
        _modeErreur =
            'Données du module indisponibles. Vérifie Internet puis actualise.';
      });
    }
  }

  Future<void> _chargerJournal(_BoutiqueWeb boutique) async {
    final generation = ++_requeteJournal;
    final jour = _jourJournal;
    setState(() {
      _journalCharge = true;
      _journalErreur = null;
      _journal = null;
    });
    try {
      final resultat = await chargerJournalWeb(_client, boutique.id, jour);
      if (!mounted ||
          generation != _requeteJournal ||
          boutique.id != _boutique?.id) {
        return;
      }
      setState(() {
        _journal = resultat;
        _journalCharge = false;
      });
    } catch (_) {
      if (!mounted ||
          generation != _requeteJournal ||
          boutique.id != _boutique?.id) {
        return;
      }
      setState(() {
        _journalCharge = false;
        _journalErreur =
            'Journal indisponible. Vérifie Internet puis actualise.';
      });
    }
  }

  Future<void> _chargerBilan(_BoutiqueWeb boutique) async {
    if (boutique.role != 'owner') return;
    final generation = ++_requeteBilan;
    final mois = _moisBilan;
    setState(() {
      _bilanCharge = true;
      _bilanErreur = null;
      _bilan = null;
    });
    try {
      final bilan = await chargerBilanWeb(
        _client,
        shopId: boutique.id,
        mois: mois,
        inventairePeriodique: _modeInventaire,
        commandesActives: _commandesActives,
      );
      if (!mounted ||
          generation != _requeteBilan ||
          boutique.id != _boutique?.id) {
        return;
      }
      setState(() {
        _bilan = bilan;
        _bilanCharge = false;
      });
    } catch (_) {
      if (!mounted ||
          generation != _requeteBilan ||
          boutique.id != _boutique?.id) {
        return;
      }
      setState(() {
        _bilanCharge = false;
        _bilanErreur = 'Bilan indisponible. Vérifie Internet puis actualise.';
      });
    }
  }

  Future<void> _chargerCaisse(_BoutiqueWeb boutique) async {
    if (!_stockInitialAutorise) return;
    final generation = ++_requeteCaisse;
    setState(() {
      _caisseCharge = true;
      _caisseErreur = null;
    });
    try {
      final resultat = await chargerCaisseWeb(
        _client,
        shopId: boutique.id,
        estPatron: boutique.role == 'owner',
      );
      if (!mounted || generation != _requeteCaisse ||
          boutique.id != _boutique?.id) return;
      setState(() {
        _caisse = resultat;
        _caisseCharge = false;
      });
    } catch (_) {
      if (!mounted || generation != _requeteCaisse ||
          boutique.id != _boutique?.id) return;
      setState(() {
        _caisseCharge = false;
        _caisseErreur = 'Caisse indisponible. Vérifie Internet puis actualise.';
      });
    }
  }

  Future<void> _ouvrirMouvementCaisse({required bool soldeInitial}) async {
    final boutique = _boutique;
    if (boutique == null || !_stockInitialAutorise) return;
    if (soldeInitial && (_caisse?.aDesOperations ?? true)) return;
    final formulaire = WebCashForm(
      shopId: boutique.id,
      estPatron: boutique.role == 'owner',
      soldeInitial: soldeInitial,
    );
    final bool? enregistre;
    if (MediaQuery.sizeOf(context).width < 650) {
      enregistre = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => formulaire,
      );
    } else {
      enregistre = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
            child: formulaire,
          ),
        ),
      );
    }
    if (enregistre == true && mounted) {
      await _chargerCaisse(boutique);
      await _chargerJournal(boutique);
    }
  }

  Future<void> _ouvrirClotureCaisse() async {
    final boutique = _boutique;
    final caisse = _caisse;
    if (boutique == null || caisse == null || !_stockInitialAutorise ||
        caisse.clotureAujourdhui) return;
    final formulaire = WebCashClosingForm(
      shopId: boutique.id,
      soldeCalcule: caisse.totaux.calculatedCash.round(),
    );
    final bool? enregistre;
    if (MediaQuery.sizeOf(context).width < 650) {
      enregistre = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => formulaire,
      );
    } else {
      enregistre = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
            child: formulaire,
          ),
        ),
      );
    }
    if (enregistre == true && mounted && _boutique?.id == boutique.id) {
      await _chargerCaisse(boutique);
      await _chargerJournal(boutique);
      await _chargerBilan(boutique);
    }
  }

  Future<void> _ouvrirMotDePasse() async {
    final formulaire = const WebPasswordForm();
    final bool? change;
    if (MediaQuery.sizeOf(context).width < 650) {
      change = await showModalBottomSheet<bool>(context: context,
        isScrollControlled: true, useSafeArea: true, showDragHandle: true,
        builder: (_) => formulaire);
    } else {
      change = await showDialog<bool>(context: context,
        builder: (_) => Dialog(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: formulaire,
        )));
    }
    if (change == true && mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe changé.')),
    );
  }

  void _changerMoisBilan(int decalage) {
    final nouveau = DateTime(_moisBilan.year, _moisBilan.month + decalage);
    final courant = dateCamerounMaintenant();
    if (nouveau.isAfter(DateTime(courant.year, courant.month))) return;
    setState(() => _moisBilan = nouveau);
    final boutique = _boutique;
    if (boutique != null) _chargerBilan(boutique);
  }

  Future<void> _scannerCatalogue() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (!mounted || code == null || code.trim().isEmpty) return;
    setState(() {
      _recherche.text = code.trim();
      _page = WebPage.stock;
    });
  }

  void _changerJourJournal(int decalage) {
    final nouveau = DateTime(
      _jourJournal.year,
      _jourJournal.month,
      _jourJournal.day + decalage,
    );
    if (nouveau.isAfter(dateCamerounMaintenant())) return;
    setState(() => _jourJournal = nouveau);
    final boutique = _boutique;
    if (boutique != null) _chargerJournal(boutique);
  }

  Future<void> _choisirJourJournal() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _jourJournal,
      firstDate: DateTime(2023),
      lastDate: dateCamerounMaintenant(),
    );
    if (date == null || !mounted) return;
    setState(() => _jourJournal = date);
    final boutique = _boutique;
    if (boutique != null) _chargerJournal(boutique);
  }

  Future<void> _ouvrirCreationProduit() async {
    final boutique = _boutique;
    if (boutique == null || boutique.role != 'owner') return;
    final formulaire = WebProductForm(
      shopId: boutique.id,
      estPatron: boutique.role == 'owner',
      stockInitialAutorise: _stockInitialAutorise,
    );
    final bool? ajoute;
    if (MediaQuery.sizeOf(context).width < 650) {
      ajoute = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => formulaire,
      );
    } else {
      ajoute = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 750),
            child: formulaire,
          ),
        ),
      );
    }
    if (ajoute == true && mounted) await _chargerProduits(boutique);
  }

  List<ProductEntity> _produitsPourCsv(_BoutiqueWeb boutique) => [
    for (final produit in _produits)
      ProductEntity(
        id: produit['id'] as String,
        shopId: boutique.id,
        name: produit['name'] as String? ?? '',
        buyPrice: ((produit['buy_price'] as num?) ?? 0).toDouble(),
        sellPrice: ((produit['sell_price'] as num?) ?? 0).toDouble(),
        quantity: ((produit['quantity'] as num?) ?? 0).toInt(),
        minQuantity: ((produit['min_quantity'] as num?) ?? 2).toInt(),
        barcode: produit['barcode'] as String?,
        unit: produit['unit'] as String?,
      ),
  ];

  Future<void> _exporterCatalogue({required bool modele}) async {
    final boutique = _boutique;
    if (boutique == null || boutique.role != 'owner' || !_stockInitialAutorise) return;
    try {
      final contenu = ecrireCatalogueCsv(
        modele ? <ProductEntity>[] : _produitsPourCsv(boutique),
        stockInitialAutorise: true,
      );
      await FilePicker.saveFile(
        fileName: modele ? 'modele_catalogue_shoptrack.csv'
            : 'catalogue_shoptrack.csv',
        bytes: Uint8List.fromList(utf8.encode(contenu)),
        mimeType: 'text/csv',
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Export CSV impossible sur ce navigateur.'),
      ));
    }
  }

  Future<void> _importerCatalogue() async {
    final boutique = _boutique;
    if (boutique == null || boutique.role != 'owner' ||
        !_stockInitialAutorise || _transfertCatalogue) return;
    try {
      final fichier = await FilePicker.pickFile(
        type: FileType.custom, allowedExtensions: ['csv']);
      if (fichier == null) return;
      final taille = await fichier.length();
      if (taille != null && taille > 1024 * 1024) {
        throw const FormatException('Fichier trop grand : limite de 1 Mo.');
      }
      final octets = await fichier.readAsBytes();
      if (octets.length > 1024 * 1024) {
        throw const FormatException('Fichier trop grand : limite de 1 Mo.');
      }
      final contenu = utf8.decode(octets);
      final resultat = lireCatalogueCsv(contenu,
        stockInitialAutorise: true,
        produitsExistants: _produitsPourCsv(boutique));
      if (!mounted || _boutique?.id != boutique.id) return;
      if (!resultat.estValide) {
        await showDialog<void>(context: context, builder: (dialogue) => AlertDialog(
          title: const Text('Fichier à corriger'),
          content: SingleChildScrollView(child: Text(resultat.erreurs.take(15).join('\n'))),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogue),
              child: const Text('Fermer'))],
        ));
        return;
      }
      final confirme = await showDialog<bool>(context: context,
        builder: (dialogue) => AlertDialog(
          title: const Text('Importer le catalogue ?'),
          content: Text('${resultat.lignes.length} produits seront ajoutés. '
              'Les produits existants ne seront pas modifiés.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogue, false),
                child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(dialogue, true),
                child: const Text('Importer')),
          ],
        ));
      if (confirme != true || !mounted || _boutique?.id != boutique.id) return;
      setState(() => _transfertCatalogue = true);
      final uuid = const Uuid();
      final lignes = [
        for (final ligne in resultat.lignes)
          {
            'id': uuid.v5(Namespace.url.value,
                'shoptrack-csv:${boutique.id}:${ligne.nom.trim().toLowerCase()}'),
            'shop_id': boutique.id,
            'name': ligne.nom,
            'buy_price': ligne.prixAchat,
            'sell_price': ligne.prixVente,
            'quantity': ligne.quantite,
            'min_quantity': ligne.alerteStockBas,
            'barcode': ligne.codeBarres ??
                'QR-${uuid.v5(Namespace.url.value, 'shoptrack-csv:${boutique.id}:${ligne.nom.trim().toLowerCase()}')}',
            'unit': ligne.unite,
            'is_ingredient': false,
          },
      ];
      // Un seul INSERT pour tout le fichier : PostgreSQL valide ou annule
      // l'ensemble. Les UUID stables empêchent un nouvel import après une
      // réponse réseau perdue de créer des doublons silencieux.
      await _client.from('products').insert(lignes);
      if (mounted && _boutique?.id == boutique.id) {
        await _chargerProduits(boutique);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${lignes.length} produits ajoutés.'),
        ));
      }
    } on FormatException catch (erreur) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(erreur.message),
      ));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Import non confirmé. Actualise le stock avant de réessayer.'),
      ));
    } finally {
      if (mounted) setState(() => _transfertCatalogue = false);
    }
  }

  Future<void> _ouvrirVente() async {
    final boutique = _boutique;
    if (boutique == null || !_stockInitialAutorise) return;
    final formulaire = WebSimpleSaleForm(
      shopId: boutique.id,
      produits: _produits,
    );
    final bool? enregistree;
    if (MediaQuery.sizeOf(context).width < 650) {
      enregistree = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => formulaire,
      );
    } else {
      enregistree = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
            child: formulaire,
          ),
        ),
      );
    }
    if (enregistree == true && mounted) await _chargerProduits(boutique);
  }

  Future<void> _ouvrirModificationProduit(Map<String, dynamic> produit) async {
    final boutique = _boutique;
    if (boutique == null || boutique.role != 'owner') return;
    final formulaire = WebProductEditForm(
      shopId: boutique.id,
      produit: produit,
      autoriserPrix: _stockInitialAutorise,
    );
    final bool? modifie;
    if (MediaQuery.sizeOf(context).width < 650) {
      modifie = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => formulaire,
      );
    } else {
      modifie = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 750),
            child: formulaire,
          ),
        ),
      );
    }
    if (modifie == true && mounted) await _chargerProduits(boutique);
  }

  Future<void> _ouvrirFicheProduit(Map<String, dynamic> produit) async {
    final estPatron = _boutique?.role == 'owner';
    final fiche = WebProductDetail(
      produit: produit,
      estPatron: estPatron,
      stockInitialAutorise: _stockInitialAutorise,
      shopId: _boutique!.id,
    );
    final WebProductDetailAction? action;
    if (MediaQuery.sizeOf(context).width < 650) {
      action = await showModalBottomSheet<WebProductDetailAction>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => fiche,
      );
    } else {
      action = await showDialog<WebProductDetailAction>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
            child: fiche,
          ),
        ),
      );
    }
    if (!mounted || _boutique == null) return;
    if (action == WebProductDetailAction.modifier) {
      await _ouvrirModificationProduit(produit);
    } else if (action == WebProductDetailAction.photo) {
      await _chargerProduits(_boutique!);
    } else if (action == WebProductDetailAction.recharge) {
      await _ouvrirRechargeProduit(produit);
    } else if (action == WebProductDetailAction.archiver) {
      await _archiverProduit(produit);
    }
  }

  Future<void> _ouvrirRechargeProduit(Map<String, dynamic> produit) async {
    final boutique = _boutique;
    if (boutique == null || boutique.role != 'owner' || !_stockInitialAutorise) return;
    final formulaire = WebStockRechargeForm(shopId: boutique.id, produit: produit);
    final bool? ajoute;
    if (MediaQuery.sizeOf(context).width < 650) {
      ajoute = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => formulaire,
      );
    } else {
      ajoute = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 490),
            child: formulaire,
          ),
        ),
      );
    }
    if (ajoute == true && mounted && _boutique?.id == boutique.id) {
      await _chargerProduits(boutique);
    }
  }

  Future<void> _archiverProduit(Map<String, dynamic> produit) async {
    final boutique = _boutique;
    if (boutique == null || boutique.role != 'owner' || !_stockInitialAutorise) return;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogue) => AlertDialog(
        title: const Text('Archiver ce produit ?'),
        content: Text('${produit['name']} ne sera plus proposé à la vente. '
            'Son historique restera disponible dans les anciennes ventes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogue, false),
              child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(dialogue, true),
              child: const Text('Archiver')),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      final resultat = await _client.from('products')
          .update({'archived_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', produit['id'] as String)
          .eq('shop_id', boutique.id)
          .isFilter('archived_at', null)
          .select('id')
          .maybeSingle();
      if (resultat == null) throw StateError('Archivage non confirmé.');
      if (mounted && _boutique?.id == boutique.id) await _chargerProduits(boutique);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Archivage non confirmé. Vérifie Internet puis actualise le stock.'),
      ));
    }
  }

  Future<void> _ouvrirArchives() async {
    final boutique = _boutique;
    if (boutique == null || boutique.role != 'owner' || !_stockInitialAutorise) return;
    final bool? modifie;
    if (MediaQuery.sizeOf(context).width < 650) {
      modifie = await showModalBottomSheet<bool>(context: context,
        isScrollControlled: true, useSafeArea: true, showDragHandle: true,
        builder: (_) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: WebArchivedProducts(shopId: boutique.id),
        ));
    } else {
      modifie = await showDialog<bool>(context: context,
        builder: (_) => Dialog(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 650),
          child: WebArchivedProducts(shopId: boutique.id),
        )));
    }
    if (modifie == true && mounted && _boutique?.id == boutique.id) {
      await _chargerProduits(boutique);
    }
  }

  Future<void> _ouvrirRecette([Map<String, dynamic>? existante]) async {
    final boutique = _boutique;
    if (boutique == null || !_modeInventaire) return;
    final formulaire = WebTakingForm(
      shopId: boutique.id,
      dateInitiale: existante == null
          ? null
          : DateTime.parse(existante['date'] as String),
      montantInitial: (existante?['amount'] as num?)?.round(),
    );
    final bool? enregistree;
    if (MediaQuery.sizeOf(context).width < 650) {
      enregistree = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => formulaire,
      );
    } else {
      enregistree = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
            child: formulaire,
          ),
        ),
      );
    }
    if (enregistree == true && mounted) await _chargerDonneesMode(boutique);
  }

  Future<void> _ouvrirCommande() async {
    final boutique = _boutique;
    if (boutique == null || !_commandesActives) return;
    final formulaire = WebOrderForm(
      shopId: boutique.id,
      estPatron: boutique.role == 'owner',
    );
    final bool? enregistree;
    if (MediaQuery.sizeOf(context).width < 650) {
      enregistree = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => formulaire,
      );
    } else {
      enregistree = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 570, maxHeight: 780),
            child: formulaire,
          ),
        ),
      );
    }
    if (enregistree == true && mounted) await _chargerDonneesMode(boutique);
  }

  Future<void> _ouvrirPrixCommande(Map<String, dynamic> dossier) async {
    final boutique = _boutique;
    if (boutique == null || boutique.role != 'owner') return;
    if (dossier['statut'] == 'annulee' || dossier['statut'] == 'terminee') {
      return;
    }
    final formulaire = WebOrderPriceForm(shopId: boutique.id, dossier: dossier);
    final bool? enregistree;
    if (MediaQuery.sizeOf(context).width < 650) {
      enregistree = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => formulaire,
      );
    } else {
      enregistree = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
            child: formulaire,
          ),
        ),
      );
    }
    if (enregistree == true && mounted) await _chargerDonneesMode(boutique);
  }

  Future<void> _ouvrirDetailCommande(Map<String, dynamic> dossier) async {
    final boutique = _boutique;
    if (boutique == null) return;
    final fiche = WebOrderDetail(
      shopId: boutique.id,
      dossier: dossier,
      nomClient:
          _commandes?.clients[dossier['client_id'] as String] ?? 'Client',
      estPatron: boutique.role == 'owner',
    );
    final bool? modifier;
    if (MediaQuery.sizeOf(context).width < 650) {
      modifier = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => fiche,
      );
    } else {
      modifier = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
            child: fiche,
          ),
        ),
      );
    }
    if (modifier == true && mounted) await _ouvrirPrixCommande(dossier);
  }

  @override
  Widget build(BuildContext context) {
    final connecte = _client.auth.currentSession != null;
    return Scaffold(
      backgroundColor: _fondWeb,
      body: SafeArea(
        child: connecte ? _contenuConnecte() : _formulaireConnexion(),
      ),
    );
  }

  Widget _formulaireConnexion() => LayoutBuilder(
    builder: (context, contraintes) {
      final large = contraintes.maxWidth >= 800;
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(large ? 28 : 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: large
                ? SizedBox(
                    height: _inscription ? 690 : 590,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 11, child: _panneauAccueil(large: true)),
                        const SizedBox(width: 0),
                        Expanded(flex: 9, child: _carteConnexion()),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _panneauAccueil(large: false),
                      const SizedBox(height: 0),
                      _carteConnexion(),
                    ],
                  ),
          ),
        ),
      );
    },
  );

  Widget _panneauAccueil({required bool large}) => Container(
    constraints: BoxConstraints(minHeight: large ? 590 : 200),
    padding: EdgeInsets.all(large ? 44 : 24),
    decoration: BoxDecoration(
      color: WebPalette.ink,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(24),
        bottomLeft: Radius.circular(large ? 24 : 0),
        topRight: Radius.circular(large ? 0 : 24),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _marque(sombre: true),
        Padding(
          padding: EdgeInsets.symmetric(vertical: large ? 30 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Une boutique.\nUn seul catalogue.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: large ? 43 : 28,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tes produits te suivent du téléphone à l’ordinateur.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: large ? 16 : 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (large) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
            decoration: BoxDecoration(
              color: WebPalette.paper,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'APERÇU DU CATALOGUE',
                  style: TextStyle(
                    color: WebPalette.muted,
                    letterSpacing: 1.3,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _ligneApercu(
                  'Produits',
                  Icons.inventory_2_outlined,
                  WebPalette.mint,
                ),
                const Divider(color: WebPalette.line, height: 22),
                _ligneApercu(
                  'Quantités',
                  Icons.widgets_outlined,
                  const Color(0xFFF9E5C6),
                ),
                const Divider(color: WebPalette.line, height: 22),
                _ligneApercu(
                  'Prix en FCFA',
                  Icons.sell_outlined,
                  const Color(0xFFDCE7F8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WebPalette.mint.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.sync, color: _vertClair, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Le même compte que sur ShopTrack TEST Android.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  Widget _ligneApercu(String titre, IconData icone, Color fond) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icone, color: WebPalette.ink, size: 17),
      ),
      const SizedBox(width: 12),
      Text(
        titre,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: WebPalette.ink,
        ),
      ),
      const Spacer(),
      const Icon(Icons.check_circle, size: 17, color: WebPalette.pine),
    ],
  );

  Widget _carteConnexion() => Container(
    constraints: BoxConstraints(minHeight: _inscription ? 610 : 440),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topRight: MediaQuery.sizeOf(context).width >= 800
            ? const Radius.circular(24)
            : Radius.zero,
        bottomRight: const Radius.circular(24),
        bottomLeft: MediaQuery.sizeOf(context).width >= 800
            ? Radius.zero
            : const Radius.circular(24),
      ),
      border: Border.all(color: WebPalette.line),
    ),
    child: AutofillGroup(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ACCÈS À LA BOUTIQUE',
            style: TextStyle(
              color: WebPalette.pine,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _inscription ? 'Créer ma boutique' : 'Connexion',
            style: TextStyle(
              color: _vertProfond,
              fontSize: 31,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _inscription
                ? 'Crée un compte de test pour retrouver ta boutique sur Android et sur le web.'
                : 'Utilise ton compte ShopTrack TEST. Internet est requis.',
          ),
          const SizedBox(height: 24),
          if (_inscription) ...[
            TextField(
              controller: _nomBoutique,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom de la boutique',
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _numero,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(
              labelText: 'Numéro de téléphone',
              prefixText: _inscription ? '+237 ' : null,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _motDePasse,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _connexion
                ? null
                : _inscription
                ? _creerCompte()
                : _connecter(),
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          if (_inscription) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _confirmation,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Au moins 6 caractères.',
              style: TextStyle(color: Color(0xFF5D716C), fontSize: 12),
            ),
            Wrap(
              spacing: 2,
              children: [
                TextButton(
                  onPressed: () => _ouvrirPageLegale('editeur'),
                  child: const Text('Informations légales'),
                ),
                TextButton(
                  onPressed: () => _ouvrirPageLegale('confidentialite'),
                  child: const Text('Confidentialité'),
                ),
              ],
            ),
          ],
          if (_erreur != null) ...[
            const SizedBox(height: 14),
            Text(_erreur!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _connexion
                ? null
                : _inscription
                ? _creerCompte
                : _connecter,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Text(
                _connexion
                    ? 'Patiente…'
                    : _inscription
                    ? 'Créer mon compte de test'
                    : 'Ouvrir ma boutique',
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _connexion
                ? null
                : () => setState(() {
                    _inscription = !_inscription;
                    _erreur = null;
                  }),
            child: Text(
              _inscription
                  ? 'J’ai déjà un compte : me connecter'
                  : 'Nouveau ici ? Créer mon compte de test',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Version de test · Utilise uniquement des données fictives.',
            style: TextStyle(color: Color(0xFF5D716C), fontSize: 12),
          ),
        ],
      ),
    ),
  );

  Widget _contenuConnecte() {
    final largeur = MediaQuery.sizeOf(context).width;
    final large = largeur >= 860;
    final recherche = _recherche.text.trim().toLowerCase();
    final visibles = _produits.where((produit) {
      final nom = (produit['name'] as String? ?? '').toLowerCase();
      final code = (produit['barcode'] as String? ?? '').toLowerCase();
      return nom.contains(recherche) || code.contains(recherche);
    }).toList();
    final ruptures = _stockInitialAutorise
        ? _produits.where((p) => (p['quantity'] as num? ?? 0) <= 0).length
        : 0;
    final articles = _stockInitialAutorise
        ? _produits.fold<int>(
            0,
            (total, p) => total + ((p['quantity'] as num?)?.toInt() ?? 0),
          )
        : 0;

    final contenu = Column(
      children: [
        _barreSuperieure(large),
        Expanded(
          child: switch (_page) {
            WebPage.accueil => _pageAccueil(large, articles, ruptures),
            WebPage.journal => _pageJournal(large),
            WebPage.caisse => _pageCaisse(large),
            WebPage.bilan => _pageBilan(large),
            WebPage.employes => WebEmployeesPage(
              shopId: _boutique!.id,
            ),
            WebPage.cycles => _pageCycles(large),
            WebPage.inventaire => _pageInventaire(large),
            WebPage.commandes => _pageCommandes(large),
            WebPage.stock => ListView.builder(
              padding: EdgeInsets.fromLTRB(
                large ? 44 : 20,
                large ? 36 : 25,
                large ? 44 : 20,
                40,
              ),
              itemCount: visibles.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _enteteStock(
                    large,
                    articles,
                    ruptures,
                    visibles.length,
                  );
                }
                return _ligneProduit(visibles[index - 1], large);
              },
            ),
          },
        ),
        if (!large) _navigationMobile(),
      ],
    );
    return large
        ? Row(
            children: [
              _navigationLaterale(),
              Expanded(child: contenu),
            ],
          )
        : contenu;
  }

  Widget _marque({bool sombre = false}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: sombre ? WebPalette.mint : WebPalette.pine,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          Icons.storefront_rounded,
          color: sombre ? WebPalette.ink : Colors.white,
          size: 21,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'shoptrack',
        style: TextStyle(
          fontSize: 19,
          letterSpacing: -0.6,
          fontWeight: FontWeight.w700,
          color: sombre ? Colors.white : WebPalette.ink,
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: sombre
              ? WebPalette.mint.withValues(alpha: .17)
              : WebPalette.mint,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          'TEST',
          style: TextStyle(
            color: sombre ? WebPalette.mint : WebPalette.pine,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    ],
  );

  Widget _navigationLaterale() => Container(
    width: 236,
    decoration: const BoxDecoration(
      color: WebPalette.ink,
      border: Border(right: BorderSide(color: Color(0xFF285057))),
    ),
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 25),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _marque(sombre: true),
        const SizedBox(height: 48),
        const Padding(
          padding: EdgeInsets.only(left: 12, bottom: 12),
          child: Text(
            'ESPACE BOUTIQUE',
            style: TextStyle(
              color: Color(0xFF9AB8B3),
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final destination in _destinations) ...[
          _itemNavigation(
            destination.page,
            destination.label == 'Stock' ? 'Mon stock' : destination.label,
            destination.icon,
          ),
          const SizedBox(height: 6),
        ],
        const Spacer(),
        const Divider(color: Color(0xFF315057)),
        const SizedBox(height: 14),
        const Text(
          'La même boutique sur Android et sur le web de test.',
          style: TextStyle(color: Color(0xFFA9C3BE), fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: _ouvrirMotDePasse,
          icon: const Icon(Icons.lock_reset_outlined, size: 18),
          label: const Text('Changer mon mot de passe'),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
        ),
        TextButton.icon(
          onPressed: () => _client.auth.signOut(),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Se déconnecter'),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
        ),
      ],
    ),
  );

  List<WebDestination> get _destinations => destinationsWeb(
    inventairePeriodique: _modeInventaire,
    cyclesActifs: _modeCycles,
    commandesActives: _commandesActives,
    estPatron: _boutique?.role == 'owner',
  );

  void _naviguer(WebPage destination) {
    if (!_destinations.any((item) => item.page == destination)) return;
    setState(() => _page = destination);
    if (destination == WebPage.bilan && _boutique != null) {
      _chargerBilan(_boutique!);
    }
    if (destination == WebPage.accueil) {
      final maintenant = dateCamerounMaintenant();
      if (_jourJournal.year != maintenant.year ||
          _jourJournal.month != maintenant.month ||
          _jourJournal.day != maintenant.day) {
        _jourJournal = maintenant;
        final boutique = _boutique;
        if (boutique != null) _chargerJournal(boutique);
      }
    }
  }

  Widget _itemNavigation(WebPage page, String titre, IconData icone) {
    final actif = _page == page;
    return InkWell(
      onTap: () => _naviguer(page),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(
          color: actif
              ? WebPalette.mint.withValues(alpha: .15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Icon(
              icone,
              color: actif ? WebPalette.mint : const Color(0xFFA9C3BE),
              size: 20,
            ),
            const SizedBox(width: 11),
            Text(
              titre,
              style: TextStyle(
                color: actif ? Colors.white : const Color(0xFFA9C3BE),
                fontWeight: actif ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigationMobile() {
    final items = _destinations;
    final visibles = items.length <= 5 ? items : items.take(4).toList();
    final autres = items.length <= 5
        ? <WebDestination>[]
        : items.skip(4).toList();
    final selection = visibles.indexWhere((item) => item.page == _page);
    return NavigationBar(
      backgroundColor: WebPalette.paper,
      elevation: 4,
      height: 68,
      selectedIndex: selection < 0 ? (autres.isEmpty ? 0 : 4) : selection,
      onDestinationSelected: (index) {
        if (index < visibles.length) {
          _naviguer(visibles[index].page);
          return;
        }
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in autres)
                  ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    selected: item.page == _page,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _naviguer(item.page);
                    },
                  ),
              ],
            ),
          ),
        );
      },
      destinations: [
        for (final item in visibles)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
        if (autres.isNotEmpty)
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Plus',
          ),
      ],
    );
  }

  Widget _pageAccueil(bool large, int articles, int ruptures) {
    final entrees =
        _journal?.entrees.take(3).toList() ?? const <WebJournalEntry>[];
    return ListView(
      padding: EdgeInsets.fromLTRB(
        large ? 44 : 20,
        large ? 36 : 25,
        large ? 44 : 20,
        40,
      ),
      children: [
        const Text(
          'AUJOURD’HUI',
          style: TextStyle(
            color: WebPalette.pine,
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Bonjour, ta boutique est là.',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontSize: large ? 38 : 30),
        ),
        const SizedBox(height: 7),
        Text(
          _boutique?.nom ?? 'Boutique',
          style: const TextStyle(color: WebPalette.muted, fontSize: 15),
        ),
        if (_stockInitialAutorise) ...[
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _charge ? null : _ouvrirVente,
              icon: const Icon(Icons.point_of_sale_outlined),
              label: const Text('Nouvelle vente'),
            ),
          ),
        ],
        const SizedBox(height: 29),
        Wrap(
          spacing: 11,
          runSpacing: 11,
          children: [
            _indicateur(
              '${_produits.length}',
              'produits',
              Icons.inventory_2_outlined,
            ),
            if (_stockInitialAutorise)
              _indicateur(
                '$articles',
                'articles en stock',
                Icons.widgets_outlined,
              ),
            if (_stockInitialAutorise)
              _indicateur(
                '$ruptures',
                'ruptures',
                Icons.error_outline_rounded,
                alerte: ruptures > 0,
              ),
            if (_stockInitialAutorise && _caisse != null)
              _indicateur(
                '${NumberFormat.decimalPattern('fr_FR').format(_caisse!.totaux.calculatedCash.round())} FCFA',
                'caisse calculée',
                Icons.account_balance_wallet_outlined,
              ),
            if (_boutique?.role == 'owner' && _stockInitialAutorise)
              _indicateur(
                '${NumberFormat.decimalPattern('fr_FR').format(_valeurStockAchat)} FCFA',
                'valeur du stock (achat)',
                Icons.account_balance_wallet_outlined,
              ),
            if (!_modeInventaire) ...[
              _indicateur(
                '${_journal?.nombreVentes ?? '—'}',
                'ventes synchronisées',
                Icons.shopping_bag_outlined,
              ),
              _indicateur(
                _journal == null ? '—' : '${_journal!.totalVentes} FCFA',
                'total des ventes',
                Icons.payments_outlined,
              ),
            ],
          ],
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: WebPalette.ink,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Wrap(
            spacing: 20,
            runSpacing: 18,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: large ? 470 : 270,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LE CATALOGUE',
                      style: TextStyle(
                        color: WebPalette.mint,
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Retrouve tes produits en un geste.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _modeInventaire
                          ? 'Les quantités se mettent à jour après le comptage d’inventaire.'
                          : 'Consulte les prix, les quantités et les ruptures de la boutique.',
                      style: const TextStyle(
                        color: Color(0xFFC5D8D4),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _naviguer(WebPage.stock),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ouvrir le stock'),
                style: FilledButton.styleFrom(
                  backgroundColor: WebPalette.mint,
                  foregroundColor: WebPalette.ink,
                ),
              ),
            ],
          ),
        ),
        if (!_modeInventaire) ...[
          const SizedBox(height: 30),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dernières opérations du jour',
                  style: TextStyle(
                    color: WebPalette.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _naviguer(WebPage.journal),
                child: const Text('Voir le journal'),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (_journalCharge) const LinearProgressIndicator(),
          if (_journalErreur != null)
            Text(
              _journalErreur!,
              style: const TextStyle(color: WebPalette.danger),
            ),
          if (!_journalCharge && _journalErreur == null && entrees.isEmpty)
            _messageVide(
              'Aucune opération synchronisée aujourd’hui.',
              'Les ventes faites hors ligne sur Android apparaîtront après synchronisation.',
            ),
          for (final entree in entrees) _carteJournal(entree),
          const SizedBox(height: 12),
          const Text(
            'Les chiffres affichent uniquement les opérations confirmées par le serveur de test.',
            style: TextStyle(color: WebPalette.muted, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _pageJournal(bool large) {
    final entrees = _journal?.entrees ?? const <WebJournalEntry>[];
    final maintenant = dateCamerounMaintenant();
    final estAujourdhui =
        _jourJournal.year == maintenant.year &&
        _jourJournal.month == maintenant.month &&
        _jourJournal.day == maintenant.day;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        large ? 44 : 20,
        large ? 36 : 25,
        large ? 44 : 20,
        40,
      ),
      itemCount: entrees.length + 1,
      itemBuilder: (context, index) {
        if (index > 0) return _carteJournal(entrees[index - 1]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OPÉRATIONS',
              style: TextStyle(
                color: WebPalette.pine,
                fontSize: 11,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Journal',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontSize: large ? 38 : 31),
            ),
            const SizedBox(height: 7),
            const Text(
              'Ventes et mouvements de caisse synchronisés · heure du Cameroun.',
              style: TextStyle(color: WebPalette.muted),
            ),
            if (_stockInitialAutorise) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _charge ? null : _ouvrirVente,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Nouvelle vente'),
              ),
            ],
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: WebPalette.paper,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: WebPalette.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Jour précédent',
                    onPressed: () => _changerJourJournal(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: _choisirJourJournal,
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    label: Text(
                      estAujourdhui
                          ? 'Aujourd’hui'
                          : DateFormat('dd/MM/yyyy').format(_jourJournal),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Jour suivant',
                    onPressed: estAujourdhui
                        ? null
                        : () => _changerJourJournal(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    tooltip: 'Actualiser',
                    onPressed: _boutique == null
                        ? null
                        : () => _chargerJournal(_boutique!),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_journalCharge) const LinearProgressIndicator(),
            if (_journalErreur != null)
              Text(
                _journalErreur!,
                style: const TextStyle(color: WebPalette.danger),
              ),
            if (!_journalCharge && _journalErreur == null && entrees.isEmpty)
              _messageVide(
                'Aucune opération ce jour-là.',
                'Choisis un autre jour ou synchronise Android.',
              ),
            if (entrees.isNotEmpty) ...[
              Text(
                '${_journal?.nombreVentes ?? 0} vente(s) · ${_journal?.totalVentes ?? 0} FCFA de ventes',
                style: const TextStyle(color: WebPalette.muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }

  Widget _pageCaisse(bool large) {
    final caisse = _caisse;
    String fcfa(num montant) =>
        '${NumberFormat.decimalPattern('fr_FR').format(montant.round())} FCFA';
    return ListView(
      padding: EdgeInsets.fromLTRB(
        large ? 44 : 20,
        large ? 36 : 25,
        large ? 44 : 20,
        40,
      ),
      children: [
        const Text('ARGENT DU TIROIR', style: TextStyle(
          color: WebPalette.pine, fontSize: 11,
          letterSpacing: 1.6, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 9),
        Text('Caisse', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text('Solde continu calculé depuis la dernière clôture et les opérations synchronisées.',
          style: TextStyle(color: WebPalette.muted)),
        const SizedBox(height: 22),
        if (_caisseCharge) const LinearProgressIndicator(),
        if (_caisseErreur != null)
          Text(_caisseErreur!, style: const TextStyle(color: WebPalette.danger)),
        if (caisse != null) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: WebPalette.ink,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SOLDE CALCULÉ', style: TextStyle(
                  color: WebPalette.mint, fontSize: 11,
                  letterSpacing: 1.4, fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 8),
                Text(fcfa(caisse.totaux.calculatedCash), style: const TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 8),
                const Text('Ce montant est théorique tant que le tiroir n’a pas été compté.',
                  style: TextStyle(color: Color(0xFFC5D8D4))),
              ],
            ),
          ),
          const SizedBox(height: 17),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              _indicateur(fcfa(caisse.totaux.totalSales), 'ventes depuis le repère', Icons.shopping_bag_outlined),
              _indicateur(fcfa(caisse.totaux.totalIncoming), 'autres entrées', Icons.south_west),
              _indicateur(fcfa(caisse.totaux.totalWithdrawals), 'sorties', Icons.north_east),
            ],
          ),
          if (caisse.derniereCloture != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: WebPalette.paper,
                border: Border.all(color: WebPalette.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dernière clôture : ${caisse.derniereCloture!['closing_date']}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 7),
                  Text('Compté : ${fcfa((caisse.derniereCloture!['physical_cash'] as num?) ?? 0)}'),
                  Text('Écart : ${fcfa((caisse.derniereCloture!['cash_gap'] as num?) ?? 0)}'),
                  if ((caisse.derniereCloture!['note'] as String?)?.isNotEmpty == true)
                    Text('Note : ${caisse.derniereCloture!['note']}'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => _ouvrirMouvementCaisse(soldeInitial: false),
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Enregistrer une sortie'),
              ),
              if (!caisse.aDesOperations)
                OutlinedButton.icon(
                  onPressed: () => _ouvrirMouvementCaisse(soldeInitial: true),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Définir le solde de départ'),
                ),
              if (!caisse.clotureAujourdhui)
                OutlinedButton.icon(
                  onPressed: _ouvrirClotureCaisse,
                  icon: const Icon(Icons.task_alt_outlined),
                  label: const Text('Clôturer la journée'),
                )
              else
                const Chip(label: Text('Journée clôturée')),
              IconButton(
                tooltip: 'Actualiser la caisse',
                onPressed: _boutique == null ? null : () => _chargerCaisse(_boutique!),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Derniers mouvements', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          if (caisse.mouvementsRecents.isEmpty)
            const Text('Aucun mouvement de caisse enregistré.'),
          for (final mouvement in caisse.mouvementsRecents)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                mouvement['type'] == 'withdrawal'
                    ? Icons.north_east : Icons.south_west,
                color: WebPalette.pine,
              ),
              title: Text(mouvement['category'] as String? ??
                  (mouvement['type'] == 'morning_balance'
                      ? 'Solde de départ' : 'Mouvement')),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(
                heureCameroun(DateTime.parse(mouvement['created_at'] as String)))),
              trailing: Text(fcfa(mouvement['amount'] as num)),
            ),
        ],
      ],
    );
  }

  Widget _pageBilan(bool large) {
    final bilan = _bilan;
    final maintenant = dateCamerounMaintenant();
    final moisCourant =
        _moisBilan.year == maintenant.year &&
        _moisBilan.month == maintenant.month;
    String fcfa(int montant) =>
        '${NumberFormat.decimalPattern('fr_FR').format(montant)} FCFA';
    return ListView(
      padding: EdgeInsets.fromLTRB(
        large ? 44 : 20,
        large ? 36 : 25,
        large ? 44 : 20,
        40,
      ),
      children: [
        const Text(
          'CHIFFRES DE LA BOUTIQUE',
          style: TextStyle(
            color: WebPalette.pine,
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Text('Bilan', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text(
          'Montants enregistrés sur le serveur de test. Les commandes ont leur propre bilan.',
          style: TextStyle(color: WebPalette.muted),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: WebPalette.ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Mois précédent',
                onPressed: () => _changerMoisBilan(-1),
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', 'fr').format(_moisBilan),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Mois suivant',
                onPressed: moisCourant ? null : () => _changerMoisBilan(1),
                icon: Icon(
                  Icons.chevron_right,
                  color: moisCourant ? Colors.white38 : Colors.white,
                ),
              ),
              IconButton(
                tooltip: 'Actualiser le bilan',
                onPressed: _boutique == null
                    ? null
                    : () => _chargerBilan(_boutique!),
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        ),
        if (_bilanCharge) ...[
          const SizedBox(height: 20),
          const LinearProgressIndicator(),
        ],
        if (_bilanErreur != null) ...[
          const SizedBox(height: 20),
          Text(_bilanErreur!, style: const TextStyle(color: WebPalette.danger)),
        ],
        if (bilan != null) ...[
          const SizedBox(height: 25),
          if (_stockInitialAutorise && !_modeInventaire) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await imprimerBilanSimpleWeb(
                      nomBoutique: _boutique?.nom ?? 'Boutique',
                      mois: _moisBilan,
                      bilan: bilan,
                    );
                  } catch (_) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export PDF indisponible sur ce navigateur.')),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Exporter le résumé PDF'),
              ),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            _modeInventaire ? 'Recettes déclarées' : 'Ventes du mois',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _modeInventaire
                ? [
                    _indicateur(
                      fcfa(bilan.totalRecettes),
                      'recettes déclarées',
                      Icons.payments_outlined,
                    ),
                    _indicateur(
                      '${bilan.nombreRecettes}',
                      'journées saisies',
                      Icons.event_note_outlined,
                    ),
                  ]
                : [
                    _indicateur(
                      fcfa(bilan.totalVentes),
                      'ventes enregistrées',
                      Icons.payments_outlined,
                    ),
                    _indicateur(
                      '${bilan.nombreVentes}',
                      'ventes',
                      Icons.receipt_long_outlined,
                    ),
                  ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Ce total ne représente ni le bénéfice ni le solde de caisse.',
            style: TextStyle(color: WebPalette.muted, fontSize: 12),
          ),
          if (_stockInitialAutorise && !_modeInventaire) ...[
            const SizedBox(height: 29),
            Text('Résultat du mois',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: [
              if (bilan.beneficeBrutVentes != null)
                _indicateur(fcfa(bilan.beneficeBrutVentes!),
                    'marge brute des ventes', Icons.trending_up_outlined),
              _indicateur(fcfa(bilan.depenses), 'dépenses de caisse',
                  Icons.receipt_long_outlined),
              if (bilan.beneficeNetVentes != null)
                _indicateur(fcfa(bilan.beneficeNetVentes!),
                    'bénéfice après dépenses', Icons.account_balance_outlined),
              _indicateur(fcfa(bilan.deplacements),
                  'argent déplacé hors du tiroir', Icons.swap_horiz),
            ]),
            if (bilan.beneficeBrutVentes == null) ...[
              const SizedBox(height: 10),
              const Text('Certaines ventes n’ont pas de coût connu : le bénéfice est masqué.',
                  style: TextStyle(color: WebPalette.danger)),
            ],
          ],
          if (_commandesActives) ...[
            const SizedBox(height: 32),
            Text(
              'Commandes livrées',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Une commande compte le mois de sa livraison, même si un acompte a été versé avant.',
              style: TextStyle(color: WebPalette.muted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _indicateur(
                  fcfa(bilan.totalCommandesLivrees),
                  'chiffre d’affaires commandes',
                  Icons.shopping_bag_outlined,
                ),
                _indicateur(
                  '${bilan.commandesLivrees}',
                  'livrées',
                  Icons.task_alt_outlined,
                ),
                _indicateur(
                  fcfa(bilan.encoreDuCommandes),
                  'encore dû, toutes périodes',
                  Icons.account_balance_wallet_outlined,
                ),
                if (bilan.beneficeCommandes != null)
                  _indicateur(
                    fcfa(bilan.beneficeCommandes!),
                    'bénéfice commandes',
                    Icons.trending_up_outlined,
                  ),
              ],
            ),
            if (bilan.commandesSansCout > 0) ...[
              const SizedBox(height: 12),
              Text(
                '${bilan.commandesSansCout} commande(s) livrée(s) sans coût saisi : bénéfice non calculable.',
                style: const TextStyle(
                  color: WebPalette.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _messageVide(String titre, String suite) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: WebPalette.paper,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: WebPalette.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          color: WebPalette.pine,
          size: 27,
        ),
        const SizedBox(height: 9),
        Text(
          titre,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 5),
        Text(suite, style: const TextStyle(color: WebPalette.muted)),
      ],
    ),
  );

  Widget _carteJournal(WebJournalEntry entree) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: WebPalette.paper,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: WebPalette.line),
    ),
    child: ExpansionTile(
      key: ValueKey(entree.id),
      leading: Icon(
        entree.estVente
            ? Icons.shopping_bag_outlined
            : Icons.account_balance_wallet_outlined,
        color: WebPalette.pine,
      ),
      title: Text(
        entree.titre,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        DateFormat('HH:mm').format(entree.date),
        style: const TextStyle(color: WebPalette.muted, fontSize: 12),
      ),
      trailing: Text(
        '${entree.montant} FCFA',
        style: const TextStyle(
          color: WebPalette.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              entree.details.isEmpty
                  ? 'Aucun détail supplémentaire.'
                  : entree.details.join('\n'),
              style: const TextStyle(color: WebPalette.muted, height: 1.5),
            ),
          ),
        ),
      ],
    ),
  );

  String _nomProduit(String id) =>
      _produits
          .where((produit) => produit['id'] == id)
          .map((produit) => produit['name'] as String? ?? 'Produit')
          .firstOrNull ??
      'Produit';

  Widget _enteteModule(
    bool large,
    String etiquette,
    String titre,
    String description,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        etiquette,
        style: const TextStyle(
          color: WebPalette.pine,
          fontSize: 11,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        titre,
        style: Theme.of(
          context,
        ).textTheme.headlineLarge?.copyWith(fontSize: large ? 38 : 31),
      ),
      const SizedBox(height: 7),
      Text(
        description,
        style: const TextStyle(color: WebPalette.muted, fontSize: 14),
      ),
      const SizedBox(height: 18),
      TextButton.icon(
        onPressed: _boutique == null || _modeCharge
            ? null
            : () => _chargerDonneesMode(_boutique!),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Actualiser'),
      ),
      if (_modeCharge) const LinearProgressIndicator(),
      if (_modeErreur != null)
        Text(_modeErreur!, style: const TextStyle(color: WebPalette.danger)),
      const SizedBox(height: 16),
    ],
  );

  Widget _ligneModule({
    required IconData icone,
    required String titre,
    required String sousTitre,
    String? fin,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: WebPalette.paper,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: WebPalette.line),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: WebPalette.canvas,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, color: WebPalette.pine, size: 19),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: const TextStyle(
                  color: WebPalette.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sousTitre,
                style: const TextStyle(color: WebPalette.muted, fontSize: 12),
              ),
              if (fin != null && MediaQuery.sizeOf(context).width < 650) ...[
                const SizedBox(height: 7),
                Text(
                  fin,
                  style: const TextStyle(
                    color: WebPalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (fin != null && MediaQuery.sizeOf(context).width >= 650)
          Text(
            fin,
            style: const TextStyle(
              color: WebPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    ),
  );

  Widget _pageInventaire(bool large) {
    final recettes = _inventaire?.recettes ?? const <Map<String, dynamic>>[];
    final comptages = _inventaire?.comptages ?? const <Map<String, dynamic>>[];
    return ListView(
      padding: EdgeInsets.fromLTRB(
        large ? 44 : 20,
        large ? 36 : 25,
        large ? 44 : 20,
        40,
      ),
      children: [
        _enteteModule(
          large,
          'MODE PÉRIODIQUE',
          'Inventaire',
          'Recettes et comptages confirmés par le serveur.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _modeCharge ? null : () => _ouvrirRecette(),
            icon: const Icon(Icons.add),
            label: const Text('Noter une recette'),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _indicateur(
              '${recettes.length}',
              'recettes récentes',
              Icons.payments_outlined,
            ),
            _indicateur(
              '${comptages.length}',
              'comptages récents',
              Icons.fact_check_outlined,
            ),
          ],
        ),
        const SizedBox(height: 27),
        const Text(
          'Recettes récentes',
          style: TextStyle(
            color: WebPalette.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 11),
        if (!_modeCharge && _modeErreur == null && recettes.isEmpty)
          _messageVide(
            'Aucune recette synchronisée.',
            'Les recettes saisies sur Android apparaissent après synchronisation.',
          ),
        for (final recette in recettes.take(10))
          InkWell(
            onTap: () => _ouvrirRecette(recette),
            borderRadius: BorderRadius.circular(12),
            child: _ligneModule(
              icone: Icons.payments_outlined,
              titre: recette['date'] as String? ?? 'Jour',
              sousTitre: 'Recette de la boutique · toucher pour corriger',
              fin: '${((recette['amount'] as num?) ?? 0).round()} FCFA',
            ),
          ),
        const SizedBox(height: 25),
        const Text(
          'Derniers comptages',
          style: TextStyle(
            color: WebPalette.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 11),
        if (!_modeCharge && _modeErreur == null && comptages.isEmpty)
          _messageVide(
            'Aucun comptage synchronisé.',
            'Le premier comptage pose le point de départ de l’inventaire.',
          ),
        for (final comptage in comptages.take(15))
          _ligneModule(
            icone: Icons.fact_check_outlined,
            titre: _nomProduit(comptage['product_id'] as String),
            sousTitre: DateFormat('dd/MM/yyyy').format(
              DateTime.parse(comptage['counted_at'] as String).toLocal(),
            ),
            fin: '${comptage['counted_quantity']} compté(s)',
          ),
      ],
    );
  }

  Widget _pageCycles(bool large) {
    final cycles = _cycles?.cycles ?? const <Map<String, dynamic>>[];
    final ouverts = cycles.where((cycle) => cycle['status'] == 'open').length;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        large ? 44 : 20,
        large ? 36 : 25,
        large ? 44 : 20,
        40,
      ),
      children: [
        _enteteModule(
          large,
          'UNITÉS & ARRIVAGES',
          'Cycles',
          'Arrivages de la boutique, visibles pour le propriétaire.',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _indicateur('$ouverts', 'cycles ouverts', Icons.autorenew_outlined),
            _indicateur(
              '${cycles.length}',
              'cycles récents',
              Icons.inventory_2_outlined,
            ),
          ],
        ),
        const SizedBox(height: 27),
        const Text(
          'Arrivages récents',
          style: TextStyle(
            color: WebPalette.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 11),
        if (!_modeCharge && _modeErreur == null && cycles.isEmpty)
          _messageVide(
            'Aucun cycle synchronisé.',
            'Un arrivage créé sur Android apparaîtra ici après synchronisation.',
          ),
        for (final cycle in cycles)
          _ligneModule(
            icone: Icons.autorenew_outlined,
            titre: _nomProduit(cycle['product_id'] as String),
            sousTitre:
                '${DateFormat('dd/MM/yyyy').format(DateTime.parse(cycle['opened_at'] as String).toLocal())} · ${cycle['status'] == 'open' ? 'Ouvert' : 'Fermé'}',
            fin: '${cycle['quantity_received']} unités',
          ),
      ],
    );
  }

  Widget _pageCommandes(bool large) {
    final dossiers = _commandes?.dossiers ?? const <Map<String, dynamic>>[];
    final enCours = dossiers
        .where((d) => d['statut'] != 'terminee' && d['statut'] != 'annulee')
        .length;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        large ? 44 : 20,
        large ? 36 : 25,
        large ? 44 : 20,
        40,
      ),
      children: [
        _enteteModule(
          large,
          'DEMANDES & ACOMPTES',
          'Commandes',
          'Dossiers et soldes recalculés depuis les paiements.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _modeCharge ? null : _ouvrirCommande,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle demande'),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _indicateur('$enCours', 'à suivre', Icons.assignment_outlined),
            _indicateur(
              '${dossiers.length}',
              'dossiers récents',
              Icons.folder_outlined,
            ),
          ],
        ),
        const SizedBox(height: 27),
        const Text(
          'Dossiers récents',
          style: TextStyle(
            color: WebPalette.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 11),
        if (!_modeCharge && _modeErreur == null && dossiers.isEmpty)
          _messageVide(
            'Aucune commande synchronisée.',
            'Les demandes créées sur Android apparaissent après synchronisation.',
          ),
        for (final dossier in dossiers)
          InkWell(
            onTap: () => _ouvrirDetailCommande(dossier),
            borderRadius: BorderRadius.circular(12),
            child: _ligneModule(
              icone: Icons.assignment_outlined,
              titre:
                  _commandes?.clients[dossier['client_id'] as String] ??
                  'Client',
              sousTitre:
                  '${dossier['description']} · ${dossier['statut']} · ouvrir le dossier',
              fin: _libelleSoldeCommande(dossier),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Le solde est le prix accepté moins les paiements nets. Il ne représente pas la caisse.',
          style: TextStyle(color: WebPalette.muted, fontSize: 12),
        ),
      ],
    );
  }

  String _libelleSoldeCommande(Map<String, dynamic> dossier) {
    final solde = _commandes?.solde(dossier);
    if (solde == null) return 'Prix à fixer';
    if (solde == 0) return 'Soldée';
    if (solde < 0) return '${-solde} FCFA de trop-perçu';
    return '$solde FCFA dus';
  }

  Widget _selecteurBoutique() => DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: _boutique?.id,
      isDense: true,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      items: [
        for (final b in _boutiques)
          DropdownMenuItem(
            value: b.id,
            child: Text(b.nom, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) {
        final b = _boutiques.where((x) => x.id == id).firstOrNull;
        if (b != null) _chargerProduits(b);
      },
    ),
  );

  Widget _barreSuperieure(bool large) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: large ? 44 : 20,
      vertical: large ? 18 : 13,
    ),
    decoration: const BoxDecoration(
      color: WebPalette.paper,
      border: Border(bottom: BorderSide(color: WebPalette.line)),
    ),
    child: large
        ? Row(
            children: [
              const Text(
                'Espace boutique',
                style: TextStyle(color: WebPalette.muted, fontSize: 13),
              ),
              const Spacer(),
              if (_boutiques.isNotEmpty)
                SizedBox(width: 230, child: _selecteurBoutique()),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _marque(),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Compte',
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'logout') _client.auth.signOut();
                      if (value == 'password') _ouvrirMotDePasse();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'password',
                        child: Text('Changer mon mot de passe'),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Text('Se déconnecter'),
                      ),
                    ],
                  ),
                ],
              ),
              if (_boutiques.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 17,
                      color: WebPalette.muted,
                    ),
                    const SizedBox(width: 7),
                    Expanded(child: _selecteurBoutique()),
                  ],
                ),
              ],
            ],
          ),
  );

  Widget _enteteStock(
    bool large,
    int articles,
    int ruptures,
    int nombreVisibles,
  ) {
    final description = _stockInitialAutorise
        ? 'Ton catalogue et tes quantités à jour.'
        : 'Le stock se renseigne dans ${_modeInventaire ? 'les comptages d’inventaire' : 'les cycles'}.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CATALOGUE',
          style: TextStyle(
            color: WebPalette.pine,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 20,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mon stock',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: large ? 38 : 31,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(color: WebPalette.muted, fontSize: 14),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: _boutique?.role != 'owner' || _charge
                  ? null
                  : _ouvrirCreationProduit,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Ajouter un produit'),
            ),
            if (_boutique?.role == 'owner' && _stockInitialAutorise) ...[
              TextButton.icon(
                onPressed: _ouvrirArchives,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archives'),
              ),
              OutlinedButton.icon(
                onPressed: _transfertCatalogue || _charge
                    ? null : _importerCatalogue,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(_transfertCatalogue
                    ? 'Import en cours…' : 'Importer CSV'),
              ),
              OutlinedButton.icon(
                onPressed: () => _exporterCatalogue(modele: false),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Exporter CSV'),
              ),
              TextButton(
                onPressed: () => _exporterCatalogue(modele: true),
                child: const Text('Modèle CSV'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 25),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _indicateur(
              '${_produits.length}',
              'produits',
              Icons.inventory_2_outlined,
            ),
            if (_stockInitialAutorise)
              _indicateur('$articles', 'articles', Icons.widgets_outlined),
            if (_stockInitialAutorise)
              _indicateur(
                '$ruptures',
                'en rupture',
                Icons.error_outline_rounded,
                alerte: ruptures > 0,
              ),
            if (!_stockInitialAutorise)
              _indicateur(
                _modeInventaire ? 'Inventaire' : 'Cycles',
                'mode actif',
                Icons.tune_rounded,
              ),
            if (_boutique?.role == 'owner' && _stockInitialAutorise)
              _indicateur(
                '${NumberFormat.decimalPattern('fr_FR').format(_valeurStockAchat)} FCFA',
                'valeur du stock (achat)',
                Icons.account_balance_wallet_outlined,
              ),
          ],
        ),
        const SizedBox(height: 27),
        Container(
          padding: EdgeInsets.all(large ? 19 : 15),
          decoration: BoxDecoration(
            color: WebPalette.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WebPalette.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Produits',
                    style: TextStyle(
                      color: WebPalette.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$nombreVisibles affiché${nombreVisibles > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: WebPalette.muted,
                      fontSize: 12,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _boutique == null || _charge
                        ? null
                        : () => _chargerProduits(_boutique!),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Actualiser'),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              TextField(
                controller: _recherche,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un nom ou un code-barres',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _scannerCatalogue,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scanner un QR ou un code-barres'),
                ),
              ),
              if (_charge) ...[
                const SizedBox(height: 15),
                const LinearProgressIndicator(),
              ],
              if (_erreur != null) ...[
                const SizedBox(height: 13),
                Text(
                  _erreur!,
                  style: const TextStyle(color: WebPalette.danger),
                ),
              ],
              if (!_charge && _boutiques.isEmpty) ...[
                const SizedBox(height: 16),
                const Text('Aucune boutique accessible avec ce compte.'),
              ],
              if (!_charge &&
                  _boutique != null &&
                  _produits.isEmpty &&
                  _erreur == null) ...[
                const SizedBox(height: 26),
                const Icon(
                  Icons.inventory_2_outlined,
                  color: WebPalette.pine,
                  size: 35,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Le catalogue est vide',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 4),
                const Text('Ajoute un premier produit pour commencer.'),
                const SizedBox(height: 12),
              ],
              if (!_charge && _produits.isNotEmpty && nombreVisibles == 0) ...[
                const SizedBox(height: 20),
                const Text('Aucun produit ne correspond à ta recherche.'),
              ],
            ],
          ),
        ),
        if (nombreVisibles > 0) ...[
          const SizedBox(height: 12),
          if (large)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'PRODUIT',
                      style: TextStyle(
                        color: WebPalette.muted,
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'STOCK',
                      style: TextStyle(
                        color: WebPalette.muted,
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'PRIX DE VENTE',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: WebPalette.muted,
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _indicateur(
    String valeur,
    String libelle,
    IconData icone, {
    bool alerte = false,
  }) => Container(
    constraints: const BoxConstraints(minWidth: 145),
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
    decoration: BoxDecoration(
      color: alerte ? const Color(0xFFFFE8E1) : WebPalette.soft,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: alerte ? const Color(0xFFF0D2CB) : WebPalette.line,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icone,
          size: 20,
          color: alerte ? WebPalette.danger : WebPalette.pine,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valeur,
              style: TextStyle(
                color: alerte ? WebPalette.danger : WebPalette.ink,
                fontSize: 19,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              libelle,
              style: const TextStyle(color: WebPalette.muted, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _ligneProduit(Map<String, dynamic> produit, bool large) {
    final nom = produit['name'] as String? ?? 'Produit';
    final quantite = (produit['quantity'] as num?)?.toInt() ?? 0;
    final unite = (produit['unit'] as String?)?.trim() ?? '';
    final prix = (produit['sell_price'] as num?)?.round() ?? 0;
    final statut = _modeInventaire
        ? 'Stock géré dans Inventaire'
        : _modeCycles
        ? 'Stock géré dans Cycles'
        : '$quantite ${unite.isEmpty ? 'en stock' : unite}';
    return InkWell(
      onTap: () => _ouvrirFicheProduit(produit),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: WebPalette.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WebPalette.line),
        ),
        child: large
            ? Row(
                children: [
                  _vignetteProduit(produit, 50),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 4,
                    child: Text(
                      nom,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      statut,
                      style: TextStyle(
                        color: quantite == 0 && _stockInitialAutorise
                            ? WebPalette.danger
                            : WebPalette.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$prix FCFA',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_boutique?.role == 'owner') ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Modifier $nom',
                      onPressed: () => _ouvrirModificationProduit(produit),
                      icon: const Icon(Icons.edit_outlined, size: 19),
                    ),
                  ],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _vignetteProduit(produit, 54),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$prix FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (_boutique?.role == 'owner') ...[
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Modifier $nom',
                          onPressed: () => _ouvrirModificationProduit(produit),
                          icon: const Icon(Icons.edit_outlined, size: 19),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    statut,
                    style: TextStyle(
                      color: quantite == 0 && _stockInitialAutorise
                          ? WebPalette.danger
                          : WebPalette.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _vignetteProduit(Map<String, dynamic> produit, double taille) =>
      Container(
        width: taille,
        height: taille,
        decoration: BoxDecoration(
          color: WebPalette.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WebPalette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: WebProductPhoto(url: produit['photo_url'] as String?),
      );
}

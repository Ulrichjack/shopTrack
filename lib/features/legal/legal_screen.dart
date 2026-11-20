import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'legal_content.dart';

const publicLegalRoutes = {'/legal', '/privacy', '/account-deletion'};

/// Aucun accès à Supabase : les textes et demandes restent accessibles à une
/// personne déconnectée, hors ligne, ou avec un mot de passe provisoire.
class LegalScreen extends StatefulWidget {
  const LegalScreen({
    super.key,
    required this.documentId,
    this.loadContent = LegalContent.load,
  });

  final String documentId;
  final Future<LegalContent> Function() loadContent;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late Future<LegalContent> _content = widget.loadContent();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ShopTrack — informations')),
    body: SafeArea(
      child: FutureBuilder<LegalContent>(
        future: _content,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () =>
                    setState(() => _content = widget.loadContent()),
                child: const Text(
                  'Impossible de lire les informations. Réessayer',
                ),
              ),
            );
          }
          final content = snapshot.data;
          if (content == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final document = content.document(widget.documentId);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                document.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('Version ${content.version}'),
              if (content.draft)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(content.draftNotice),
                  ),
                ),
              for (final section in document.sections) ...[
                const SizedBox(height: 24),
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final paragraph in section.paragraphs) ...[
                  const SizedBox(height: 12),
                  SelectableText(paragraph),
                ],
              ],
              const SizedBox(height: 24),
              if (document.id == 'suppression-compte')
                DataRequestActions(
                  contact: content.contact,
                  request: DataRequest.deletion,
                ),
              if (document.id == 'confidentialite') ...[
                DataRequestActions(
                  contact: content.contact,
                  request: DataRequest.access,
                ),
                const SizedBox(height: 16),
                DataRequestActions(
                  contact: content.contact,
                  request: DataRequest.correction,
                ),
              ],
              if (document.id == 'editeur')
                OutlinedButton.icon(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'ShopTrack',
                    applicationLegalese: content.copyright,
                  ),
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('Licences des composants'),
                ),
              const SizedBox(height: 24),
              const LegalLinks(),
              const SizedBox(height: 16),
              Text(
                content.copyright,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// Ouvre seulement un brouillon. Ne prétend jamais envoyer une demande, ni
/// supprimer un compte. Le repli est utilisable sans messagerie installée.
class DataRequestActions extends StatefulWidget {
  const DataRequestActions({
    super.key,
    required this.contact,
    required this.request,
    this.openEmail,
  });

  final String contact;
  final DataRequest request;
  final Future<bool> Function(Uri)? openEmail;

  @override
  State<DataRequestActions> createState() => _DataRequestActionsState();
}

class _DataRequestActionsState extends State<DataRequestActions> {
  bool _opening = false;
  String? _status;

  Future<void> _open() async {
    setState(() {
      _opening = true;
      _status = null;
    });
    var opened = false;
    try {
      final uri = widget.request.emailUri(widget.contact);
      opened =
          await (widget.openEmail?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
    } catch (_) {
      // L'absence de messagerie ou une erreur de plateforme ne perd pas la
      // demande : son texte reste copiable et l'adresse reste visible.
    }
    if (!mounted) return;
    setState(() {
      _opening = false;
      _status = opened
          ? 'Vérifiez, complétez puis envoyez le message dans votre messagerie. '
                'ShopTrack ne confirme pas son envoi.'
          : 'La messagerie n’a pas pu s’ouvrir. Copiez la demande et envoyez-la '
                'à ${widget.contact} depuis votre messagerie.';
    });
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(
        ClipboardData(
          text:
              'À : ${widget.contact}\n'
              'Objet : ShopTrack — ${widget.request.subject}\n\n'
              '${widget.request.body}',
        ),
      );
      if (!mounted) return;
      setState(
        () => _status =
            'Demande copiée, pas encore envoyée. '
            'Complétez-la et envoyez-la à ${widget.contact}.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _status =
            'Copie impossible. Vous pouvez écrire directement '
            'à ${widget.contact}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        widget.request.subject,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      SelectableText(widget.contact),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: _opening ? null : _open,
        icon: const Icon(Icons.mail_outline),
        label: const Text('Préparer un e-mail'),
      ),
      OutlinedButton.icon(
        onPressed: _copy,
        icon: const Icon(Icons.copy_outlined),
        label: const Text('Copier la demande'),
      ),
      if (_status != null) Semantics(liveRegion: true, child: Text(_status!)),
    ],
  );
}

class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    children: [
      TextButton(
        onPressed: () => context.push('/legal'),
        child: const Text('Informations légales'),
      ),
      TextButton(
        onPressed: () => context.push('/privacy'),
        child: const Text('Confidentialité'),
      ),
      TextButton(
        onPressed: () => context.push('/account-deletion'),
        child: const Text('Supprimer mon compte'),
      ),
    ],
  );
}

// Assistance (écran 16), sans réseau ni affichage : questions fréquentes de la maquette
// (`Assistance.dc.html`) et recherche. Testé dans test/features/account/support_rules_test.dart.

/// Une question fréquente et sa réponse (textes de la maquette). `keywords` : mots-clés CACHÉS
/// (jamais affichés), trouvés par la recherche en plus de la question et de la réponse.
/// Décision de Loick (M1) : le champ propose « reçu » en exemple, mais aucun texte de la maquette
/// ne contient ce mot ; les mots-clés le relient à la bonne réponse.
typedef Faq = ({String question, String answer, String keywords});

const faqs = <Faq>[
  (
    question: 'Mon paiement est en attente depuis longtemps',
    answer:
        'Vérifiez votre téléphone : l’opérateur attend votre code PIN. Sans confirmation au bout '
        'de 10 minutes, la demande expire et rien n’est débité. Ne payez pas une deuxième fois '
        'tant que le statut est « Vérification en cours ».',
    keywords: 'bloqué délai expiré PIN',
  ),
  (
    question: 'J’ai payé mais la facture reste « À payer »',
    answer:
        'La confirmation de l’opérateur peut prendre quelques minutes. Si le montant a été débité '
        'et que la facture n’est pas à jour après une heure, signalez un problème de paiement avec '
        'la référence TX de la transaction.',
    keywords: 'reçu recu paiement payé débité',
  ),
  (
    question: 'Comment payer la facture d’un proche ?',
    answer:
        'Demandez au titulaire du foyer de vous inviter avec votre numéro. Vous verrez alors ses '
        'factures et pourrez les payer depuis votre compte Mobile Money.',
    keywords: 'famille délégué invitation',
  ),
  (
    question: 'Pourquoi ma consommation est « estimée » ?',
    answer:
        'Quand un relevé manque, ElecPay estime la consommation à partir de vos jours précédents. '
        'La valeur est corrigée dès que le relevé arrive.',
    keywords: 'estimation manquant',
  ),
  (
    question: 'Où trouver la référence de mon compteur ?',
    answer: 'Elle est imprimée en haut de votre facture E²C, à côté de votre numéro de contrat.',
    keywords: 'branchement police client',
  ),
];

/// Texte ramené à sa forme simple pour la recherche : minuscules, sans accents ni apostrophes
/// typographiques (« Reçu » trouve « recu », « d’un » trouve « d'un »).
String simplify(String text) {
  const from = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿ’';
  const to = "aaaaaceeeeiiiinooooouuuuyy'";
  final out = StringBuffer();
  for (final char in text.toLowerCase().replaceAll('œ', 'oe').split('')) {
    final i = from.indexOf(char);
    out.write(i < 0 ? char : to[i]);
  }
  return out.toString();
}

/// Questions qui contiennent TOUS les mots cherchés (dans la question, la réponse ou les
/// mots-clés cachés). Recherche vide : toutes.
List<Faq> searchFaqs(String query, [List<Faq> all = faqs]) {
  final words = simplify(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return all;
  return [
    for (final faq in all)
      if (words.every((w) => simplify('${faq.question} ${faq.answer} ${faq.keywords}').contains(w)))
        faq,
  ];
}

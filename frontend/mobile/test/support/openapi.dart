import 'dart:convert';
import 'dart:io';

/// Lecture du contrat `backend/openapi.json` pour vérifier les modèles écrits à la main.
///
/// Principe : pour un schéma, on fabrique un JSON d'exemple conforme au contrat (chaque champ avec
/// une valeur du bon type), puis on vérifie que le modèle Dart le lit, le réécrit à l'identique,
/// refuse un champ obligatoire manquant ou un `null` interdit, et accepte un champ facultatif absent.
class OpenApi {
  OpenApi(this._doc);

  factory OpenApi.load() => OpenApi(
    jsonDecode(File('../../backend/openapi.json').readAsStringSync()) as Map<String, dynamic>,
  );

  final Map<String, dynamic> _doc;

  Map<String, dynamic> get _schemas =>
      (_doc['components'] as Map<String, dynamic>)['schemas'] as Map<String, dynamic>;

  bool hasSchema(String name) => _schemas.containsKey(name);

  Map<String, dynamic> schema(String name) {
    final found = _schemas[name];
    if (found == null) throw StateError('Schéma « $name » absent de backend/openapi.json');
    return found as Map<String, dynamic>;
  }

  Map<String, dynamic> _resolve(Map<String, dynamic> node) {
    final ref = node[r'$ref'];
    return ref is String ? schema(ref.split('/').last) : node;
  }

  /// Propriétés d'un schéma objet (nom JSON → sous-schéma).
  Map<String, dynamic> properties(String name) =>
      (schema(name)['properties'] as Map<String, dynamic>?) ?? <String, dynamic>{};

  /// Champs obligatoires selon le contrat.
  Set<String> required(String name) =>
      ((schema(name)['required'] as List<dynamic>?) ?? <dynamic>[]).cast<String>().toSet();

  /// Le champ accepte-t-il `null` (`anyOf: [..., {"type": "null"}]`) ?
  bool isNullable(String name, String field) {
    final node = properties(name)[field] as Map<String, dynamic>;
    final anyOf = node['anyOf'] as List<dynamic>?;
    return anyOf != null && anyOf.any((s) => (s as Map<String, dynamic>)['type'] == 'null');
  }

  /// Le champ a-t-il une valeur par défaut dans le contrat ?
  bool hasDefault(String name, String field) =>
      (properties(name)[field] as Map<String, dynamic>).containsKey('default');

  /// Un JSON d'exemple complet et conforme au schéma `name`.
  Map<String, dynamic> sample(String name) => sampleOf(schema(name)) as Map<String, dynamic>;

  Object? sampleOf(Map<String, dynamic> node) {
    final resolved = _resolve(node);
    if (resolved.containsKey('const')) return resolved['const'];
    final enumValues = resolved['enum'] as List<dynamic>?;
    if (enumValues != null) return enumValues.first;
    final anyOf = resolved['anyOf'] as List<dynamic>?;
    if (anyOf != null) {
      // Première forme non nulle (ex. `string | null` → une chaîne).
      final first = anyOf.cast<Map<String, dynamic>>().firstWhere((s) => s['type'] != 'null');
      return sampleOf(first);
    }
    switch (resolved['type']) {
      case 'object':
        final props = (resolved['properties'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        return {
          for (final entry in props.entries)
            entry.key: sampleOf(entry.value as Map<String, dynamic>),
        };
      case 'array':
        return [sampleOf(resolved['items'] as Map<String, dynamic>)];
      case 'integer':
        return 42;
      case 'number':
        return 4.5;
      case 'boolean':
        return true;
      case 'string':
        return switch (resolved['format']) {
          'date-time' => '2026-11-16T12:30:00Z',
          'date' => '2026-11-16',
          _ => 'texte',
        };
    }
    throw UnsupportedError('Schéma non géré par le test de contrat : $resolved');
  }

  /// Schémas possibles de la réponse 200 de `POST /auth/login` (un `anyOf`).
  Set<String> loginResponseSchemas() {
    final paths = _doc['paths'] as Map<String, dynamic>;
    final post =
        (paths['/api/v1/auth/login'] as Map<String, dynamic>)['post'] as Map<String, dynamic>;
    final ok = (post['responses'] as Map<String, dynamic>)['200'] as Map<String, dynamic>;
    final json =
        (ok['content'] as Map<String, dynamic>)['application/json'] as Map<String, dynamic>;
    final anyOf = (json['schema'] as Map<String, dynamic>)['anyOf'] as List<dynamic>;
    return {
      for (final s in anyOf.cast<Map<String, dynamic>>()) (s[r'$ref'] as String).split('/').last,
    };
  }

  /// Valeurs autorisées d'une énumération du contrat.
  List<String> enumValues(String name) => (schema(name)['enum'] as List<dynamic>).cast<String>();
}

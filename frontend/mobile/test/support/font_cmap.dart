import 'dart:io';
import 'dart:typed_data';

/// Lit la table `cmap` d'une police TrueType / OpenType : quels caractères (points de code
/// Unicode) ont un vrai dessin (glyphe ≠ 0). Formats 4 (plan de base) et 12 (tout Unicode).
class FontCharacters {
  FontCharacters._(this._data);

  factory FontCharacters.load(String path) =>
      FontCharacters._(ByteData.sublistView(File(path).readAsBytesSync()));

  final ByteData _data;

  int _u16(int offset) => _data.getUint16(offset);
  int _i16(int offset) => _data.getInt16(offset);
  int _u32(int offset) => _data.getUint32(offset);

  int get _cmapOffset {
    final tables = _u16(4);
    for (var i = 0; i < tables; i++) {
      final record = 12 + i * 16;
      final tag = String.fromCharCodes([for (var j = 0; j < 4; j++) _data.getUint8(record + j)]);
      if (tag == 'cmap') return _u32(record + 8);
    }
    throw StateError('table cmap absente');
  }

  /// La police dessine-t-elle ce caractère ?
  bool has(int codePoint) {
    final cmap = _cmapOffset;
    final subtables = _u16(cmap + 2);
    for (var i = 0; i < subtables; i++) {
      final record = cmap + 4 + i * 8;
      final platform = _u16(record);
      final encoding = _u16(record + 2);
      final unicode = platform == 0 || (platform == 3 && (encoding == 1 || encoding == 10));
      if (!unicode) continue;
      final table = cmap + _u32(record + 4);
      final glyph = switch (_u16(table)) {
        4 => _format4(table, codePoint),
        12 => _format12(table, codePoint),
        _ => 0,
      };
      if (glyph != 0) return true;
    }
    return false;
  }

  int _format4(int table, int c) {
    if (c > 0xFFFF) return 0;
    final segments = _u16(table + 6) ~/ 2;
    final ends = table + 14;
    final starts = ends + segments * 2 + 2;
    final deltas = starts + segments * 2;
    final rangeOffsets = deltas + segments * 2;
    for (var s = 0; s < segments; s++) {
      if (c > _u16(ends + s * 2)) continue;
      final start = _u16(starts + s * 2);
      if (c < start) return 0;
      final delta = _i16(deltas + s * 2);
      final rangeOffsetAt = rangeOffsets + s * 2;
      final rangeOffset = _u16(rangeOffsetAt);
      if (rangeOffset == 0) return (c + delta) & 0xFFFF;
      final glyph = _u16(rangeOffsetAt + rangeOffset + 2 * (c - start));
      return glyph == 0 ? 0 : (glyph + delta) & 0xFFFF;
    }
    return 0;
  }

  int _format12(int table, int c) {
    final groups = _u32(table + 12);
    for (var g = 0; g < groups; g++) {
      final group = table + 16 + g * 12;
      final start = _u32(group);
      final end = _u32(group + 4);
      if (c >= start && c <= end) return _u32(group + 8) + (c - start);
    }
    return 0;
  }
}

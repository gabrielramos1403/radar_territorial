import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Camada fina em cima do SharedPreferences.
/// Centraliza as chaves pra não ter string solta espalhada no código.
class StorageService {
  static const chaveConsentimento = 'consentimento_lgpd';
  static const chaveDataConsentimento = 'consentimento_data';
  static const chaveTema = 'tema';
  static const chaveAltoContraste = 'alto_contraste';
  static const chaveEscalaFonte = 'escala_fonte';
  static const chaveLimiares = 'limiares';
  static const chaveOcorrencias = 'ocorrencias';
  static const chaveDecisoes = 'decisoes_alertas';
  static const chaveCacheClima = 'cache_clima';
  static const chaveCacheAr = 'cache_qualidade_ar';
  static const chaveCacheData = 'cache_clima_data';
  static const chaveSimularOffline = 'simular_offline';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> iniciar() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool lerBool(String chave, {bool padrao = false}) =>
      _prefs.getBool(chave) ?? padrao;

  Future<void> salvarBool(String chave, bool valor) =>
      _prefs.setBool(chave, valor);

  double lerDouble(String chave, {double padrao = 1.0}) =>
      _prefs.getDouble(chave) ?? padrao;

  Future<void> salvarDouble(String chave, double valor) =>
      _prefs.setDouble(chave, valor);

  String? lerTexto(String chave) => _prefs.getString(chave);

  Future<void> salvarTexto(String chave, String valor) =>
      _prefs.setString(chave, valor);

  /// Lê um JSON salvo. Se estiver corrompido devolve null em vez de quebrar.
  dynamic lerJson(String chave) {
    final texto = _prefs.getString(chave);
    if (texto == null) return null;
    try {
      return jsonDecode(texto);
    } on FormatException {
      return null;
    }
  }

  Future<void> salvarJson(String chave, Object valor) =>
      _prefs.setString(chave, jsonEncode(valor));

  Future<void> remover(String chave) => _prefs.remove(chave);

  /// Usado quando o usuário revoga o consentimento.
  Future<void> apagarTudo() => _prefs.clear();
}

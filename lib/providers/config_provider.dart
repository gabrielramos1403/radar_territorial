import 'package:flutter/material.dart';

import '../models/limiares.dart';
import '../services/storage_service.dart';

/// Estado GLOBAL de preferências: tema, acessibilidade, consentimento
/// e limiares dos alertas. Tudo é persistido no aparelho.
class ConfigProvider extends ChangeNotifier {
  final StorageService _storage;

  ConfigProvider(this._storage) {
    _carregar();
  }

  bool _consentimento = false;
  DateTime? _dataConsentimento;
  ThemeMode _tema = ThemeMode.system;
  bool _altoContraste = false;
  double _escalaFonte = 1.0;
  Limiares _limiares = Limiares.padrao;
  bool _simularOffline = false;
  bool _simularFalha = false;

  bool get consentimento => _consentimento;
  DateTime? get dataConsentimento => _dataConsentimento;
  ThemeMode get tema => _tema;
  bool get altoContraste => _altoContraste;
  double get escalaFonte => _escalaFonte;
  Limiares get limiares => _limiares;
  bool get simularOffline => _simularOffline;

  /// Falha simulada não é salva: serve só pra demonstrar a tela de erro.
  bool get simularFalha => _simularFalha;

  void _carregar() {
    _consentimento = _storage.lerBool(StorageService.chaveConsentimento);
    final data = _storage.lerTexto(StorageService.chaveDataConsentimento);
    _dataConsentimento = data == null ? null : DateTime.tryParse(data);

    final temaSalvo = _storage.lerTexto(StorageService.chaveTema);
    _tema = ThemeMode.values.firstWhere(
      (t) => t.name == temaSalvo,
      orElse: () => ThemeMode.system,
    );
    _altoContraste = _storage.lerBool(StorageService.chaveAltoContraste);
    _escalaFonte = _storage.lerDouble(StorageService.chaveEscalaFonte);
    _simularOffline = _storage.lerBool(StorageService.chaveSimularOffline);

    final json = _storage.lerJson(StorageService.chaveLimiares);
    if (json is Map<String, dynamic>) {
      _limiares = Limiares.fromJson(json);
    }
  }

  Future<void> darConsentimento() async {
    _consentimento = true;
    _dataConsentimento = DateTime.now();
    await _storage.salvarBool(StorageService.chaveConsentimento, true);
    await _storage.salvarTexto(
      StorageService.chaveDataConsentimento,
      _dataConsentimento!.toIso8601String(),
    );
    notifyListeners();
  }

  /// Revogar apaga TODOS os dados locais (ocorrências, decisões, cache).
  Future<void> revogarConsentimento() async {
    await _storage.apagarTudo();
    _consentimento = false;
    _dataConsentimento = null;
    _tema = ThemeMode.system;
    _altoContraste = false;
    _escalaFonte = 1.0;
    _limiares = Limiares.padrao;
    _simularOffline = false;
    _simularFalha = false;
    notifyListeners();
  }

  Future<void> mudarTema(ThemeMode tema) async {
    _tema = tema;
    notifyListeners();
    await _storage.salvarTexto(StorageService.chaveTema, tema.name);
  }

  Future<void> mudarAltoContraste(bool ativo) async {
    _altoContraste = ativo;
    notifyListeners();
    await _storage.salvarBool(StorageService.chaveAltoContraste, ativo);
  }

  Future<void> mudarEscalaFonte(double escala) async {
    _escalaFonte = escala;
    notifyListeners();
    await _storage.salvarDouble(StorageService.chaveEscalaFonte, escala);
  }

  Future<void> salvarLimiares(Limiares novos) async {
    _limiares = novos;
    notifyListeners();
    await _storage.salvarJson(StorageService.chaveLimiares, novos.toJson());
  }

  Future<void> restaurarLimiares() => salvarLimiares(Limiares.padrao);

  Future<void> mudarSimularOffline(bool ativo) async {
    _simularOffline = ativo;
    notifyListeners();
    await _storage.salvarBool(StorageService.chaveSimularOffline, ativo);
  }

  void mudarSimularFalha(bool ativo) {
    _simularFalha = ativo;
    notifyListeners();
  }
}

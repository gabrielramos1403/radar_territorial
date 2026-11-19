import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/utils/validadores.dart';
import '../models/ocorrencia.dart';
import '../services/storage_service.dart';

/// Ocorrências registradas pelos cidadãos (salvas localmente).
class OcorrenciasProvider extends ChangeNotifier {
  final StorageService _storage;
  final _random = Random();

  OcorrenciasProvider(this._storage) {
    _carregar();
  }

  List<Ocorrencia> _ocorrencias = [];

  /// Mais recentes primeiro.
  List<Ocorrencia> get ocorrencias => List.unmodifiable(_ocorrencias);

  int get total => _ocorrencias.length;

  void _carregar() {
    final json = _storage.lerJson(StorageService.chaveOcorrencias);
    if (json is List) {
      _ocorrencias = json
          .whereType<Map<String, dynamic>>()
          .map(Ocorrencia.fromJson)
          .toList()
        ..sort((a, b) => b.data.compareTo(a.data));
    }
  }

  /// Gera um código aleatório tipo "OC-7F3A9K" que não identifica ninguém.
  String _novoCodigo() {
    const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final codigo =
        List.generate(6, (_) => letras[_random.nextInt(letras.length)]).join();
    return 'OC-$codigo';
  }

  Future<Ocorrencia> registrar({
    required CategoriaOcorrencia categoria,
    required String bairroId,
    required String descricao,
    String? pontoReferencia,
  }) async {
    final referencia = pontoReferencia?.trim();
    final ocorrencia = Ocorrencia(
      id: _novoCodigo(),
      categoria: categoria,
      bairroId: bairroId,
      // segunda camada de proteção: mascara dados pessoais que passarem
      descricao: Anonimizador.mascarar(descricao.trim()),
      pontoReferencia: (referencia == null || referencia.isEmpty)
          ? null
          : Anonimizador.mascarar(referencia),
      data: DateTime.now(),
    );

    _ocorrencias.insert(0, ocorrencia);
    notifyListeners();
    await _salvar();
    return ocorrencia;
  }

  Future<void> remover(String id) async {
    _ocorrencias.removeWhere((o) => o.id == id);
    notifyListeners();
    await _salvar();
  }

  /// Chamado quando o consentimento é revogado (o storage já foi limpo).
  void limparMemoria() {
    _ocorrencias = [];
    notifyListeners();
  }

  Future<void> _salvar() => _storage.salvarJson(
        StorageService.chaveOcorrencias,
        _ocorrencias.map((o) => o.toJson()).toList(),
      );
}

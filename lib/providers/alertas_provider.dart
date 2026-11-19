import 'package:flutter/foundation.dart';

import '../models/alerta.dart';
import '../models/decisao_alerta.dart';
import '../services/motor_alertas.dart';
import '../services/storage_service.dart';
import 'config_provider.dart';
import 'ocorrencias_provider.dart';
import 'territorio_provider.dart';

/// Estado GLOBAL dos alertas.
///
/// Escuta os outros providers: sempre que os dados, os limiares ou as
/// ocorrências mudam, os alertas são recalculados.
/// Também guarda as decisões do gestor (persistidas no aparelho).
class AlertasProvider extends ChangeNotifier {
  final ConfigProvider _config;
  final TerritorioProvider _territorio;
  final OcorrenciasProvider _ocorrencias;
  final StorageService _storage;

  AlertasProvider({
    required ConfigProvider config,
    required TerritorioProvider territorio,
    required OcorrenciasProvider ocorrencias,
    required StorageService storage,
  })  : _config = config,
        _territorio = territorio,
        _ocorrencias = ocorrencias,
        _storage = storage {
    _carregarDecisoes();
    _recalcular();
    _config.addListener(_aoMudarDados);
    _territorio.addListener(_aoMudarDados);
    _ocorrencias.addListener(_aoMudarDados);
  }

  List<Alerta> _alertas = [];
  Map<String, DecisaoAlerta> _decisoes = {};

  List<Alerta> get alertas => List.unmodifiable(_alertas);

  List<Alerta> get pendentes =>
      _alertas.where((a) => statusDe(a.id) == StatusDecisao.pendente).toList();

  List<Alerta> get criticos =>
      _alertas.where((a) => a.severidade.index >= Severidade.alta.index).toList();

  Alerta? alertaPorId(String id) {
    for (final a in _alertas) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<Alerta> alertasDoIndicador(String indicadorId) =>
      _alertas.where((a) => a.indicadorId == indicadorId).toList();

  DecisaoAlerta? decisaoDe(String alertaId) => _decisoes[alertaId];

  StatusDecisao statusDe(String alertaId) =>
      _decisoes[alertaId]?.status ?? StatusDecisao.pendente;

  void _aoMudarDados() {
    _recalcular();
    notifyListeners();
  }

  void _recalcular() {
    final motor = MotorAlertas(limiares: _config.limiares);
    _alertas = motor.gerar(
      clima: _territorio.clima,
      territorio: _territorio.territorio,
      ocorrencias: _ocorrencias.ocorrencias,
    );
  }

  void _carregarDecisoes() {
    final json = _storage.lerJson(StorageService.chaveDecisoes);
    if (json is List) {
      _decisoes = {
        for (final item in json.whereType<Map<String, dynamic>>())
          item['alertaId'] as String: DecisaoAlerta.fromJson(item),
      };
    } else {
      _decisoes = {};
    }
  }

  /// Registra a decisão tomada por uma PESSOA sobre o alerta.
  Future<void> registrarDecisao(
    String alertaId,
    StatusDecisao status,
    String observacao,
  ) async {
    _decisoes[alertaId] = DecisaoAlerta(
      alertaId: alertaId,
      status: status,
      observacao: observacao.trim(),
      data: DateTime.now(),
    );
    notifyListeners();
    await _salvarDecisoes();
  }

  Future<void> _salvarDecisoes() => _storage.salvarJson(
        StorageService.chaveDecisoes,
        _decisoes.values.map((d) => d.toJson()).toList(),
      );

  /// Usado depois de revogar o consentimento.
  void limparMemoria() {
    _decisoes = {};
    _recalcular();
    notifyListeners();
  }

  // -------------------------------------------------------------------
  // Indicadores de benefício social
  // -------------------------------------------------------------------

  List<Alerta> get _confirmados => _alertas
      .where((a) => statusDe(a.id) == StatusDecisao.confirmado)
      .toList();

  /// Moradores que vivem em áreas com alertas confirmados pelo gestor,
  /// ou seja, que podem ser beneficiados por uma ação preventiva.
  /// Conta cada bairro uma vez só, pra não somar a mesma pessoa duas vezes.
  int get moradoresBeneficiados {
    final dados = _territorio.territorio;
    if (dados == null) return 0;

    final bairros = <String>{};
    for (final a in _confirmados) {
      if (a.bairroId != null) {
        bairros.add(a.bairroId!);
      } else {
        bairros.addAll(dados.bairros.map((b) => b.id));
      }
    }
    return dados.bairros
        .where((b) => bairros.contains(b.id))
        .fold(0, (soma, b) => soma + b.populacao);
  }

  /// Litros de água por dia que podem ser economizados com os vazamentos
  /// confirmados.
  double get litrosEvitaveis => _confirmados.fold(
        0,
        (soma, a) => soma + (a.litrosDiaEvitaveis ?? 0),
      );

  int get totalAnalisados =>
      _alertas.where((a) => statusDe(a.id) != StatusDecisao.pendente).length;

  @override
  void dispose() {
    _config.removeListener(_aoMudarDados);
    _territorio.removeListener(_aoMudarDados);
    _ocorrencias.removeListener(_aoMudarDados);
    super.dispose();
  }
}

import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/dados_territorio.dart';

class ServicoIndisponivelException implements Exception {
  final String mensagem;
  const ServicoIndisponivelException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// "API" simulada com os dados de recursos e serviços da região.
///
/// Não existe uma API pública com consumo de água por bairro em tempo real,
/// então os dados são sintéticos (gerados pelo script em tools/). A classe
/// simula o comportamento de uma API de verdade: tem atraso de rede e pode
/// falhar, pra gente conseguir testar os estados de carregamento e erro.
class TerritorioService {
  final AssetBundle _bundle;
  final Duration atraso;

  TerritorioService({AssetBundle? bundle, this.atraso = const Duration(milliseconds: 900)})
      : _bundle = bundle ?? rootBundle;

  Future<DadosTerritorio> buscar({bool simularFalha = false}) async {
    await Future.delayed(atraso);

    if (simularFalha) {
      throw const ServicoIndisponivelException(
        'Servidor de dados do território indisponível (falha simulada).',
      );
    }

    final texto = await _bundle.loadString('assets/data/territorio.json');
    final json = jsonDecode(texto) as Map<String, dynamic>;
    return DadosTerritorio.fromJson(json, DateTime.now());
  }
}

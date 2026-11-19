import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/estatistica.dart';

enum CategoriaIndicador { clima, recursos, servicos }

extension CategoriaIndicadorInfo on CategoriaIndicador {
  String get nome {
    switch (this) {
      case CategoriaIndicador.clima:
        return 'Clima';
      case CategoriaIndicador.recursos:
        return 'Recursos';
      case CategoriaIndicador.servicos:
        return 'Serviços';
    }
  }

  Color get cor {
    switch (this) {
      case CategoriaIndicador.clima:
        return AppColors.clima;
      case CategoriaIndicador.recursos:
        return AppColors.recursos;
      case CategoriaIndicador.servicos:
        return AppColors.servicos;
    }
  }

  /// Cor certa para desenhar em cima do fundo do tema atual.
  Color corNoTema(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) return cor;
    switch (this) {
      case CategoriaIndicador.clima:
        return AppColors.climaClaro;
      case CategoriaIndicador.recursos:
        return AppColors.recursosClaro;
      case CategoriaIndicador.servicos:
        return AppColors.servicosClaro;
    }
  }

  IconData get icone {
    switch (this) {
      case CategoriaIndicador.clima:
        return Icons.thermostat_outlined;
      case CategoriaIndicador.recursos:
        return Icons.water_drop_outlined;
      case CategoriaIndicador.servicos:
        return Icons.local_hospital_outlined;
    }
  }
}

enum Tendencia { subindo, estavel, caindo }

class PontoSerie {
  final DateTime data;
  final double valor;

  const PontoSerie(this.data, this.valor);
}

class Indicador {
  final String id;
  final String nome;
  final String descricao;
  final String unidade;
  final CategoriaIndicador categoria;
  final List<PontoSerie> historico;

  /// Valores futuros (só os de clima têm, vindos da previsão da API).
  final List<PontoSerie> previsao;
  final String fonte;

  /// Se true, subir é ruim (ex.: consumo). Se false, cair é ruim
  /// (ex.: nível do reservatório). Serve só para a cor da tendência.
  final bool subirEhRuim;
  final int casasDecimais;
  final String? bairroId;

  const Indicador({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.unidade,
    required this.categoria,
    required this.historico,
    required this.fonte,
    this.previsao = const [],
    this.subirEhRuim = true,
    this.casasDecimais = 1,
    this.bairroId,
  });

  List<double> get valores => historico.map((p) => p.valor).toList();

  double get valorAtual => historico.isEmpty ? 0 : historico.last.valor;

  /// Variação da última semana contra as 4 anteriores, em %.
  double get variacaoSemanal => Estatistica.variacaoPercentual(valores);

  Tendencia get tendencia {
    final v = variacaoSemanal;
    if (v > 3) return Tendencia.subindo;
    if (v < -3) return Tendencia.caindo;
    return Tendencia.estavel;
  }

  bool get tendenciaPreocupante {
    if (tendencia == Tendencia.estavel) return false;
    return subirEhRuim ? tendencia == Tendencia.subindo : tendencia == Tendencia.caindo;
  }

  double get minimo =>
      valores.isEmpty ? 0 : valores.reduce((a, b) => a < b ? a : b);
  double get maximo =>
      valores.isEmpty ? 0 : valores.reduce((a, b) => a > b ? a : b);
  double get media => Estatistica.media(valores);
}

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'indicador.dart';

enum Severidade { baixa, moderada, alta, critica }

extension SeveridadeInfo on Severidade {
  String get nome {
    switch (this) {
      case Severidade.baixa:
        return 'Baixa';
      case Severidade.moderada:
        return 'Moderada';
      case Severidade.alta:
        return 'Alta';
      case Severidade.critica:
        return 'Crítica';
    }
  }

  Color get cor {
    switch (this) {
      case Severidade.baixa:
        return AppColors.severidadeBaixa;
      case Severidade.moderada:
        return AppColors.severidadeModerada;
      case Severidade.alta:
        return AppColors.severidadeAlta;
      case Severidade.critica:
        return AppColors.severidadeCritica;
    }
  }

  IconData get icone {
    switch (this) {
      case Severidade.baixa:
        return Icons.info_outline;
      case Severidade.moderada:
        return Icons.report_outlined;
      case Severidade.alta:
        return Icons.warning_amber_rounded;
      case Severidade.critica:
        return Icons.crisis_alert;
    }
  }
}

enum NivelConfianca { baixa, media, alta }

extension NivelConfiancaInfo on NivelConfianca {
  String get nome {
    switch (this) {
      case NivelConfianca.baixa:
        return 'Baixa';
      case NivelConfianca.media:
        return 'Média';
      case NivelConfianca.alta:
        return 'Alta';
    }
  }
}

class Alerta {
  /// Id estável: o mesmo alerta gerado de novo mantém o id,
  /// assim a decisão do gestor não se perde ao atualizar os dados.
  final String id;
  final String titulo;
  final String resumo;
  final CategoriaIndicador categoria;
  final Severidade severidade;

  /// Confiança de 0 a 1.
  final double confianca;

  /// Regra ou modelo que gerou o alerta (explicação curta).
  final String regra;
  final String justificativa;
  final List<String> evidencias;
  final List<String> limitacoes;

  /// Sugestão para o gestor. Nunca é executada automaticamente.
  final String sugestao;
  final String? indicadorId;
  final String? bairroId;
  final String regiao;
  final int populacaoAfetada;
  final DateTime geradoEm;

  /// Litros de água por dia que podem ser economizados se o problema for
  /// resolvido. Só os alertas de consumo de água preenchem.
  final double? litrosDiaEvitaveis;

  const Alerta({
    required this.id,
    required this.titulo,
    required this.resumo,
    required this.categoria,
    required this.severidade,
    required this.confianca,
    required this.regra,
    required this.justificativa,
    required this.evidencias,
    required this.limitacoes,
    required this.sugestao,
    required this.regiao,
    required this.populacaoAfetada,
    required this.geradoEm,
    this.indicadorId,
    this.bairroId,
    this.litrosDiaEvitaveis,
  });

  NivelConfianca get nivelConfianca {
    if (confianca >= 0.75) return NivelConfianca.alta;
    if (confianca >= 0.55) return NivelConfianca.media;
    return NivelConfianca.baixa;
  }

  int get confiancaPorcentagem => (confianca * 100).round();
}

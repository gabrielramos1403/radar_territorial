import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/utils/formatadores.dart';
import '../models/indicador.dart';
import 'grafico_linha.dart';

/// Card de indicador com valor atual, tendência e um mini gráfico.
class IndicadorCard extends StatelessWidget {
  final Indicador indicador;
  final VoidCallback onTap;

  const IndicadorCard({super.key, required this.indicador, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cor = indicador.categoria.corNoTema(context);
    final valor = Formatadores.numero(indicador.valorAtual, casas: indicador.casasDecimais);

    return Semantics(
      button: true,
      label: '${indicador.nome}: $valor ${indicador.unidade}. '
          '${ChipTendencia.textoTendencia(indicador)}. Toque para ver o detalhe.',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(indicador.categoria.icone, size: 18, color: cor),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        indicador.nome,
                        style: textos.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: valor,
                        style: textos.headlineSmall,
                      ),
                      TextSpan(text: ' ${indicador.unidade}', style: textos.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ChipTendencia(indicador: indicador),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 42,
                  child: MiniGrafico(
                    pontos: indicador.historico.length > 21
                        ? indicador.historico.sublist(indicador.historico.length - 21)
                        : indicador.historico,
                    cor: cor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seta + variação semanal. Vermelho quando a tendência é ruim.
class ChipTendencia extends StatelessWidget {
  final Indicador indicador;

  const ChipTendencia({super.key, required this.indicador});

  static String textoTendencia(Indicador i) {
    switch (i.tendencia) {
      case Tendencia.subindo:
        return 'Subindo ${Formatadores.variacao(i.variacaoSemanal)} na semana';
      case Tendencia.caindo:
        return 'Caindo ${Formatadores.variacao(i.variacaoSemanal)} na semana';
      case Tendencia.estavel:
        return 'Estável na semana';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final IconData icone;
    switch (indicador.tendencia) {
      case Tendencia.subindo:
        icone = Icons.trending_up_rounded;
        break;
      case Tendencia.caindo:
        icone = Icons.trending_down_rounded;
        break;
      case Tendencia.estavel:
        icone = Icons.trending_flat_rounded;
        break;
    }
    final cor = indicador.tendenciaPreocupante ? cores.error : cores.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 18, color: cor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            indicador.tendencia == Tendencia.estavel
                ? 'Estável'
                : '${Formatadores.variacao(indicador.variacaoSemanal)} semana',
            style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 12.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

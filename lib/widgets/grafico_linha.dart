import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/utils/formatadores.dart';
import '../models/indicador.dart';

/// Gráfico de linha com histórico (linha cheia) e previsão (tracejada).
/// Também pode desenhar uma linha horizontal com o limiar do alerta.
class GraficoLinha extends StatelessWidget {
  final List<PontoSerie> historico;
  final List<PontoSerie> previsao;
  final Color cor;
  final String unidade;
  final double? limiar;
  final String? rotuloLimiar;
  final double altura;
  final int casasDecimais;

  /// Texto lido pelo leitor de tela no lugar do gráfico.
  final String descricaoAcessivel;

  const GraficoLinha({
    super.key,
    required this.historico,
    required this.cor,
    required this.unidade,
    required this.descricaoAcessivel,
    this.previsao = const [],
    this.limiar,
    this.rotuloLimiar,
    this.altura = 220,
    this.casasDecimais = 1,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final corTexto = tema.colorScheme.onSurfaceVariant;

    final todos = [...historico, ...previsao];
    if (todos.isEmpty) {
      return SizedBox(height: altura, child: const Center(child: Text('Sem dados')));
    }

    final spotsHistorico = <FlSpot>[
      for (var i = 0; i < historico.length; i++) FlSpot(i.toDouble(), historico[i].valor),
    ];
    // a previsão começa no último ponto do histórico pra linha não ficar cortada
    final spotsPrevisao = <FlSpot>[
      if (historico.isNotEmpty && previsao.isNotEmpty) spotsHistorico.last,
      for (var i = 0; i < previsao.length; i++)
        FlSpot((historico.length + i).toDouble(), previsao[i].valor),
    ];

    var minY = todos.map((p) => p.valor).reduce(min);
    var maxY = todos.map((p) => p.valor).reduce(max);
    if (limiar != null) {
      minY = min(minY, limiar!);
      maxY = max(maxY, limiar!);
    }
    final folga = (maxY - minY).abs() * 0.15 + 1;
    minY = minY - folga;
    maxY = maxY + folga;
    if (minY < 0 && todos.every((p) => p.valor >= 0)) minY = 0;

    final intervaloX = max(1, (todos.length / 5).ceil()).toDouble();

    return Semantics(
      label: descricaoAcessivel,
      excludeSemantics: true,
      child: SizedBox(
        height: altura,
        child: Padding(
          padding: const EdgeInsets.only(right: 12, top: 8),
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              minX: 0,
              maxX: (todos.length - 1).toDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (valor, meta) {
                      if (valor == meta.max || valor == meta.min) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        Formatadores.numero(valor, casas: 0),
                        style: TextStyle(fontSize: 11, color: corTexto),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: intervaloX,
                    getTitlesWidget: (valor, meta) {
                      final i = valor.toInt();
                      if (i < 0 || i >= todos.length || valor != i.toDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          Formatadores.diaMes(todos[i].data),
                          style: TextStyle(fontSize: 11, color: corTexto),
                        ),
                      );
                    },
                  ),
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (limiar != null)
                    HorizontalLine(
                      y: limiar!,
                      color: tema.colorScheme.error,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tema.colorScheme.error,
                        ),
                        labelResolver: (_) => rotuloLimiar ?? 'limiar',
                      ),
                    ),
                ],
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => tema.colorScheme.inverseSurface,
                  getTooltipItems: (spots) => spots.map((s) {
                    final i = s.x.toInt().clamp(0, todos.length - 1);
                    final ehPrevisao = i >= historico.length;
                    return LineTooltipItem(
                      '${Formatadores.diaMes(todos[i].data)}${ehPrevisao ? ' (previsão)' : ''}\n'
                      '${Formatadores.numero(s.y, casas: casasDecimais)} $unidade',
                      TextStyle(
                        color: tema.colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spotsHistorico,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  preventCurveOverShooting: true,
                  color: cor,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: cor.withValues(alpha: 0.12),
                  ),
                ),
                if (spotsPrevisao.length > 1)
                  LineChartBarData(
                    spots: spotsPrevisao,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    preventCurveOverShooting: true,
                    color: cor.withValues(alpha: 0.75),
                    barWidth: 3,
                    dashArray: [6, 5],
                    dotData: FlDotData(
                      // com muitos pontos as bolinhas ficam emboladas
                      show: previsao.length <= 8,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: tema.colorScheme.surface,
                        strokeWidth: 2,
                        strokeColor: cor,
                      ),
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

/// Mini gráfico sem eixos, usado dentro dos cards.
class MiniGrafico extends StatelessWidget {
  final List<PontoSerie> pontos;
  final Color cor;

  const MiniGrafico({super.key, required this.pontos, required this.cor});

  @override
  Widget build(BuildContext context) {
    if (pontos.length < 2) return const SizedBox.shrink();
    final spots = [
      for (var i = 0; i < pontos.length; i++) FlSpot(i.toDouble(), pontos[i].valor),
    ];
    return ExcludeSemantics(
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: cor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: cor.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}

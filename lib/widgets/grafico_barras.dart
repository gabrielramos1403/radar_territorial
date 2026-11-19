import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/utils/formatadores.dart';

class ItemBarra {
  final String rotulo;
  final double valor;
  final bool destaque;

  const ItemBarra(this.rotulo, this.valor, {this.destaque = false});
}

/// Gráfico de barras simples (usado para comparar bairros).
/// Barras em destaque usam a cor de alerta.
class GraficoBarras extends StatelessWidget {
  final List<ItemBarra> itens;
  final Color cor;
  final String unidade;
  final String descricaoAcessivel;
  final double altura;
  final int casasDecimais;

  const GraficoBarras({
    super.key,
    required this.itens,
    required this.cor,
    required this.unidade,
    required this.descricaoAcessivel,
    this.altura = 220,
    this.casasDecimais = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    if (itens.isEmpty) {
      return SizedBox(height: altura, child: const Center(child: Text('Sem dados')));
    }
    final maior = itens.map((i) => i.valor).reduce(max);

    return Semantics(
      label: descricaoAcessivel,
      excludeSemantics: true,
      child: SizedBox(
        height: altura,
        child: BarChart(
          BarChartData(
            maxY: maior * 1.2,
            alignment: BarChartAlignment.spaceAround,
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
                  reservedSize: 40,
                  getTitlesWidget: (valor, meta) {
                    if (valor == meta.max) return const SizedBox.shrink();
                    return Text(
                      Formatadores.numero(valor, casas: 0),
                      style: TextStyle(fontSize: 11, color: tema.colorScheme.onSurfaceVariant),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  getTitlesWidget: (valor, meta) {
                    final i = valor.toInt();
                    if (i < 0 || i >= itens.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        itens[i].rotulo,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: itens[i].destaque ? FontWeight.w800 : FontWeight.w500,
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => tema.colorScheme.inverseSurface,
                getTooltipItem: (grupo, indiceGrupo, barra, indiceBarra) =>
                    BarTooltipItem(
                  '${itens[grupo.x].rotulo}\n'
                  '${Formatadores.numero(barra.toY, casas: casasDecimais)} $unidade',
                  TextStyle(
                    color: tema.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < itens.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: itens[i].valor,
                      width: 22,
                      color: itens[i].destaque ? tema.colorScheme.error : cor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

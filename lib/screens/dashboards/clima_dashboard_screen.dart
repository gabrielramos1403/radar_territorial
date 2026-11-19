import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatadores.dart';
import '../../models/dados_clima.dart';
import '../../models/indicador.dart';
import '../../providers/config_provider.dart';
import '../../providers/territorio_provider.dart';
import '../../widgets/banner_dados.dart';
import '../../widgets/dashboard_base.dart';
import '../../widgets/grafico_linha.dart';
import '../../widgets/resumo_tile.dart';
import '../../widgets/secao_titulo.dart';

/// Dashboard 1: clima local e qualidade do ar (dados reais do Open-Meteo).
class ClimaDashboardScreen extends StatelessWidget {
  const ClimaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardBase(
      categoria: CategoriaIndicador.clima,
      titulo: 'Clima e ar',
      dependeDoClima: true,
      conteudo: (context) {
        final provider = context.watch<TerritorioProvider>();
        final limiares = context.watch<ConfigProvider>().limiares;
        final clima = provider.clima!;
        final cor = CategoriaIndicador.clima.corNoTema(context);
        final corSecundaria = Theme.of(context).colorScheme.onSurfaceVariant;

        final temp = provider.indicadorPorId('temp_max');
        final chuva = provider.indicadorPorId('chuva');
        final pm25 = provider.indicadorPorId('pm25');

        final chuva3dias =
            clima.previsao.take(3).fold<double>(0, (s, d) => s + d.chuva);
        final pm25Hoje = (pm25 == null || pm25.historico.isEmpty) ? null : pm25.valorAtual;

        return [
          const BannerDados(),
          GradeResponsiva(
            filhos: [
              ResumoTile(
                icone: Icons.thermostat,
                valor: clima.temperaturaAtual == null
                    ? '--'
                    : '${Formatadores.numero(clima.temperaturaAtual!)} °C',
                legenda: 'temperatura agora',
                cor: cor,
              ),
              ResumoTile(
                icone: Icons.water_outlined,
                valor: clima.umidadeAtual == null
                    ? '--'
                    : Formatadores.porcentagem(clima.umidadeAtual!),
                legenda: 'umidade do ar',
                cor: cor,
              ),
              ResumoTile(
                icone: Icons.umbrella_outlined,
                valor: '${Formatadores.numero(chuva3dias)} mm',
                legenda: 'chuva prevista nos próximos 3 dias',
                cor: cor,
              ),
              ResumoTile(
                icone: Icons.air,
                valor: pm25Hoje == null ? '--' : '${Formatadores.numero(pm25Hoje)} µg/m³',
                legenda: 'PM2.5 médio hoje (OMS: até 15)',
                cor: cor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (temp != null)
            CardGrafico(
              titulo: 'Temperatura máxima',
              subtitulo: 'Últimos ${temp.historico.length} dias + previsão de ${temp.previsao.length}',
              indicadorId: temp.id,
              grafico: GraficoLinha(
                historico: temp.historico,
                previsao: temp.previsao,
                cor: cor,
                unidade: '°C',
                limiar: limiares.temperaturaMaxima,
                rotuloLimiar: 'alerta ${Formatadores.numero(limiares.temperaturaMaxima, casas: 0)} °C',
                descricaoAcessivel: 'Gráfico da temperatura máxima. Hoje '
                    '${Formatadores.numero(temp.valorAtual)} graus. Máxima prevista '
                    'na semana ${Formatadores.numero(temp.previsao.isEmpty ? temp.valorAtual : temp.previsao.map((p) => p.valor).reduce((a, b) => a > b ? a : b))} graus.',
              ),
              legenda: LegendaGrafico(cor: cor, mostrarLimiar: true),
            ),
          const SizedBox(height: AppSpacing.md),
          if (chuva != null)
            CardGrafico(
              titulo: 'Chuva por dia',
              subtitulo: 'Volume acumulado em milímetros',
              indicadorId: chuva.id,
              grafico: GraficoLinha(
                historico: chuva.historico,
                previsao: chuva.previsao,
                cor: cor,
                unidade: 'mm',
                descricaoAcessivel: 'Gráfico de chuva diária. Previsão de '
                    '${Formatadores.numero(chuva3dias)} milímetros nos próximos 3 dias.',
              ),
              legenda: LegendaGrafico(cor: cor),
            ),
          const SecaoTitulo(titulo: 'Previsão dos próximos dias'),
          _ListaPrevisao(dias: clima.previsao),
          if (pm25 != null) ...[
            const SizedBox(height: AppSpacing.md),
            CardGrafico(
              titulo: 'Qualidade do ar (PM2.5)',
              subtitulo: 'Média diária em µg/m³',
              indicadorId: pm25.id,
              grafico: GraficoLinha(
                historico: pm25.historico,
                previsao: pm25.previsao,
                cor: corSecundaria,
                unidade: 'µg/m³',
                limiar: limiares.pm25Maximo,
                rotuloLimiar: 'alerta',
                descricaoAcessivel: 'Gráfico de partículas finas PM2.5. Hoje '
                    '${Formatadores.numero(pm25.valorAtual)} microgramas por metro cúbico.',
              ),
              legenda: LegendaGrafico(cor: corSecundaria, mostrarLimiar: true),
            ),
          ],
          const SecaoAlertasCategoria(categoria: CategoriaIndicador.clima),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fonte: Open-Meteo (api.open-meteo.com), modelo de previsão para '
            'as coordenadas do Butantã. Atualizado em '
            '${Formatadores.dataHora(clima.atualizadoEm)}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ];
      },
    );
  }
}

class _ListaPrevisao extends StatelessWidget {
  final List<DiaClima> dias;

  const _ListaPrevisao({required this.dias});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final limiar = context.watch<ConfigProvider>().limiares.temperaturaMaxima;

    if (dias.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Sem previsão disponível.'),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dias.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final d = dias[i];
          final quente = d.temperaturaMaxima >= limiar;
          return Semantics(
            label: '${Formatadores.diaSemana(d.data)}: máxima '
                '${Formatadores.numero(d.temperaturaMaxima, casas: 0)}, mínima '
                '${Formatadores.numero(d.temperaturaMinima, casas: 0)} graus, '
                'chuva ${Formatadores.numero(d.chuva)} milímetros'
                '${quente ? ', acima do limiar de calor' : ''}',
            excludeSemantics: true,
            child: Container(
              width: 104,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: cores.surface,
                borderRadius: BorderRadius.circular(AppSpacing.raio),
                border: Border.all(
                  color: quente ? cores.error : cores.outlineVariant,
                  width: quente ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(Formatadores.diaSemana(d.data), style: textos.labelMedium),
                  Icon(
                    d.chuva >= 5
                        ? Icons.thunderstorm_outlined
                        : d.chuva > 0.5
                            ? Icons.grain
                            : Icons.wb_sunny_outlined,
                    color: quente ? cores.error : CategoriaIndicador.clima.corNoTema(context),
                  ),
                  Text(
                    '${Formatadores.numero(d.temperaturaMaxima, casas: 0)}° / '
                    '${Formatadores.numero(d.temperaturaMinima, casas: 0)}°',
                    style: textos.titleSmall,
                  ),
                  Text(
                    '${Formatadores.numero(d.chuva)} mm'
                    '${d.probabilidadeChuva != null ? ' · ${d.probabilidadeChuva}%' : ''}',
                    style: textos.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

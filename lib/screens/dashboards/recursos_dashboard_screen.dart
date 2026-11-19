import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/estatistica.dart';
import '../../core/utils/formatadores.dart';
import '../../models/indicador.dart';
import '../../providers/alertas_provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/territorio_provider.dart';
import '../../widgets/dashboard_base.dart';
import '../../widgets/grafico_barras.dart';
import '../../widgets/grafico_linha.dart';
import '../../widgets/indicador_card.dart';
import '../../widgets/resumo_tile.dart';
import '../../widgets/secao_titulo.dart';

/// Dashboard 2: recursos (água, energia e resíduos).
class RecursosDashboardScreen extends StatelessWidget {
  const RecursosDashboardScreen({super.key});

  /// Projeta os próximos [dias] do reservatório usando regressão linear
  /// dos últimos 30 dias (é a mesma lógica do alerta).
  List<PontoSerie> _projecao(Indicador reservatorio, int dias) {
    final hist = reservatorio.historico;
    final base = hist.sublist(max(0, hist.length - 30)).map((p) => p.valor).toList();
    final reg = Estatistica.regressao(base);
    final ultimaData = hist.last.data;
    return List.generate(
      dias,
      (i) => PontoSerie(
        ultimaData.add(Duration(days: i + 1)),
        max(0, reg.prever((base.length + i).toDouble())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardBase(
      categoria: CategoriaIndicador.recursos,
      titulo: 'Recursos',
      conteudo: (context) {
        final provider = context.watch<TerritorioProvider>();
        final alertas = context.watch<AlertasProvider>();
        final limiares = context.watch<ConfigProvider>().limiares;
        final cor = CategoriaIndicador.recursos.corNoTema(context);

        final principais = provider.indicadoresDaCategoria(CategoriaIndicador.recursos);
        final reservatorio = provider.indicadorPorId('reservatorio');
        final aguaBairros = provider.indicadoresPorBairro('agua_');
        final bairrosComAlerta = alertas.alertas
            .where((a) => a.id.startsWith('agua_'))
            .map((a) => a.bairroId)
            .toSet();

        return [
          if (reservatorio != null)
            CardGrafico(
              titulo: 'Nível do reservatório',
              subtitulo: 'Últimos 60 dias + projeção de 14 dias (regressão linear)',
              indicadorId: reservatorio.id,
              grafico: GraficoLinha(
                historico: reservatorio.historico,
                previsao: _projecao(reservatorio, 14),
                cor: cor,
                unidade: '%',
                limiar: limiares.nivelReservatorioMinimo,
                rotuloLimiar: 'mínimo ${Formatadores.porcentagem(limiares.nivelReservatorioMinimo)}',
                descricaoAcessivel: 'Gráfico do nível do reservatório. Hoje '
                    '${Formatadores.numero(reservatorio.valorAtual)} por cento, em queda. '
                    'Limite mínimo de ${Formatadores.numero(limiares.nivelReservatorioMinimo, casas: 0)} por cento.',
              ),
              legenda: LegendaGrafico(
                cor: cor,
                textoPrevisao: 'Projeção (tendência)',
                mostrarLimiar: true,
              ),
            ),
          const SecaoTitulo(
            titulo: 'Indicadores',
            subtitulo: 'Toque em um card para ver histórico e tendência',
          ),
          GradeResponsiva(
            filhos: [
              for (final i in principais)
                IndicadorCard(
                  indicador: i,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.indicadorDetalhe, arguments: i.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CardGrafico(
            titulo: 'Consumo de água por bairro',
            subtitulo: 'Média dos últimos 7 dias (L/hab/dia). Em vermelho: consumo anormal',
            grafico: GraficoBarras(
              cor: cor,
              unidade: 'L/hab/dia',
              itens: [
                for (final i in aguaBairros)
                  ItemBarra(
                    Formatadores.abreviarRotulo(i.nome.replaceFirst('Consumo de água - ', '')),
                    Estatistica.media(i.valores.sublist(max(0, i.valores.length - 7))),
                    destaque: bairrosComAlerta.contains(i.bairroId),
                  ),
              ],
              descricaoAcessivel: 'Gráfico de barras do consumo de água por bairro. '
                  '${bairrosComAlerta.isEmpty ? 'Nenhum bairro com consumo anormal.' : 'Bairros com consumo anormal destacados.'}',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                for (final i in aguaBairros)
                  ListTile(
                    leading: Icon(
                      bairrosComAlerta.contains(i.bairroId)
                          ? Icons.warning_amber_rounded
                          : Icons.water_drop_outlined,
                      color: bairrosComAlerta.contains(i.bairroId)
                          ? Theme.of(context).colorScheme.error
                          : cor,
                    ),
                    title: Text(i.nome.replaceFirst('Consumo de água - ', '')),
                    subtitle: Text(
                      '${Formatadores.numero(i.valorAtual)} L/hab/dia · '
                      '${ChipTendencia.textoTendencia(i)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.indicadorDetalhe, arguments: i.id),
                  ),
              ],
            ),
          ),
          const SecaoAlertasCategoria(categoria: CategoriaIndicador.recursos),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fonte: ${provider.territorio?.fonte ?? ''}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ];
      },
    );
  }
}

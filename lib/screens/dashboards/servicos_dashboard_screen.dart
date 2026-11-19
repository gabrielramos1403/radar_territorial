import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/estatistica.dart';
import '../../core/utils/formatadores.dart';
import '../../models/indicador.dart';
import '../../models/ocorrencia.dart';
import '../../providers/alertas_provider.dart';
import '../../providers/ocorrencias_provider.dart';
import '../../providers/territorio_provider.dart';
import '../../widgets/dashboard_base.dart';
import '../../widgets/estado_widgets.dart';
import '../../widgets/grafico_barras.dart';
import '../../widgets/grafico_linha.dart';
import '../../widgets/indicador_card.dart';
import '../../widgets/resumo_tile.dart';
import '../../widgets/secao_titulo.dart';

/// Dashboard 3: demanda por serviços públicos.
class ServicosDashboardScreen extends StatelessWidget {
  const ServicosDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardBase(
      categoria: CategoriaIndicador.servicos,
      titulo: 'Serviços',
      conteudo: (context) {
        final provider = context.watch<TerritorioProvider>();
        final alertas = context.watch<AlertasProvider>();
        final ocorrencias = context.watch<OcorrenciasProvider>().ocorrencias;
        final cor = CategoriaIndicador.servicos.corNoTema(context);

        final principais = provider.indicadoresDaCategoria(CategoriaIndicador.servicos);
        final ubs = provider.indicadorPorId('atendimentos_ubs');
        final chamadosBairros = provider.indicadoresPorBairro('chamados_');
        final mediaMovelUbs =
            ubs == null ? <double>[] : Estatistica.mediaMovel(ubs.valores, 7);
        final bairrosComAlerta = alertas.alertas
            .where((a) => a.id.startsWith('chamados_'))
            .map((a) => a.bairroId)
            .toSet();

        return [
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
          if (ubs != null)
            CardGrafico(
              titulo: 'Atendimentos nas UBS',
              subtitulo: 'Por dia, com média móvel de 7 dias',
              indicadorId: ubs.id,
              grafico: GraficoLinha(
                historico: [
                  for (var i = 0; i < ubs.historico.length; i++)
                    PontoSerie(
                      ubs.historico[i].data,
                      mediaMovelUbs[i],
                    ),
                ],
                cor: cor,
                unidade: 'atend.',
                casasDecimais: 0,
                descricaoAcessivel: 'Gráfico de atendimentos nas UBS. Média de '
                    '${Formatadores.inteiro(ubs.valorAtual)} atendimentos por dia, '
                    '${ChipTendencia.textoTendencia(ubs)}.',
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          CardGrafico(
            titulo: 'Chamados de zeladoria por bairro',
            subtitulo: 'Média por dia na última semana. Em vermelho: alta anormal',
            grafico: GraficoBarras(
              cor: cor,
              unidade: 'chamados/dia',
              casasDecimais: 1,
              itens: [
                for (final i in chamadosBairros)
                  ItemBarra(
                    Formatadores.abreviarRotulo(i.nome.replaceFirst('Chamados - ', '')),
                    Estatistica.media(i.valores.sublist(max(0, i.valores.length - 7))),
                    destaque: bairrosComAlerta.contains(i.bairroId),
                  ),
              ],
              descricaoAcessivel: 'Gráfico de barras com chamados de zeladoria por bairro.',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                for (final i in chamadosBairros)
                  ListTile(
                    leading: Icon(
                      bairrosComAlerta.contains(i.bairroId)
                          ? Icons.warning_amber_rounded
                          : Icons.handyman_outlined,
                      color: bairrosComAlerta.contains(i.bairroId)
                          ? Theme.of(context).colorScheme.error
                          : cor,
                    ),
                    title: Text(i.nome.replaceFirst('Chamados - ', '')),
                    subtitle: Text(ChipTendencia.textoTendencia(i)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.indicadorDetalhe, arguments: i.id),
                  ),
              ],
            ),
          ),
          SecaoTitulo(
            titulo: 'Relatos dos cidadãos',
            subtitulo: '${ocorrencias.length} ocorrência(s) registrada(s) neste aparelho',
          ),
          if (ocorrencias.isEmpty)
            Card(
              child: ListaVaziaWidget(
                icone: Icons.campaign_outlined,
                titulo: 'Nenhum relato ainda',
                mensagem: 'Os relatos anônimos dos moradores ajudam a confirmar '
                    'os alertas de serviços.',
                acao: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.novaOcorrencia),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar ocorrência'),
                ),
              ),
            )
          else
            CardGrafico(
              titulo: 'Relatos por categoria',
              grafico: GraficoBarras(
                cor: cor,
                unidade: 'relatos',
                altura: 180,
                itens: [
                  for (final c in CategoriaOcorrencia.values)
                    if (ocorrencias.any((o) => o.categoria == c))
                      ItemBarra(
                        Formatadores.abreviarRotulo(c.nome.split(' ').first),
                        ocorrencias.where((o) => o.categoria == c).length.toDouble(),
                      ),
                ],
                descricaoAcessivel: 'Gráfico com a quantidade de relatos por categoria.',
              ),
            ),
          const SecaoAlertasCategoria(categoria: CategoriaIndicador.servicos),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fonte: ${provider.territorio?.fonte ?? ''}. Relatos: app (local).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ];
      },
    );
  }
}

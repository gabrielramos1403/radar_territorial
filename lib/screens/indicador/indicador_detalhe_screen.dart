import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatadores.dart';
import '../../models/indicador.dart';
import '../../providers/alertas_provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/territorio_provider.dart';
import '../../widgets/alerta_widgets.dart';
import '../../widgets/dashboard_base.dart';
import '../../widgets/estado_widgets.dart';
import '../../widgets/grafico_linha.dart';
import '../../widgets/indicador_card.dart';
import '../../widgets/resumo_tile.dart';
import '../../widgets/secao_titulo.dart';

/// Detalhe de um indicador: histórico completo, estatísticas e alertas
/// ligados a ele. Recebe o id pela rota.
class IndicadorDetalheScreen extends StatefulWidget {
  final String indicadorId;

  const IndicadorDetalheScreen({super.key, required this.indicadorId});

  @override
  State<IndicadorDetalheScreen> createState() => _IndicadorDetalheScreenState();
}

class _IndicadorDetalheScreenState extends State<IndicadorDetalheScreen> {
  // estado local: período escolhido no gráfico
  int _periodo = 30;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TerritorioProvider>();
    final indicador = provider.indicadorPorId(widget.indicadorId);

    if (indicador == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Indicador')),
        body: provider.carregando
            ? const CarregandoWidget()
            : const ListaVaziaWidget(
                icone: Icons.search_off,
                titulo: 'Indicador não encontrado',
                mensagem: 'Os dados deste indicador não estão disponíveis agora.',
              ),
      );
    }

    final alertas = context.watch<AlertasProvider>();
    final limiares = context.watch<ConfigProvider>().limiares;
    final relacionados = alertas.alertasDoIndicador(indicador.id);
    final textos = Theme.of(context).textTheme;
    final casas = indicador.casasDecimais;

    final historico = indicador.historico.length > _periodo
        ? indicador.historico.sublist(indicador.historico.length - _periodo)
        : indicador.historico;
    final temHistoricoLongo = indicador.historico.length > 14;

    return Scaffold(
      appBar: AppBar(title: Text(indicador.nome)),
      body: ConteudoCentralizado(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                Chip(
                  avatar: Icon(indicador.categoria.icone, size: 18, color: indicador.categoria.corNoTema(context)),
                  label: Text(indicador.categoria.nome),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (indicador.bairroId != null) const Chip(label: Text('Por bairro')),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: Formatadores.numero(indicador.valorAtual, casas: casas),
                  style: textos.headlineSmall?.copyWith(fontSize: 34),
                ),
                TextSpan(text: ' ${indicador.unidade}', style: textos.titleMedium),
              ]),
              semanticsLabel: 'Valor atual ${Formatadores.numero(indicador.valorAtual, casas: casas)} '
                  '${indicador.unidade}',
            ),
            ChipTendencia(indicador: indicador),
            const SizedBox(height: AppSpacing.sm),
            Text(indicador.descricao, style: textos.bodyLarge),
            const SizedBox(height: AppSpacing.md),
            CardGrafico(
              titulo: 'Histórico${indicador.previsao.isNotEmpty ? ' e previsão' : ''}',
              grafico: GraficoLinha(
                historico: historico,
                previsao: indicador.previsao,
                cor: indicador.categoria.corNoTema(context),
                unidade: indicador.unidade,
                casasDecimais: casas,
                limiar: limiarDoIndicador(indicador.id, limiares),
                rotuloLimiar: 'limiar',
                altura: 260,
                descricaoAcessivel: 'Gráfico de ${indicador.nome} nos últimos '
                    '${historico.length} dias. Mínimo '
                    '${Formatadores.numero(indicador.minimo, casas: casas)}, máximo '
                    '${Formatadores.numero(indicador.maximo, casas: casas)}.',
              ),
              legenda: temHistoricoLongo
                  ? SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 14, label: Text('14 dias')),
                        ButtonSegment(value: 30, label: Text('30 dias')),
                        ButtonSegment(value: 60, label: Text('60 dias')),
                      ],
                      selected: {_periodo},
                      onSelectionChanged: (s) => setState(() => _periodo = s.first),
                    )
                  : LegendaGrafico(
                      cor: indicador.categoria.corNoTema(context),
                      mostrarLimiar: limiarDoIndicador(indicador.id, limiares) != null,
                    ),
            ),
            const SecaoTitulo(titulo: 'Estatísticas do período completo'),
            GradeResponsiva(
              larguraMinimaItem: 110,
              filhos: [
                ResumoTile(
                  icone: Icons.south,
                  valor: Formatadores.numero(indicador.minimo, casas: casas),
                  legenda: 'mínimo (${indicador.unidade})',
                ),
                ResumoTile(
                  icone: Icons.horizontal_rule,
                  valor: Formatadores.numero(indicador.media, casas: casas),
                  legenda: 'média (${indicador.unidade})',
                ),
                ResumoTile(
                  icone: Icons.north,
                  valor: Formatadores.numero(indicador.maximo, casas: casas),
                  legenda: 'máximo (${indicador.unidade})',
                ),
                ResumoTile(
                  icone: Icons.show_chart,
                  valor: Formatadores.variacao(indicador.variacaoSemanal),
                  legenda: 'última semana vs 4 anteriores',
                ),
              ],
            ),
            SecaoTitulo(
              titulo: 'Alertas ligados a este indicador',
              subtitulo: relacionados.isEmpty ? null : 'Toque para ver a justificativa',
            ),
            if (relacionados.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('Nenhum alerta para este indicador com os limiares atuais.'),
                ),
              )
            else
              for (final a in relacionados)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AlertaCard(
                    alerta: a,
                    status: alertas.statusDe(a.id),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.alertaDetalhe, arguments: a.id),
                  ),
                ),
            const SizedBox(height: AppSpacing.sm),
            Text('Fonte: ${indicador.fonte}', style: textos.bodySmall),
          ],
        ),
      ),
    );
  }
}

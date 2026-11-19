import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../core/theme/app_spacing.dart';
import '../models/alerta.dart';
import '../models/indicador.dart';
import '../models/limiares.dart';
import '../providers/alertas_provider.dart';
import '../providers/territorio_provider.dart';
import 'alerta_widgets.dart';
import 'estado_widgets.dart';
import 'resumo_tile.dart';
import 'secao_titulo.dart';

/// Estrutura comum dos 3 dashboards: AppBar, estados de carregamento/erro,
/// pull-to-refresh e largura máxima. Cada dashboard só monta o conteúdo.
class DashboardBase extends StatelessWidget {
  final CategoriaIndicador categoria;
  final String titulo;

  /// Diz se o dashboard depende do clima (API real) ou do território.
  final bool dependeDoClima;
  final List<Widget> Function(BuildContext context) conteudo;

  const DashboardBase({
    super.key,
    required this.categoria,
    required this.titulo,
    required this.conteudo,
    this.dependeDoClima = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TerritorioProvider>();

    final estado = dependeDoClima ? provider.estadoClima : provider.estadoTerritorio;
    final temDados = dependeDoClima ? provider.clima != null : provider.territorio != null;
    final erro = dependeDoClima ? provider.erroClima : provider.erroTerritorio;

    Widget corpo;
    if (!temDados && estado != EstadoCarregamento.erro) {
      corpo = const CarregandoWidget();
    } else if (!temDados) {
      corpo = ErroWidget(
        mensagem: erro ?? 'Erro ao carregar.',
        onTentarNovamente: provider.carregar,
      );
    } else {
      corpo = RefreshIndicator(
        onRefresh: provider.carregar,
        child: ConteudoCentralizado(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              if (provider.carregando) const LinearProgressIndicator(),
              ...conteudo(context),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(categoria.icone, color: categoria.corNoTema(context)),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: Text(titulo, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            onPressed: provider.carregando ? null : provider.carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: corpo,
    );
  }
}

/// Card com título e um gráfico dentro, com botão para o detalhe.
class CardGrafico extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget grafico;
  final String? indicadorId;
  final Widget? legenda;

  const CardGrafico({
    super.key,
    required this.titulo,
    required this.grafico,
    this.subtitulo,
    this.indicadorId,
    this.legenda,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(header: true, child: Text(titulo, style: textos.titleMedium)),
                      if (subtitulo != null) Text(subtitulo!, style: textos.bodySmall),
                    ],
                  ),
                ),
                if (indicadorId != null)
                  IconButton(
                    tooltip: 'Ver detalhe de $titulo',
                    icon: const Icon(Icons.open_in_full_rounded),
                    onPressed: () => Navigator.of(context)
                        .pushNamed(AppRoutes.indicadorDetalhe, arguments: indicadorId),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            grafico,
            if (legenda != null) ...[
              const SizedBox(height: AppSpacing.sm),
              legenda!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Legenda simples: linha cheia = histórico, tracejada = previsão.
class LegendaGrafico extends StatelessWidget {
  final Color cor;
  final String textoPrevisao;
  final bool mostrarLimiar;

  const LegendaGrafico({
    super.key,
    required this.cor,
    this.textoPrevisao = 'Previsão',
    this.mostrarLimiar = false,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    Widget item(Widget marca, String texto) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [marca, const SizedBox(width: 4), Text(texto, style: const TextStyle(fontSize: 12))],
        );

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        item(Container(width: 18, height: 3, color: cor), 'Histórico'),
        item(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 3, color: cor),
              const SizedBox(width: 3),
              Container(width: 6, height: 3, color: cor),
            ],
          ),
          textoPrevisao,
        ),
        if (mostrarLimiar)
          item(Container(width: 18, height: 2, color: cores.error), 'Limiar do alerta'),
      ],
    );
  }
}

/// Lista dos alertas de uma categoria (parte de baixo de cada dashboard).
class SecaoAlertasCategoria extends StatelessWidget {
  final CategoriaIndicador categoria;

  const SecaoAlertasCategoria({super.key, required this.categoria});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertasProvider>();
    final lista = provider.alertas.where((a) => a.categoria == categoria).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SecaoTitulo(
          titulo: 'Alertas de ${categoria.nome.toLowerCase()}',
          subtitulo: 'Gerados a partir dos dados acima',
        ),
        if (lista.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Nenhum alerta de ${categoria.nome.toLowerCase()} com os '
                'limiares atuais.',
              ),
            ),
          )
        else
          for (final Alerta a in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AlertaCard(
                alerta: a,
                status: provider.statusDe(a.id),
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.alertaDetalhe, arguments: a.id),
              ),
            ),
      ],
    );
  }
}

/// Limiar ligado a cada indicador (pra desenhar a linha no gráfico).
double? limiarDoIndicador(String indicadorId, Limiares limiares) {
  switch (indicadorId) {
    case 'temp_max':
      return limiares.temperaturaMaxima;
    case 'pm25':
      return limiares.pm25Maximo;
    case 'reservatorio':
      return limiares.nivelReservatorioMinimo;
    default:
      return null;
  }
}

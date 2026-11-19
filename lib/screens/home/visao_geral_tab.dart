import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatadores.dart';
import '../../models/indicador.dart';
import '../../providers/alertas_provider.dart';
import '../../providers/ocorrencias_provider.dart';
import '../../providers/territorio_provider.dart';
import '../../widgets/alerta_widgets.dart';
import '../../widgets/aviso_decisao_humana.dart';
import '../../widgets/banner_dados.dart';
import '../../widgets/estado_widgets.dart';
import '../../widgets/resumo_tile.dart';
import '../../widgets/secao_titulo.dart';

class VisaoGeralTab extends StatelessWidget {
  final VoidCallback onVerAlertas;

  const VisaoGeralTab({super.key, required this.onVerAlertas});

  @override
  Widget build(BuildContext context) {
    final territorio = context.watch<TerritorioProvider>();

    Widget corpo;
    // olha só o estado do território: ele não precisa esperar o clima
    if (territorio.territorio == null &&
        territorio.estadoTerritorio != EstadoCarregamento.erro) {
      corpo = const CarregandoWidget(mensagem: 'Buscando dados do território...');
    } else if (territorio.territorio == null) {
      corpo = ErroWidget(
        mensagem: territorio.erroTerritorio ?? 'Erro desconhecido.',
        onTentarNovamente: territorio.carregar,
      );
    } else {
      corpo = RefreshIndicator(
        onRefresh: territorio.carregar,
        child: _Conteudo(onVerAlertas: onVerAlertas),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar Territorial'),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            onPressed: territorio.carregando ? null : territorio.carregar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sobre os dados e limitações',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.sobreDados),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: corpo,
    );
  }
}

class _Conteudo extends StatelessWidget {
  final VoidCallback onVerAlertas;

  const _Conteudo({required this.onVerAlertas});

  @override
  Widget build(BuildContext context) {
    final territorio = context.watch<TerritorioProvider>();
    final alertas = context.watch<AlertasProvider>();
    final ocorrencias = context.watch<OcorrenciasProvider>();
    final dados = territorio.territorio!;
    final textos = Theme.of(context).textTheme;

    final prioritarios = alertas.pendentes.take(3).toList();

    return ConteudoCentralizado(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
        children: [
          if (territorio.carregando) const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.sm),
          const BannerDados(),
          _CardTerritorio(),
          const SizedBox(height: AppSpacing.md),
          const AvisoDecisaoHumana(compacto: true),

          // ---------- impacto social ----------
          const SecaoTitulo(
            titulo: 'Impacto social',
            subtitulo: 'Resultado das decisões tomadas a partir dos alertas',
          ),
          GradeResponsiva(
            filhos: [
              ResumoTile(
                icone: Icons.groups_2_outlined,
                valor: Formatadores.inteiro(alertas.moradoresBeneficiados),
                legenda: 'moradores em áreas com ação preventiva confirmada',
              ),
              ResumoTile(
                icone: Icons.water_drop_outlined,
                valor: '${Formatadores.inteiro(alertas.litrosEvitaveis / 1000)} mil L',
                legenda: 'de água por dia que podem deixar de ser desperdiçados',
                cor: CategoriaIndicador.recursos.corNoTema(context),
              ),
              ResumoTile(
                icone: Icons.fact_check_outlined,
                valor: '${alertas.totalAnalisados}/${alertas.alertas.length}',
                legenda: 'alertas já analisados por uma pessoa',
              ),
              ResumoTile(
                icone: Icons.campaign_outlined,
                valor: '${ocorrencias.total}',
                legenda: 'relatos anônimos de cidadãos',
                cor: CategoriaIndicador.servicos.corNoTema(context),
              ),
            ],
          ),

          // ---------- dashboards ----------
          const SecaoTitulo(titulo: 'Dashboards do território'),
          _AtalhoDashboard(
            categoria: CategoriaIndicador.clima,
            descricao: 'Temperatura, chuva e qualidade do ar (dados reais)',
            rota: AppRoutes.dashboardClima,
            qtdAlertas: alertas.alertas
                .where((a) => a.categoria == CategoriaIndicador.clima)
                .length,
          ),
          const SizedBox(height: AppSpacing.sm),
          _AtalhoDashboard(
            categoria: CategoriaIndicador.recursos,
            descricao: 'Reservatório, água, energia e resíduos',
            rota: AppRoutes.dashboardRecursos,
            qtdAlertas: alertas.alertas
                .where((a) => a.categoria == CategoriaIndicador.recursos)
                .length,
          ),
          const SizedBox(height: AppSpacing.sm),
          _AtalhoDashboard(
            categoria: CategoriaIndicador.servicos,
            descricao: 'UBS, zeladoria e relatos dos cidadãos',
            rota: AppRoutes.dashboardServicos,
            qtdAlertas: alertas.alertas
                .where((a) => a.categoria == CategoriaIndicador.servicos)
                .length,
          ),

          // ---------- alertas ----------
          SecaoTitulo(
            titulo: 'Alertas aguardando análise',
            subtitulo: '${alertas.pendentes.length} de ${alertas.alertas.length} alertas',
            acao: TextButton(
              onPressed: onVerAlertas,
              child: const Text('Ver todos'),
            ),
          ),
          if (prioritarios.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.task_alt, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Nenhum alerta pendente. Tudo analisado!',
                        style: textos.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final a in prioritarios)
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
          Text(
            'Fonte: ${dados.fonte}. Clima: Open-Meteo.',
            style: textos.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CardTerritorio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final territorio = context.watch<TerritorioProvider>();
    final dados = territorio.territorio!;
    final clima = territorio.clima;
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cores.primary,
        borderRadius: BorderRadius.circular(AppSpacing.raio),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: cores.onPrimary),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dados.nome,
                    style: textos.titleLarge?.copyWith(color: cores.onPrimary),
                  ),
                  Text(dados.cidade),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${dados.bairros.length} distritos · '
                    '${Formatadores.inteiro(dados.populacaoTotal)} habitantes',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (clima != null)
                    Text(
                      'Clima atualizado ${Formatadores.tempoAtras(clima.atualizadoEm)}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                ],
              ),
            ),
            if (clima?.temperaturaAtual != null)
              Semantics(
                label: 'Temperatura agora: ${Formatadores.numero(clima!.temperaturaAtual!)} graus',
                excludeSemantics: true,
                child: Column(
                  children: [
                    Icon(Icons.thermostat, color: cores.onPrimary),
                    Text(
                      '${Formatadores.numero(clima.temperaturaAtual!, casas: 0)}°',
                      style: textos.headlineSmall?.copyWith(color: cores.onPrimary),
                    ),
                    const Text('agora', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AtalhoDashboard extends StatelessWidget {
  final CategoriaIndicador categoria;
  final String descricao;
  final String rota;
  final int qtdAlertas;

  const _AtalhoDashboard({
    required this.categoria,
    required this.descricao,
    required this.rota,
    required this.qtdAlertas,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => Navigator.of(context).pushNamed(rota),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: categoria.cor,
          foregroundColor: Colors.white,
          child: Icon(categoria.icone),
        ),
        title: Text('Dashboard de ${categoria.nome}', style: textos.titleMedium),
        subtitle: Text(descricao),
        trailing: qtdAlertas > 0
            ? Badge(
                label: Text('$qtdAlertas'),
                child: const Icon(Icons.chevron_right),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

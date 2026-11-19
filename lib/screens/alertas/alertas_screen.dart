import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/alerta.dart';
import '../../models/decisao_alerta.dart';
import '../../models/indicador.dart';
import '../../providers/alertas_provider.dart';
import '../../providers/territorio_provider.dart';
import '../../widgets/alerta_widgets.dart';
import '../../widgets/aviso_decisao_humana.dart';
import '../../widgets/estado_widgets.dart';
import '../../widgets/resumo_tile.dart';

/// Lista de todos os alertas, com filtros por categoria e situação.
class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  // filtros são estado LOCAL (só essa tela usa)
  CategoriaIndicador? _categoria;
  bool _somentePendentes = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertasProvider>();
    final territorio = context.watch<TerritorioProvider>();

    final filtrados = provider.alertas.where((a) {
      if (_categoria != null && a.categoria != _categoria) return false;
      if (_somentePendentes && provider.statusDe(a.id) != StatusDecisao.pendente) {
        return false;
      }
      return true;
    }).toList();

    Widget lista;
    if (territorio.carregando && provider.alertas.isEmpty) {
      lista = const CarregandoWidget(mensagem: 'Calculando alertas...');
    } else if (territorio.territorio == null && territorio.clima == null) {
      lista = ErroWidget(
        mensagem: 'Sem dados para gerar alertas.',
        onTentarNovamente: territorio.carregar,
      );
    } else if (filtrados.isEmpty) {
      lista = ListaVaziaWidget(
        icone: Icons.notifications_off_outlined,
        titulo: provider.alertas.isEmpty ? 'Nenhum alerta' : 'Nada com esses filtros',
        mensagem: provider.alertas.isEmpty
            ? 'Os dados atuais não passaram de nenhum limiar. Você pode ajustar '
                'os limiares em Ajustes.'
            : 'Tente mudar os filtros acima.',
        acao: provider.alertas.isEmpty
            ? null
            : TextButton(
                onPressed: () => setState(() {
                  _categoria = null;
                  _somentePendentes = false;
                }),
                child: const Text('Limpar filtros'),
              ),
      );
    } else {
      lista = ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
        itemCount: filtrados.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          final Alerta a = filtrados[i];
          return AlertaCard(
            alerta: a,
            status: provider.statusDe(a.id),
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.alertaDetalhe, arguments: a.id),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas preditivos')),
      body: ConteudoCentralizado(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: AvisoDecisaoHumana(),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Só pendentes'),
                    selected: _somentePendentes,
                    onSelected: (v) => setState(() => _somentePendentes = v),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _categoria == null,
                    onSelected: (_) => setState(() => _categoria = null),
                  ),
                  for (final c in CategoriaIndicador.values) ...[
                    const SizedBox(width: AppSpacing.sm),
                    ChoiceChip(
                      label: Text(c.nome),
                      avatar: Icon(c.icone, size: 18),
                      selected: _categoria == c,
                      onSelected: (_) => setState(() => _categoria = c),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(child: lista),
          ],
        ),
      ),
    );
  }
}

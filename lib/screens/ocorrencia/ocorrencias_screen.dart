import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatadores.dart';
import '../../models/ocorrencia.dart';
import '../../providers/ocorrencias_provider.dart';
import '../../providers/territorio_provider.dart';
import '../../widgets/estado_widgets.dart';
import '../../widgets/resumo_tile.dart';

/// Lista das ocorrências registradas (salvas no aparelho).
class OcorrenciasScreen extends StatelessWidget {
  const OcorrenciasScreen({super.key});

  Future<void> _confirmarRemocao(BuildContext context, Ocorrencia o) async {
    final remover = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover ocorrência?'),
        content: Text('A ocorrência ${o.id} será apagada deste aparelho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (remover == true && context.mounted) {
      await context.read<OcorrenciasProvider>().remover(o.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ocorrencias = context.watch<OcorrenciasProvider>().ocorrencias;
    final territorio = context.watch<TerritorioProvider>().territorio;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ocorrências dos cidadãos')),
      body: ocorrencias.isEmpty
          ? ListaVaziaWidget(
              icone: Icons.campaign_outlined,
              titulo: 'Nenhuma ocorrência registrada',
              mensagem: 'Viu um vazamento, bueiro entupido ou lixo acumulado? '
                  'Registre de forma anônima. Vários relatos parecidos no mesmo '
                  'bairro viram alerta para o gestor.',
              acao: FilledButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.novaOcorrencia),
                icon: const Icon(Icons.add),
                label: const Text('Registrar a primeira'),
              ),
            )
          : ConteudoCentralizado(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
                itemCount: ocorrencias.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final o = ocorrencias[i];
                  final bairro = territorio?.bairroPorId(o.bairroId)?.nome ?? o.bairroId;
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
                      leading: CircleAvatar(child: Icon(o.categoria.icone)),
                      title: Text(o.categoria.nome, style: textos.titleSmall),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$bairro · ${Formatadores.dataHora(o.data)}'),
                          const SizedBox(height: 4),
                          Text(o.descricao),
                          if (o.pontoReferencia != null)
                            Text('Referência: ${o.pontoReferencia}', style: textos.bodySmall),
                          const SizedBox(height: 4),
                          Text('Código anônimo: ${o.id}', style: textos.bodySmall),
                        ],
                      ),
                      trailing: IconButton(
                        tooltip: 'Remover ocorrência ${o.id}',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmarRemocao(context, o),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

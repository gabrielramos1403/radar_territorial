import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatadores.dart';
import '../../core/utils/validadores.dart';
import '../../models/alerta.dart';
import '../../models/decisao_alerta.dart';
import '../../providers/alertas_provider.dart';
import '../../providers/territorio_provider.dart';
import '../../widgets/alerta_widgets.dart';
import '../../widgets/aviso_decisao_humana.dart';
import '../../widgets/estado_widgets.dart';
import '../../widgets/resumo_tile.dart';
import '../../widgets/secao_titulo.dart';

/// Detalhe do alerta: justificativa, evidências, confiança, limitações
/// e o registro da decisão HUMANA.
class AlertaDetalheScreen extends StatelessWidget {
  final String alertaId;

  const AlertaDetalheScreen({super.key, required this.alertaId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertasProvider>();
    final alerta = provider.alertaPorId(alertaId);

    if (alerta == null) {
      final carregando = context.watch<TerritorioProvider>().carregando;
      return Scaffold(
        appBar: AppBar(title: const Text('Alerta')),
        body: carregando
            ? const CarregandoWidget(mensagem: 'Calculando alertas...')
            : const ListaVaziaWidget(
                icone: Icons.notifications_off_outlined,
                titulo: 'Este alerta não está mais ativo',
                mensagem: 'Os dados ou os limiares mudaram e a condição que '
                    'gerou o alerta deixou de existir.',
              ),
      );
    }

    final textos = Theme.of(context).textTheme;
    final decisao = provider.decisaoDe(alerta.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: ConteudoCentralizado(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                SeveridadeChip(severidade: alerta.severidade),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${alerta.regiao} · gerado ${Formatadores.dataHora(alerta.geradoEm)}',
                    style: textos.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(header: true, child: Text(alerta.titulo, style: textos.headlineSmall)),
            const SizedBox(height: AppSpacing.xs),
            Text(alerta.resumo, style: textos.bodyLarge),
            const SizedBox(height: AppSpacing.md),
            const AvisoDecisaoHumana(),

            const SecaoTitulo(titulo: 'Nível de confiança'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BarraConfianca(alerta: alerta),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Como foi calculado', style: textos.titleSmall),
                    const SizedBox(height: 2),
                    Text(alerta.regra),
                  ],
                ),
              ),
            ),

            const SecaoTitulo(titulo: 'Por que este alerta foi gerado'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(alerta.justificativa, style: textos.bodyLarge),
              ),
            ),

            const SecaoTitulo(
              titulo: 'Evidências',
              subtitulo: 'Os dados que sustentam o alerta',
            ),
            _ListaComIcone(
              itens: alerta.evidencias,
              icone: Icons.insights_outlined,
            ),

            const SecaoTitulo(
              titulo: 'Limitações',
              subtitulo: 'Quando NÃO confiar neste alerta',
            ),
            _ListaComIcone(
              itens: alerta.limitacoes,
              icone: Icons.report_gmailerrorred_outlined,
              corIcone: Theme.of(context).colorScheme.error,
            ),

            const SecaoTitulo(
              titulo: 'Sugestão para avaliação',
              subtitulo: 'Não é executada automaticamente',
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(alerta.sugestao),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GradeResponsiva(
              filhos: [
                ResumoTile(
                  icone: Icons.groups_2_outlined,
                  valor: Formatadores.inteiro(alerta.populacaoAfetada),
                  legenda: 'moradores na área do alerta',
                ),
                if (alerta.litrosDiaEvitaveis != null)
                  ResumoTile(
                    icone: Icons.water_drop_outlined,
                    valor: '${Formatadores.inteiro(alerta.litrosDiaEvitaveis! / 1000)} mil L',
                    legenda: 'de água por dia que podem ser economizados',
                  ),
              ],
            ),
            if (alerta.indicadorId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.indicadorDetalhe,
                  arguments: alerta.indicadorId,
                ),
                icon: const Icon(Icons.show_chart),
                label: const Text('Ver o indicador relacionado'),
              ),
            ],

            const SecaoTitulo(
              titulo: 'Decisão do gestor',
              subtitulo: 'Registre o que foi decidido depois de analisar',
            ),
            if (decisao != null) _DecisaoAtual(decisao: decisao),
            _FormDecisao(alerta: alerta, decisaoAtual: decisao),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ListaComIcone extends StatelessWidget {
  final List<String> itens;
  final IconData icone;
  final Color? corIcone;

  const _ListaComIcone({required this.itens, required this.icone, this.corIcone});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            for (final item in itens)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icone, size: 20, color: corIcone ?? Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DecisaoAtual extends StatelessWidget {
  final DecisaoAlerta decisao;

  const _DecisaoAtual({required this.decisao});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      color: cores.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.how_to_reg_outlined, color: cores.onPrimaryContainer),
        title: Text(
          decisao.status.nome,
          style: TextStyle(color: cores.onPrimaryContainer, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${decisao.observacao}\nRegistrado em ${Formatadores.dataHora(decisao.data)}',
          style: TextStyle(color: cores.onPrimaryContainer),
        ),
        isThreeLine: true,
      ),
    );
  }
}

/// Formulário da decisão (com validação).
class _FormDecisao extends StatefulWidget {
  final Alerta alerta;
  final DecisaoAlerta? decisaoAtual;

  const _FormDecisao({required this.alerta, this.decisaoAtual});

  @override
  State<_FormDecisao> createState() => _FormDecisaoState();
}

class _FormDecisaoState extends State<_FormDecisao> {
  final _formKey = GlobalKey<FormState>();
  final _observacao = TextEditingController();
  StatusDecisao? _status;
  bool _salvando = false;

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    await context
        .read<AlertasProvider>()
        .registrarDecisao(widget.alerta.id, _status!, _observacao.text);
    if (!mounted) return;

    setState(() {
      _salvando = false;
      _status = null;
    });
    _observacao.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Decisão registrada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.decisaoAtual == null ? 'Qual a sua decisão?' : 'Atualizar decisão',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              FormField<StatusDecisao>(
                validator: (_) => Validadores.selecionado(_status, campo: 'uma decisão'),
                builder: (campo) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final s in [
                          StatusDecisao.emAnalise,
                          StatusDecisao.confirmado,
                          StatusDecisao.descartado,
                        ])
                          ChoiceChip(
                            label: Text(_rotulo(s)),
                            selected: _status == s,
                            onSelected: (_) {
                              setState(() => _status = s);
                              campo.didChange(s);
                            },
                          ),
                      ],
                    ),
                    if (campo.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          campo.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _observacao,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Justificativa da decisão',
                  hintText: 'Ex.: equipe enviada para vistoria no local',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  final erro = Validadores.obrigatorio(v, campo: 'a justificativa');
                  if (erro != null) return erro;
                  if (v!.trim().length < 10) {
                    return 'Explique em pelo menos 10 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: const Icon(Icons.save_outlined),
                label: Text(_salvando ? 'Salvando...' : 'Registrar decisão'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rotulo(StatusDecisao s) {
    switch (s) {
      case StatusDecisao.emAnalise:
        return 'Em análise';
      case StatusDecisao.confirmado:
        return 'Confirmar e agir';
      case StatusDecisao.descartado:
        return 'Descartar';
      case StatusDecisao.pendente:
        return 'Pendente';
    }
  }
}

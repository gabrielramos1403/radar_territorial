import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/validadores.dart';
import '../../models/ocorrencia.dart';
import '../../providers/ocorrencias_provider.dart';
import '../../providers/territorio_provider.dart';
import '../../widgets/estado_widgets.dart';
import '../../widgets/resumo_tile.dart';

/// Formulário de registro de ocorrência pelo cidadão (anônimo).
class NovaOcorrenciaScreen extends StatefulWidget {
  const NovaOcorrenciaScreen({super.key});

  @override
  State<NovaOcorrenciaScreen> createState() => _NovaOcorrenciaScreenState();
}

class _NovaOcorrenciaScreenState extends State<NovaOcorrenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  final _referencia = TextEditingController();

  CategoriaOcorrencia? _categoria;
  String? _bairroId;
  bool _anonimoConfirmado = false;
  bool _enviando = false;

  @override
  void dispose() {
    _descricao.dispose();
    _referencia.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    // mostra os erros de todos os campos de uma vez
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija os campos marcados em vermelho.')),
      );
      return;
    }

    setState(() => _enviando = true);
    final ocorrencia = await context.read<OcorrenciasProvider>().registrar(
          categoria: _categoria!,
          bairroId: _bairroId!,
          descricao: _descricao.text,
          pontoReferencia: _referencia.text,
        );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 40),
        title: const Text('Ocorrência registrada'),
        content: Text(
          'Obrigado! Seu relato foi salvo de forma anônima com o código '
          '${ocorrencia.id}. Ele será considerado na geração dos alertas.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final territorio = context.watch<TerritorioProvider>();
    final bairros = territorio.territorio?.bairros;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ocorrência')),
      body: bairros == null
          ? (territorio.estadoTerritorio != EstadoCarregamento.erro
              ? const CarregandoWidget()
              : ErroWidget(
                  mensagem: 'Não foi possível carregar a lista de bairros.',
                  onTentarNovamente: territorio.carregar,
                ))
          : ConteudoCentralizado(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    const _AvisoAnonimo(),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<CategoriaOcorrencia>(
                      initialValue: _categoria,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de problema *',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        for (final c in CategoriaOcorrencia.values)
                          DropdownMenuItem(value: c, child: Text(c.nome)),
                      ],
                      onChanged: (v) => setState(() => _categoria = v),
                      validator: (v) => Validadores.selecionado(v, campo: 'o tipo de problema'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _bairroId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Bairro / distrito *',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      items: [
                        for (final b in bairros)
                          DropdownMenuItem(value: b.id, child: Text(b.nome)),
                      ],
                      onChanged: (v) => setState(() => _bairroId = v),
                      validator: (v) => Validadores.selecionado(v, campo: 'o bairro'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _descricao,
                      maxLines: 4,
                      maxLength: 280,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'O que está acontecendo? *',
                        hintText: 'Ex.: água vazando na calçada há dois dias',
                        alignLabelWithHint: true,
                      ),
                      validator: Validadores.descricaoOcorrencia,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _referencia,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Ponto de referência (opcional)',
                        hintText: 'Ex.: perto da praça / em frente à escola',
                        helperText: 'Não informe o número da sua casa.',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      validator: Validadores.pontoReferencia,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FormField<bool>(
                      validator: (_) => _anonimoConfirmado
                          ? null
                          : 'Você precisa confirmar para enviar.',
                      builder: (campo) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            value: _anonimoConfirmado,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: const Text(
                              'Confirmo que não incluí dados pessoais meus ou de '
                              'outras pessoas.',
                            ),
                            onChanged: (v) {
                              setState(() => _anonimoConfirmado = v ?? false);
                              campo.didChange(v);
                            },
                          ),
                          if (campo.hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
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
                    FilledButton.icon(
                      onPressed: _enviando ? null : _enviar,
                      icon: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(_enviando ? 'Enviando...' : 'Enviar ocorrência'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AvisoAnonimo extends StatelessWidget {
  const _AvisoAnonimo();

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cores.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.raio),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: cores.onPrimaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Seu relato é anônimo: não guardamos nome, contato nem localização '
              'exata. Telefones e e-mails digitados são bloqueados.',
              style: TextStyle(color: cores.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

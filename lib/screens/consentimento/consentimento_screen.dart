import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/config_provider.dart';
import '../../widgets/resumo_tile.dart';

/// Primeira tela: explica quais dados o app usa e pede consentimento
/// explícito (LGPD). Sem aceitar, o app não abre.
class ConsentimentoScreen extends StatefulWidget {
  const ConsentimentoScreen({super.key});

  @override
  State<ConsentimentoScreen> createState() => _ConsentimentoScreenState();
}

class _ConsentimentoScreenState extends State<ConsentimentoScreen> {
  // estado LOCAL da tela: só importa aqui
  bool _leuTermos = false;
  bool _aceitaAnonimo = false;
  bool _salvando = false;

  Future<void> _aceitar() async {
    setState(() => _salvando = true);
    await context.read<ConfigProvider>().darConsentimento();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cores = Theme.of(context).colorScheme;
    final podeContinuar = _leuTermos && _aceitaAnonimo && !_salvando;

    return Scaffold(
      body: SafeArea(
        child: ConteudoCentralizado(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Semantics(
                image: true,
                label: 'Logo do Radar Territorial',
                child: Image.asset('assets/images/logo.png', height: 84),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                child: Text(
                  'Bem-vindo ao Radar Territorial',
                  style: textos.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Um painel para acompanhar clima, recursos e serviços da '
                'Subprefeitura do Butantã (SP) e antecipar problemas antes '
                'que eles afetem a população.',
                style: textos.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Como cuidamos dos seus dados', style: textos.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              const _ItemPrivacidade(
                icone: Icons.no_accounts_outlined,
                texto: 'Não pedimos nome, CPF, telefone nem e-mail. As ocorrências '
                    'recebem um código aleatório (ex.: OC-7F3A9K).',
              ),
              const _ItemPrivacidade(
                icone: Icons.location_off_outlined,
                texto: 'Não usamos sua localização GPS. Você só informa o bairro.',
              ),
              const _ItemPrivacidade(
                icone: Icons.phone_android_outlined,
                texto: 'Ocorrências, limiares e preferências ficam salvos só neste '
                    'aparelho.',
              ),
              const _ItemPrivacidade(
                icone: Icons.cleaning_services_outlined,
                texto: 'Telefones, e-mails ou CPFs digitados por engano são '
                    'removidos automaticamente antes de salvar.',
              ),
              const _ItemPrivacidade(
                icone: Icons.delete_forever_outlined,
                texto: 'Você pode revogar o consentimento a qualquer momento em '
                    'Ajustes, e todos os dados locais são apagados.',
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cores.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.raio),
                ),
                child: Text(
                  'Os alertas do app são gerados por regras e modelos estatísticos '
                  'e servem para APOIAR a decisão. A decisão final é sempre de '
                  'uma pessoa.',
                  style: TextStyle(
                    color: cores.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                value: _leuTermos,
                onChanged: (v) => setState(() => _leuTermos = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('Li e entendi como meus dados são usados.'),
              ),
              CheckboxListTile(
                value: _aceitaAnonimo,
                onChanged: (v) => setState(() => _aceitaAnonimo = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Concordo que minhas ocorrências sejam usadas de forma anônima '
                  'para gerar alertas.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: podeContinuar ? _aceitar : null,
                child: _salvando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Concordo e quero continuar'),
              ),
              if (!podeContinuar && !_salvando) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Marque as duas opções para continuar.',
                  style: textos.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemPrivacidade extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _ItemPrivacidade({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

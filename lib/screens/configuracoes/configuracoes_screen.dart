import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatadores.dart';
import '../../providers/alertas_provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/ocorrencias_provider.dart';
import '../../providers/territorio_provider.dart';
import '../../widgets/resumo_tile.dart';
import '../../widgets/secao_titulo.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  Future<void> _revogar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revogar consentimento?'),
        content: const Text(
          'Todas as ocorrências, decisões, limiares e dados em cache deste '
          'aparelho serão apagados. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    await context.read<ConfigProvider>().revogarConsentimento();
    if (!context.mounted) return;
    context.read<OcorrenciasProvider>().limparMemoria();
    context.read<AlertasProvider>().limparMemoria();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.consentimento, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ConteudoCentralizado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
          children: [
            const SecaoTitulo(titulo: 'Aparência e acessibilidade'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema', style: textos.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('Sistema'),
                            icon: Icon(Icons.brightness_auto_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Claro'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Escuro'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {config.tema},
                        onSelectionChanged: config.altoContraste
                            ? null
                            : (s) => context.read<ConfigProvider>().mudarTema(s.first),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Alto contraste'),
                      subtitle: const Text('Fundo preto, texto branco e destaques em amarelo'),
                      value: config.altoContraste,
                      onChanged: context.read<ConfigProvider>().mudarAltoContraste,
                    ),
                    const Divider(),
                    Text('Tamanho do texto', style: textos.titleSmall),
                    Slider(
                      value: config.escalaFonte,
                      min: 0.9,
                      max: 1.6,
                      divisions: 7,
                      label: '${(config.escalaFonte * 100).round()}%',
                      semanticFormatterCallback: (v) => 'Texto em ${(v * 100).round()} por cento',
                      onChanged: context.read<ConfigProvider>().mudarEscalaFonte,
                    ),
                    Text(
                      'Prévia: o texto do app fica deste tamanho.',
                      style: textos.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SecaoTitulo(titulo: 'Alertas'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Limiares dos alertas'),
                subtitle: Text(
                  'Calor ${Formatadores.numero(config.limiares.temperaturaMaxima, casas: 0)} °C · '
                  'Reservatório ${Formatadores.porcentagem(config.limiares.nivelReservatorioMinimo)} · '
                  'Água +${Formatadores.numero(config.limiares.aumentoConsumoAgua, casas: 0)}%',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.limiares),
              ),
            ),

            const SecaoTitulo(titulo: 'Privacidade e dados'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('Consentimento LGPD'),
                    subtitle: Text(
                      config.dataConsentimento == null
                          ? 'Concedido'
                          : 'Concedido em ${Formatadores.dataHora(config.dataConsentimento!)}',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Sobre os dados, métricas e limitações'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.sobreDados),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: const Text('Revogar consentimento e apagar meus dados'),
                    onTap: () => _revogar(context),
                  ),
                ],
              ),
            ),

            const SecaoTitulo(
              titulo: 'Modo de teste',
              subtitulo: 'Para demonstrar o funcionamento sem internet e com erro',
            ),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.wifi_off_outlined),
                    title: const Text('Simular sem internet'),
                    subtitle: const Text('O clima vem do cache salvo no aparelho'),
                    value: config.simularOffline,
                    onChanged: (v) async {
                      await context.read<ConfigProvider>().mudarSimularOffline(v);
                      if (context.mounted) context.read<TerritorioProvider>().carregar();
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.error_outline),
                    title: const Text('Simular falha do servidor'),
                    subtitle: const Text('O serviço de dados do território retorna erro'),
                    value: config.simularFalha,
                    onChanged: (v) {
                      context.read<ConfigProvider>().mudarSimularFalha(v);
                      context.read<TerritorioProvider>().carregar();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Radar Territorial v1.0 · Global Solution 2026.2 · FIAP\n'
              'Projeto acadêmico, sem vínculo com a Prefeitura de São Paulo.',
              style: textos.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Widgets padrão para os estados de carregamento, erro e lista vazia.
/// Todas as telas usam os mesmos pra manter a consistência.

class CarregandoWidget extends StatelessWidget {
  final String mensagem;

  const CarregandoWidget({super.key, this.mensagem = 'Carregando dados...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Semantics(
          liveRegion: true,
          label: mensagem,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(mensagem, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class ErroWidget extends StatelessWidget {
  final String mensagem;
  final VoidCallback? onTentarNovamente;

  const ErroWidget({super.key, required this.mensagem, this.onTentarNovamente});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: cores.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Não deu para carregar',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(mensagem, textAlign: TextAlign.center),
            if (onTentarNovamente != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: onTentarNovamente,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ListaVaziaWidget extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String mensagem;
  final Widget? acao;

  const ListaVaziaWidget({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: cores.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(mensagem, textAlign: TextAlign.center),
            if (acao != null) ...[
              const SizedBox(height: AppSpacing.md),
              acao!,
            ],
          ],
        ),
      ),
    );
  }
}

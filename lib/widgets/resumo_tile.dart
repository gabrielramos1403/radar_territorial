import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Quadradinho de KPI (ícone + número + legenda).
class ResumoTile extends StatelessWidget {
  final IconData icone;
  final String valor;
  final String legenda;
  final Color? cor;

  const ResumoTile({
    super.key,
    required this.icone,
    required this.valor,
    required this.legenda,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final corIcone = cor ?? tema.colorScheme.primary;

    return Semantics(
      label: '$legenda: $valor',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: corIcone),
              const SizedBox(height: AppSpacing.sm),
              Text(valor, style: tema.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(legenda, style: tema.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grade responsiva: 2 colunas no celular, mais colunas em telas largas.
class GradeResponsiva extends StatelessWidget {
  final List<Widget> filhos;
  final double larguraMinimaItem;

  const GradeResponsiva({
    super.key,
    required this.filhos,
    this.larguraMinimaItem = 160,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = (constraints.maxWidth / larguraMinimaItem).floor().clamp(1, 4);
        final largura = (constraints.maxWidth - (colunas - 1) * AppSpacing.sm) / colunas;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final f in filhos) SizedBox(width: largura, child: f),
          ],
        );
      },
    );
  }
}

/// Limita a largura do conteúdo em telas grandes e centraliza.
class ConteudoCentralizado extends StatelessWidget {
  final Widget child;

  const ConteudoCentralizado({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.larguraMaxima),
        child: child,
      ),
    );
  }
}

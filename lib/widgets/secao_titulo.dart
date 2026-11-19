import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

class SecaoTitulo extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? acao;

  const SecaoTitulo({super.key, required this.titulo, this.subtitulo, this.acao});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(titulo, style: textos.titleMedium)),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitulo!, style: textos.bodySmall),
                ],
              ],
            ),
          ),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}

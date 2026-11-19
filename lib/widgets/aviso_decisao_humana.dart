import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Aviso fixo: os alertas apoiam, mas não substituem, a decisão humana.
class AvisoDecisaoHumana extends StatelessWidget {
  final bool compacto;

  const AvisoDecisaoHumana({super.key, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Aviso importante',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cores.secondaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.raio),
          border: Border.all(color: cores.secondary, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person_search_rounded, color: cores.onSecondaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                compacto
                    ? 'Os alertas apoiam, mas não substituem, a decisão humana.'
                    : 'Os alertas apoiam, mas não substituem, a decisão humana. '
                        'Nenhuma ação é tomada automaticamente: um gestor '
                        'precisa analisar a evidência e registrar a decisão.',
                style: TextStyle(
                  color: cores.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

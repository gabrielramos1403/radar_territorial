import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_spacing.dart';
import '../core/utils/formatadores.dart';
import '../providers/territorio_provider.dart';

/// Faixa que avisa quando o app está usando dados salvos (offline)
/// ou quando algum serviço falhou.
class BannerDados extends StatelessWidget {
  const BannerDados({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TerritorioProvider>();
    final clima = provider.clima;
    final cores = Theme.of(context).colorScheme;

    String? texto;
    if (provider.usandoCache && clima != null) {
      texto = 'Sem conexão: mostrando clima salvo de '
          '${Formatadores.dataHora(clima.atualizadoEm)} '
          '(${Formatadores.tempoAtras(clima.atualizadoEm)}).';
    } else if (provider.erroClima != null &&
        provider.estadoClima == EstadoCarregamento.erro) {
      texto = 'Clima indisponível: ${provider.erroClima}';
    }

    if (texto == null) return const SizedBox.shrink();

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: cores.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.raioPequeno),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: 20, color: cores.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(color: cores.onSurfaceVariant, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

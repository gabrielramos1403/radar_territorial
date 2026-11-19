import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../models/alerta.dart';
import '../models/decisao_alerta.dart';

/// Card de alerta usado na lista e na visão geral.
class AlertaCard extends StatelessWidget {
  final Alerta alerta;
  final StatusDecisao status;
  final VoidCallback onTap;

  const AlertaCard({
    super.key,
    required this.alerta,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cores = Theme.of(context).colorScheme;
    final corSeveridade = alerta.severidade.cor;

    return Semantics(
      button: true,
      label: 'Alerta de severidade ${alerta.severidade.nome}: ${alerta.titulo}. '
          '${alerta.resumo} Confiança ${alerta.nivelConfianca.nome}, '
          '${alerta.confiancaPorcentagem} por cento. ${status.nome}. '
          'Toque para ver a justificativa.',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // faixa colorida da severidade
                Container(width: 6, color: corSeveridade),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SeveridadeChip(severidade: alerta.severidade),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                alerta.regiao,
                                style: textos.labelMedium?.copyWith(
                                  color: cores.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (status != StatusDecisao.pendente)
                              Icon(
                                status == StatusDecisao.descartado
                                    ? Icons.block
                                    : Icons.verified_user_outlined,
                                size: 18,
                                color: cores.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(alerta.titulo, style: textos.titleMedium),
                        const SizedBox(height: 2),
                        Text(alerta.resumo, style: textos.bodyMedium),
                        const SizedBox(height: AppSpacing.sm),
                        BarraConfianca(alerta: alerta, compacta: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SeveridadeChip extends StatelessWidget {
  final Severidade severidade;

  const SeveridadeChip({super.key, required this.severidade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: severidade.cor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(severidade.icone, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            severidade.nome,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra que mostra o nível de confiança do alerta.
class BarraConfianca extends StatelessWidget {
  final Alerta alerta;
  final bool compacta;

  const BarraConfianca({super.key, required this.alerta, this.compacta = false});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Semantics(
      label: 'Confiança ${alerta.nivelConfianca.nome}: '
          '${alerta.confiancaPorcentagem} por cento',
      excludeSemantics: true,
      child: Row(
        children: [
          Text(
            'Confiança ${alerta.nivelConfianca.nome.toLowerCase()}',
            style: textos.labelMedium,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                // animação curta só pra chamar atenção pro valor
                tween: Tween(begin: 0, end: alerta.confianca),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) => LinearProgressIndicator(
                  value: valor,
                  minHeight: compacta ? 6 : 10,
                  backgroundColor: cores.surfaceContainerHighest,
                  color: cores.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('${alerta.confiancaPorcentagem}%', style: textos.labelLarge),
        ],
      ),
    );
  }
}

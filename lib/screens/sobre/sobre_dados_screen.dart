import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../widgets/resumo_tile.dart';
import '../../widgets/secao_titulo.dart';

/// Transparência: de onde vêm os dados, como os alertas são gerados,
/// métricas, limitações e vieses.
class SobreDadosScreen extends StatelessWidget {
  const SobreDadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre os dados')),
      body: const ConteudoCentralizado(
        child: _Conteudo(),
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
      children: const [
        SecaoTitulo(titulo: 'Fontes de dados'),
        _Bloco(itens: [
          'Clima (temperatura e chuva): Open-Meteo, dados reais de modelos '
              'meteorológicos, consultados pela internet.',
          'Qualidade do ar (PM2.5): Open-Meteo Air Quality, baseado no modelo '
              'europeu CAMS.',
          'Reservatório, água, energia, resíduos, UBS e zeladoria: dados '
              'SINTÉTICOS (simulados) da Subprefeitura do Butantã, gerados por '
              'script com ordem de grandeza realista. Não são dados oficiais.',
          'População dos distritos: Censo IBGE 2010 (aproximado).',
          'Relatos: ocorrências anônimas registradas no próprio app.',
        ]),
        SecaoTitulo(titulo: 'Como os alertas são gerados'),
        _Bloco(itens: [
          'Regras de limiar sobre a previsão (calor, chuva, qualidade do ar).',
          'Regressão linear para projetar quando o reservatório cruza o nível '
              'mínimo.',
          'Comparação da última semana com as 4 anteriores + z-score para '
              'detectar consumo de água e chamados fora do normal.',
          'Agrupamento de relatos de cidadãos por bairro e tipo.',
        ]),
        SecaoTitulo(titulo: 'Métricas usadas'),
        _Bloco(itens: [
          'Variação percentual semanal (média 7 dias vs. 28 dias anteriores).',
          'z-score: quantos desvios-padrão a semana atual está da média histórica.',
          'R² da regressão: o quanto a tendência explica os dados (0 a 1).',
          'Confiança do alerta (0 a 100%): calculada por regra própria em cada '
              'tipo de alerta, explicada na tela de detalhe.',
        ]),
        SecaoTitulo(titulo: 'Quando as previsões NÃO são confiáveis'),
        _Bloco(itens: [
          'Previsão do tempo para mais de 5 dias.',
          'Dados de clima em cache com mais de 6 horas (a confiança é reduzida '
              'automaticamente).',
          'Projeções do reservatório acima de 30 dias (o app não gera alerta).',
          'Eventos raros que não aparecem no histórico (feriados, obras, '
              'grandes eventos).',
          'Pancadas de chuva muito localizadas.',
        ]),
        SecaoTitulo(titulo: 'Possíveis vieses'),
        _Bloco(itens: [
          'Bairros com menos acesso à internet registram menos chamados e '
              'relatos, então podem ter problemas reais escondidos.',
          'O modelo de clima tem resolução de quilômetros e não capta ilhas de '
              'calor em comunidades com pouca vegetação.',
          'Dados sintéticos refletem as escolhas de quem os gerou.',
        ]),
        SecaoTitulo(titulo: 'Decisão humana'),
        _Bloco(itens: [
          'O app nunca executa ações sozinho: ele mostra a evidência e sugere, '
              'mas quem decide é o gestor, que registra a decisão e o motivo.',
          'Alertas podem ser descartados quando o gestor tiver informação que '
              'o app não tem.',
        ]),
      ],
    );
  }
}

class _Bloco extends StatelessWidget {
  final List<String> itens;

  const _Bloco({required this.itens});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in itens)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
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

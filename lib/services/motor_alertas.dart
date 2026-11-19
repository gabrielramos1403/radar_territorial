import 'dart:math';

import '../core/config/api_config.dart';
import '../core/utils/estatistica.dart';
import '../core/utils/formatadores.dart';
import '../models/alerta.dart';
import '../models/dados_clima.dart';
import '../models/dados_territorio.dart';
import '../models/indicador.dart';
import '../models/limiares.dart';
import '../models/ocorrencia.dart';

/// Gera os alertas preditivos a partir dos dados + limiares.
///
/// Importante: os alertas são só APOIO à decisão. Nenhuma ação é tomada
/// automaticamente, o gestor sempre precisa analisar e registrar a decisão.
///
/// Cada regra devolve um alerta com:
///  - justificativa (por que o alerta existe)
///  - evidências (os números que sustentam)
///  - nível de confiança (0 a 1, explicado em [Alerta.regra])
///  - limitações (quando NÃO confiar no alerta)
class MotorAlertas {
  final Limiares limiares;
  final DateTime agora;

  MotorAlertas({required this.limiares, DateTime? agora})
      : agora = agora ?? DateTime.now();

  DateTime get _hoje => DateTime(agora.year, agora.month, agora.day);

  List<Alerta> gerar({
    DadosClima? clima,
    DadosTerritorio? territorio,
    List<Ocorrencia> ocorrencias = const [],
  }) {
    final alertas = <Alerta>[];
    final populacao = territorio?.populacaoTotal ?? 0;

    if (clima != null) {
      _adicionar(alertas, _calor(clima, populacao));
      _adicionar(alertas, _chuva(clima, populacao, ocorrencias, territorio));
      _adicionar(alertas, _qualidadeAr(clima, populacao));
    }

    if (territorio != null) {
      _adicionar(alertas, _reservatorio(territorio, clima));
      alertas.addAll(_consumoAgua(territorio, clima));
      _adicionar(alertas, _demandaUbs(territorio));
      alertas.addAll(_chamados(territorio, ocorrencias));
      alertas.addAll(_relatosCidadaos(territorio, ocorrencias));
    }

    // ordena: mais grave primeiro, depois maior confiança
    alertas.sort((a, b) {
      final porSeveridade = b.severidade.index.compareTo(a.severidade.index);
      if (porSeveridade != 0) return porSeveridade;
      return b.confianca.compareTo(a.confianca);
    });
    return alertas;
  }

  void _adicionar(List<Alerta> lista, Alerta? alerta) {
    if (alerta != null) lista.add(alerta);
  }

  String _chaveData(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  double _limitarConfianca(double c) => c.clamp(0.2, 0.95).toDouble();

  // ---------------------------------------------------------------------
  // Clima
  // ---------------------------------------------------------------------

  /// Penalidade quando os dados de clima estão desatualizados (cache velho).
  double _penalidadeCache(DadosClima clima, List<String> limitacoes) {
    final idade = agora.difference(clima.atualizadoEm);
    if (clima.doCache && idade > ApiConfig.validadeCache) {
      limitacoes.add(
        'Os dados de clima estão em cache e foram atualizados '
        '${Formatadores.tempoAtras(clima.atualizadoEm, agora: agora)}. '
        'A previsão pode ter mudado, por isso a confiança foi reduzida.',
      );
      return 0.15;
    }
    return 0;
  }

  /// Confiança da previsão do tempo cai conforme o dia fica mais distante.
  double _confiancaPorAntecedencia(int dias) {
    if (dias <= 1) return 0.85;
    if (dias <= 3) return 0.72;
    if (dias <= 5) return 0.6;
    return 0.5;
  }

  Alerta? _calor(DadosClima clima, int populacao) {
    final previsao = clima.previsao;
    final quentes = previsao
        .where((d) => d.temperaturaMaxima >= limiares.temperaturaMaxima)
        .toList();
    if (quentes.isEmpty) return null;

    final pico = quentes.reduce(
        (a, b) => a.temperaturaMaxima >= b.temperaturaMaxima ? a : b);
    final antecedencia = pico.data.difference(_hoje).inDays;

    // conta a maior sequência de dias seguidos acima do limiar
    var sequencia = 0;
    var maiorSequencia = 0;
    for (final d in previsao) {
      if (d.temperaturaMaxima >= limiares.temperaturaMaxima) {
        sequencia++;
        maiorSequencia = max(maiorSequencia, sequencia);
      } else {
        sequencia = 0;
      }
    }

    final excesso = pico.temperaturaMaxima - limiares.temperaturaMaxima;
    var severidade = excesso < 2
        ? Severidade.moderada
        : excesso < 4
            ? Severidade.alta
            : Severidade.critica;
    final ondaDeCalor = maiorSequencia >= 3;
    if (ondaDeCalor && severidade != Severidade.critica) {
      severidade = Severidade.values[severidade.index + 1];
    }

    final limitacoes = <String>[
      'Previsão de modelo meteorológico com resolução de alguns quilômetros: '
          'não capta ilhas de calor de ruas ou quarteirões específicos.',
      'Quanto mais distante o dia previsto, menor a precisão.',
      'Não considera umidade nem sensação térmica.',
    ];
    final confianca = _limitarConfianca(
      _confiancaPorAntecedencia(antecedencia) - _penalidadeCache(clima, limitacoes),
    );

    final mediaRecente = Estatistica.media(
        clima.historico.map((d) => d.temperaturaMaxima).toList());

    return Alerta(
      id: 'calor_${_chaveData(pico.data)}',
      titulo: ondaDeCalor ? 'Possível onda de calor' : 'Calor acima do limiar',
      resumo: 'Máxima de ${Formatadores.numero(pico.temperaturaMaxima)} °C '
          'prevista para ${Formatadores.diaSemana(pico.data)}.',
      categoria: CategoriaIndicador.clima,
      severidade: severidade,
      confianca: confianca,
      regra: 'Regra de limiar sobre a previsão do Open-Meteo: dispara quando '
          'algum dia dos próximos 7 tem máxima ≥ ${Formatadores.numero(limiares.temperaturaMaxima, casas: 0)} °C. '
          'A confiança depende de quantos dias faltam (previsão de 1 dia ≈ 85%, de 6-7 dias ≈ 50%).',
      justificativa: 'A previsão indica ${quentes.length} '
          '${quentes.length == 1 ? 'dia' : 'dias'} com temperatura acima do limiar '
          'configurado. Calor intenso aumenta o risco de desidratação e '
          'problemas cardíacos em idosos e crianças, além de elevar o consumo '
          'de água e energia.',
      evidencias: [
        'Pico previsto: ${Formatadores.numero(pico.temperaturaMaxima)} °C em '
            '${Formatadores.diaSemana(pico.data)} (limiar: '
            '${Formatadores.numero(limiares.temperaturaMaxima, casas: 0)} °C).',
        'Maior sequência de dias seguidos acima do limiar: $maiorSequencia.',
        'Média das máximas nos últimos ${clima.historico.length} dias: '
            '${Formatadores.numero(mediaRecente)} °C.',
        'Antecedência do alerta: $antecedencia ${antecedencia == 1 ? 'dia' : 'dias'}.',
      ],
      limitacoes: limitacoes,
      sugestao: 'Avaliar a abertura de pontos de hidratação, reforçar '
          'orientação nas UBS e avisar instituições de longa permanência '
          'de idosos da região.',
      indicadorId: 'temp_max',
      regiao: 'Toda a região',
      populacaoAfetada: populacao,
      geradoEm: agora,
    );
  }

  Alerta? _chuva(
    DadosClima clima,
    int populacao,
    List<Ocorrencia> ocorrencias,
    DadosTerritorio? territorio,
  ) {
    final proximos = clima.previsao.take(3).toList();
    if (proximos.isEmpty) return null;

    final total = proximos.fold<double>(0, (s, d) => s + d.chuva);
    if (total < limiares.chuvaAcumulada3Dias) return null;

    final razao = total / limiares.chuvaAcumulada3Dias;
    final severidade = razao < 1.3
        ? Severidade.moderada
        : razao < 1.8
            ? Severidade.alta
            : Severidade.critica;

    final probs = proximos
        .where((d) => d.probabilidadeChuva != null)
        .map((d) => d.probabilidadeChuva!.toDouble())
        .toList();
    final probMedia = probs.isEmpty ? 60.0 : Estatistica.media(probs);

    final limitacoes = <String>[
      'Previsão de volume de chuva tem incerteza maior que a de temperatura, '
          'principalmente para pancadas de verão (chuva muito localizada).',
      'O app não tem dados de drenagem nem da altura dos córregos.',
    ];
    // chuva é mais difícil de prever, então a confiança tem teto de 80%
    final confianca = _limitarConfianca(
      min(0.8, probMedia / 100 * 0.85) - _penalidadeCache(clima, limitacoes),
    );

    final evidencias = <String>[
      'Chuva prevista para os próximos 3 dias: ${Formatadores.numero(total)} mm '
          '(limiar: ${Formatadores.numero(limiares.chuvaAcumulada3Dias, casas: 0)} mm).',
      'Probabilidade média de chuva: ${Formatadores.porcentagem(probMedia)}.',
      for (final d in proximos)
        '${Formatadores.diaSemana(d.data)}: ${Formatadores.numero(d.chuva)} mm',
    ];

    final relatos = ocorrencias
        .where((o) =>
            o.categoria == CategoriaOcorrencia.alagamento &&
            agora.difference(o.data).inDays <= 30)
        .length;
    if (relatos > 0) {
      evidencias.add('$relatos relato(s) de alagamento feitos por cidadãos '
          'no último mês.');
    }

    return Alerta(
      id: 'chuva_${_chaveData(proximos.first.data)}',
      titulo: 'Risco de alagamento',
      resumo: '${Formatadores.numero(total)} mm de chuva previstos em 3 dias.',
      categoria: CategoriaIndicador.clima,
      severidade: severidade,
      confianca: confianca,
      regra: 'Soma da chuva prevista nos próximos 3 dias comparada ao limiar. '
          'Confiança = probabilidade média de chuva × 0,85 (máximo 80%).',
      justificativa: 'O volume acumulado previsto passa do limiar configurado. '
          'Chuva concentrada em poucos dias sobrecarrega bueiros e córregos, '
          'principalmente em áreas baixas como as margens do Rio Pirajuçara.',
      evidencias: evidencias,
      limitacoes: limitacoes,
      sugestao: 'Avaliar limpeza preventiva de bocas de lobo e deixar a Defesa '
          'Civil de sobreaviso nas áreas com histórico de alagamento.',
      indicadorId: 'chuva',
      regiao: 'Toda a região',
      populacaoAfetada: populacao,
      geradoEm: agora,
    );
  }

  Alerta? _qualidadeAr(DadosClima clima, int populacao) {
    final futuros = clima.pm25.where((p) => p.data.isAfter(_hoje)).toList();
    if (futuros.isEmpty) return null;

    final pior = futuros.reduce((a, b) => a.valor >= b.valor ? a : b);
    if (pior.valor < limiares.pm25Maximo) return null;

    final antecedencia = pior.data.difference(_hoje).inDays;
    final limitacoes = <String>[
      'Modelo de qualidade do ar (CAMS) tem resolução regional de dezenas de '
          'quilômetros: não mostra a diferença entre uma avenida e uma praça.',
      'Não substitui as estações de medição da CETESB.',
    ];
    final confianca = _limitarConfianca(
      _confiancaPorAntecedencia(antecedencia) - 0.1 - _penalidadeCache(clima, limitacoes),
    );

    return Alerta(
      id: 'ar_${_chaveData(pior.data)}',
      titulo: 'Qualidade do ar ruim',
      resumo: 'PM2.5 médio de ${Formatadores.numero(pior.valor)} µg/m³ previsto '
          'para ${Formatadores.diaSemana(pior.data)}.',
      categoria: CategoriaIndicador.clima,
      severidade: pior.valor >= limiares.pm25Maximo * 1.5
          ? Severidade.alta
          : Severidade.moderada,
      confianca: confianca,
      regra: 'Média diária prevista de PM2.5 comparada ao limiar configurado '
          '(referência da OMS: 15 µg/m³).',
      justificativa: 'Partículas finas em concentração alta pioram asma e '
          'doenças respiratórias, principalmente em crianças e idosos.',
      evidencias: [
        'Pior dia previsto: ${Formatadores.diaSemana(pior.data)} com '
            '${Formatadores.numero(pior.valor)} µg/m³.',
        'Limiar configurado: ${Formatadores.numero(limiares.pm25Maximo, casas: 0)} µg/m³.',
      ],
      limitacoes: limitacoes,
      sugestao: 'Avaliar comunicado às escolas e UBS orientando evitar '
          'atividades físicas ao ar livre no período.',
      indicadorId: 'pm25',
      regiao: 'Toda a região',
      populacaoAfetada: populacao,
      geradoEm: agora,
    );
  }

  // ---------------------------------------------------------------------
  // Recursos
  // ---------------------------------------------------------------------

  Alerta? _reservatorio(DadosTerritorio t, DadosClima? clima) {
    final serie = t.nivelReservatorio;
    if (serie.length < 10) return null;

    final ultimos = serie
        .sublist(max(0, serie.length - 30))
        .map((p) => p.valor)
        .toList();
    final reg = Estatistica.regressao(ultimos);
    final atual = ultimos.last;
    final limiar = limiares.nivelReservatorioMinimo;

    Severidade severidade;
    String resumo;
    String titulo;
    double? diasAteLimiar;

    if (atual <= limiar) {
      severidade = Severidade.critica;
      titulo = 'Reservatório abaixo do nível mínimo';
      resumo = 'Nível atual de ${Formatadores.porcentagem(atual, casas: 1)}, '
          'abaixo do mínimo de ${Formatadores.porcentagem(limiar)}.';
    } else {
      if (reg.inclinacao >= 0) return null;
      diasAteLimiar = (limiar - atual) / reg.inclinacao;
      if (diasAteLimiar > 30) return null;

      severidade = diasAteLimiar <= 10
          ? Severidade.alta
          : diasAteLimiar <= 20
              ? Severidade.moderada
              : Severidade.baixa;
      titulo = 'Reservatório pode atingir nível crítico';
      resumo = 'Se a tendência continuar, chega a '
          '${Formatadores.porcentagem(limiar)} em cerca de '
          '${diasAteLimiar.round()} dias.';
    }

    // a confiança vem do R² da reta: se os pontos estão bem alinhados,
    // a projeção é mais confiável
    final confianca = _limitarConfianca(0.45 + 0.4 * reg.r2);

    final evidencias = <String>[
      'Nível atual: ${Formatadores.porcentagem(atual, casas: 1)}.',
      'Variação média: ${Formatadores.numero(reg.inclinacao, casas: 2)} '
          'ponto(s) percentual(is) por dia nos últimos ${ultimos.length} dias.',
      'Ajuste da tendência (R²): ${Formatadores.numero(reg.r2, casas: 2)}.',
      if (diasAteLimiar != null)
        'Projeção: atinge ${Formatadores.porcentagem(limiar)} por volta de '
            '${Formatadores.data(_hoje.add(Duration(days: diasAteLimiar.round())))}.',
    ];

    if (clima != null && clima.historico.isNotEmpty) {
      final chuva14 = clima.historico.fold<double>(0, (s, d) => s + d.chuva);
      evidencias.add('Chuva real acumulada nos últimos '
          '${clima.historico.length} dias: ${Formatadores.numero(chuva14)} mm.');
    }

    return Alerta(
      id: 'reservatorio',
      titulo: titulo,
      resumo: resumo,
      categoria: CategoriaIndicador.recursos,
      severidade: severidade,
      confianca: confianca,
      regra: 'Regressão linear sobre os últimos 30 dias do nível do '
          'reservatório, projetando quando ele cruza o limiar mínimo. '
          'Confiança = 45% + 40% × R² da regressão.',
      justificativa: 'O nível vem caindo de forma constante. Abaixo do mínimo '
          'aumenta a chance de rodízio e redução de pressão na rede, o que '
          'afeta primeiro os bairros mais altos e mais pobres.',
      evidencias: evidencias,
      limitacoes: [
        'Projeção linear simples: não considera chuvas futuras nem manobras '
            'operacionais da companhia de saneamento.',
        'Dados do reservatório são sintéticos neste protótipo.',
        'Para horizontes acima de 30 dias a previsão não é confiável e o '
            'alerta não é gerado.',
      ],
      sugestao: 'Avaliar campanha de economia de água e conversar com a '
          'companhia de saneamento sobre o plano de contingência.',
      indicadorId: 'reservatorio',
      regiao: 'Toda a região',
      populacaoAfetada: t.populacaoTotal,
      geradoEm: agora,
    );
  }

  List<Alerta> _consumoAgua(DadosTerritorio t, DadosClima? clima) {
    final lista = <Alerta>[];

    // se fez muito calor na última semana, aumento de consumo é esperado,
    // então a confiança de que é um problema (vazamento) cai
    var calorRecente = false;
    if (clima != null && clima.historico.length >= 7) {
      final ultimaSemana = clima.historico
          .sublist(clima.historico.length - 7)
          .map((d) => d.temperaturaMaxima)
          .toList();
      calorRecente = Estatistica.media(ultimaSemana) >= limiares.temperaturaMaxima - 2;
    }

    for (final bairro in t.bairros) {
      final serie = t.consumoAguaPorBairro[bairro.id];
      if (serie == null || serie.length < 14) continue;

      final valores = serie.map((p) => p.valor).toList();
      final variacao = Estatistica.variacaoPercentual(valores);
      final z = Estatistica.zScore(valores);
      if (variacao < limiares.aumentoConsumoAgua || z < 2) continue;

      final lim = limiares.aumentoConsumoAgua;
      final severidade = variacao < lim * 1.5
          ? Severidade.moderada
          : variacao < lim * 2.5
              ? Severidade.alta
              : Severidade.critica;

      var confianca = 0.45 + 0.08 * z;
      if (calorRecente) confianca -= 0.15;

      final recente = Estatistica.media(valores.sublist(valores.length - 7));
      final anterior = Estatistica.media(
          valores.sublist(max(0, valores.length - 35), valores.length - 7));
      final litrosExtras = (recente - anterior) * bairro.populacao;

      final limitacoes = <String>[
        'Medição agregada por bairro: não identifica o imóvel com problema '
            '(isso é proposital, para proteger a privacidade).',
        'Eventos atípicos (feriado, evento, obra) também aumentam o consumo.',
        'Dados de consumo são sintéticos neste protótipo.',
      ];
      if (calorRecente) {
        limitacoes.add('A última semana foi quente, o que naturalmente aumenta '
            'o consumo. A confiança foi reduzida por isso.');
      }

      lista.add(Alerta(
        id: 'agua_${bairro.id}',
        titulo: 'Consumo de água anormal',
        resumo: '${bairro.nome}: consumo ${Formatadores.variacao(variacao)} '
            'acima do normal na última semana.',
        categoria: CategoriaIndicador.recursos,
        severidade: severidade,
        confianca: _limitarConfianca(confianca),
        regra: 'Compara a média dos últimos 7 dias com as 4 semanas anteriores. '
            'Dispara se o aumento for ≥ ${Formatadores.numero(lim, casas: 0)}% e o '
            'z-score ≥ 2 (fora da variação normal). Confiança = 45% + 8% × z-score.',
        justificativa: 'Um aumento brusco e sustentado no consumo do bairro, '
            'sem explicação pelo clima, costuma indicar vazamento na rede ou '
            'desperdício. Antecipar isso evita perda de água num momento em '
            'que o reservatório está baixo.',
        evidencias: [
          'Média dos últimos 7 dias: ${Formatadores.numero(recente)} L/hab/dia.',
          'Média das 4 semanas anteriores: ${Formatadores.numero(anterior)} L/hab/dia.',
          'Variação: ${Formatadores.variacao(variacao)} (z-score ${Formatadores.numero(z, casas: 1)}).',
          'Estimativa de água extra: ${Formatadores.inteiro(litrosExtras)} litros por dia.',
        ],
        limitacoes: limitacoes,
        sugestao: 'Pedir à companhia de saneamento uma verificação de '
            'vazamentos na rede do bairro ${bairro.nome}.',
        indicadorId: 'agua_${bairro.id}',
        bairroId: bairro.id,
        regiao: bairro.nome,
        populacaoAfetada: bairro.populacao,
        geradoEm: agora,
        litrosDiaEvitaveis: litrosExtras,
      ));
    }
    return lista;
  }

  // ---------------------------------------------------------------------
  // Serviços
  // ---------------------------------------------------------------------

  Alerta? _demandaUbs(DadosTerritorio t) {
    final valores = t.atendimentosUbs.map((p) => p.valor).toList();
    if (valores.length < 21) return null;

    final variacao = Estatistica.variacaoPercentual(valores);
    if (variacao < limiares.aumentoDemandaServicos) return null;

    final ultimas3Semanas = valores.sublist(valores.length - 21);
    final reg = Estatistica.regressao(ultimas3Semanas);
    final projecao7dias = reg.prever(ultimas3Semanas.length + 6);
    final atualMedia = Estatistica.media(valores.sublist(valores.length - 7));

    final lim = limiares.aumentoDemandaServicos;
    final severidade = variacao < lim * 1.5
        ? Severidade.moderada
        : variacao < lim * 2.5
            ? Severidade.alta
            : Severidade.critica;

    return Alerta(
      id: 'ubs_demanda',
      titulo: 'Aumento de procura nas UBS',
      resumo: 'Atendimentos ${Formatadores.variacao(variacao)} acima do normal '
          'e com tendência de alta.',
      categoria: CategoriaIndicador.servicos,
      severidade: severidade,
      confianca: _limitarConfianca(0.4 + 0.45 * reg.r2),
      regra: 'Compara a média da última semana com as 4 anteriores e usa '
          'regressão linear das últimas 3 semanas para projetar a próxima. '
          'Confiança = 40% + 45% × R².',
      justificativa: 'A procura pelas UBS subiu de forma contínua nas últimas '
          'semanas. Se continuar, pode faltar equipe e aumentar o tempo de '
          'espera, o que prejudica principalmente quem depende só do SUS.',
      evidencias: [
        'Média da última semana: ${Formatadores.inteiro(atualMedia)} atendimentos/dia.',
        'Variação contra as 4 semanas anteriores: ${Formatadores.variacao(variacao)}.',
        'Projeção para daqui a 7 dias: ~${Formatadores.inteiro(projecao7dias)} atendimentos/dia.',
        'Ajuste da tendência (R²): ${Formatadores.numero(reg.r2, casas: 2)}.',
      ],
      limitacoes: [
        'O app só recebe o total de atendimentos, sem saber a doença '
            '(para não expor dados de saúde). Não dá pra afirmar que é dengue, '
            'por exemplo.',
        'Projeção linear: não prevê o pico nem o fim de um surto.',
        'Dados de atendimento são sintéticos neste protótipo.',
      ],
      sugestao: 'Avaliar reforço temporário de equipe nas UBS e checar com a '
          'vigilância epidemiológica se há surto em andamento.',
      indicadorId: 'atendimentos_ubs',
      regiao: 'Toda a região',
      populacaoAfetada: t.populacaoTotal,
      geradoEm: agora,
    );
  }

  List<Alerta> _chamados(DadosTerritorio t, List<Ocorrencia> ocorrencias) {
    final lista = <Alerta>[];

    for (final bairro in t.bairros) {
      final serie = t.chamadosPorBairro[bairro.id];
      if (serie == null || serie.length < 14) continue;

      final valores = serie.map((p) => p.valor).toList();
      final variacao = Estatistica.variacaoPercentual(valores);
      final z = Estatistica.zScore(valores);

      // chamados variam bastante de um dia pro outro, por isso exijo
      // aumento de 2x o limiar E z-score alto
      if (variacao < limiares.aumentoDemandaServicos * 2 || z < 2) continue;

      final relatosBairro = ocorrencias
          .where((o) =>
              o.bairroId == bairro.id && agora.difference(o.data).inDays <= 7)
          .length;

      var confianca = 0.4 + 0.07 * z;
      if (relatosBairro > 0) confianca += 0.05 * min(relatosBairro, 3);

      final recente = Estatistica.media(valores.sublist(valores.length - 7));

      lista.add(Alerta(
        id: 'chamados_${bairro.id}',
        titulo: 'Alta nos chamados de zeladoria',
        resumo: '${bairro.nome}: ${Formatadores.variacao(variacao)} de chamados '
            'na última semana.',
        categoria: CategoriaIndicador.servicos,
        severidade: variacao >= limiares.aumentoDemandaServicos * 3
            ? Severidade.alta
            : Severidade.moderada,
        confianca: _limitarConfianca(confianca),
        regra: 'Média de chamados dos últimos 7 dias contra as 4 semanas '
            'anteriores. Dispara com aumento ≥ ${Formatadores.numero(limiares.aumentoDemandaServicos * 2, casas: 0)}% '
            'e z-score ≥ 2. Relatos de cidadãos no app aumentam a confiança.',
        justificativa: 'O número de pedidos de zeladoria no bairro subiu bem '
            'acima do normal. Isso costuma aparecer antes de problemas maiores '
            '(alagamento por bueiro entupido, acúmulo de lixo).',
        evidencias: [
          'Média recente: ${Formatadores.numero(recente)} chamados/dia.',
          'Variação: ${Formatadores.variacao(variacao)} (z-score ${Formatadores.numero(z, casas: 1)}).',
          if (relatosBairro > 0)
            '$relatosBairro relato(s) de cidadãos no app para este bairro nos últimos 7 dias.',
        ],
        limitacoes: [
          'Um mesmo problema pode gerar vários chamados (duplicados).',
          'Bairros com menos acesso à internet ou ao 156 tendem a registrar '
              'menos chamados, o que pode esconder problemas reais (viés).',
          'Dados de chamados são sintéticos neste protótipo.',
        ],
        sugestao: 'Avaliar mutirão de zeladoria no bairro ${bairro.nome} e '
            'verificar os tipos de chamado mais frequentes.',
        indicadorId: 'chamados_${bairro.id}',
        bairroId: bairro.id,
        regiao: bairro.nome,
        populacaoAfetada: bairro.populacao,
        geradoEm: agora,
      ));
    }
    return lista;
  }

  /// Vários relatos parecidos no mesmo bairro em pouco tempo.
  List<Alerta> _relatosCidadaos(DadosTerritorio t, List<Ocorrencia> ocorrencias) {
    final recentes =
        ocorrencias.where((o) => agora.difference(o.data).inDays <= 7);

    final grupos = <String, List<Ocorrencia>>{};
    for (final o in recentes) {
      grupos.putIfAbsent('${o.bairroId}|${o.categoria.name}', () => []).add(o);
    }

    final lista = <Alerta>[];
    grupos.forEach((chave, itens) {
      if (itens.length < 3) return;
      final bairro = t.bairroPorId(itens.first.bairroId);
      final categoria = itens.first.categoria;
      final nomeBairro = bairro?.nome ?? itens.first.bairroId;

      lista.add(Alerta(
        id: 'relatos_${chave.replaceAll('|', '_')}',
        titulo: 'Vários relatos de cidadãos',
        resumo: '${itens.length} relatos de "${categoria.nome}" em $nomeBairro '
            'nos últimos 7 dias.',
        categoria: CategoriaIndicador.servicos,
        severidade: itens.length >= 5 ? Severidade.alta : Severidade.moderada,
        confianca: _limitarConfianca(0.45 + 0.05 * itens.length),
        regra: 'Agrupa as ocorrências registradas no app por bairro e '
            'categoria. Dispara com 3 ou mais relatos em 7 dias.',
        justificativa: 'Relatos repetidos sobre o mesmo tipo de problema no '
            'mesmo bairro indicam que ele provavelmente existe e afeta várias '
            'pessoas.',
        evidencias: [
          for (final o in itens.take(5))
            '${Formatadores.dataHora(o.data)}: "${o.descricao}"',
        ],
        limitacoes: const [
          'Relatos não são verificados e podem ser da mesma pessoa.',
          'Os relatos ficam salvos só neste aparelho no protótipo.',
        ],
        sugestao: 'Enviar equipe para vistoria antes de tomar qualquer medida.',
        bairroId: itens.first.bairroId,
        regiao: nomeBairro,
        populacaoAfetada: bairro?.populacao ?? 0,
        geradoEm: agora,
      ));
    });
    return lista;
  }
}

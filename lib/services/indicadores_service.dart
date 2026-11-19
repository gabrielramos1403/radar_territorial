import '../models/dados_clima.dart';
import '../models/dados_territorio.dart';
import '../models/indicador.dart';

/// Transforma os dados brutos (clima + território) na lista de indicadores
/// que aparece nos dashboards.
class IndicadoresService {
  IndicadoresService._();

  static const fonteOpenMeteo = 'Open-Meteo (dados reais, modelo de previsão)';
  static const fonteSintetica = 'Dados sintéticos (simulação do território)';

  static List<Indicador> montar({DadosClima? clima, DadosTerritorio? territorio}) {
    final lista = <Indicador>[];
    if (clima != null) lista.addAll(_clima(clima));
    if (territorio != null) {
      lista.addAll(_recursos(territorio));
      lista.addAll(_servicos(territorio));
    }
    return lista;
  }

  static List<Indicador> _clima(DadosClima clima) {
    final lista = <Indicador>[
      Indicador(
        id: 'temp_max',
        nome: 'Temperatura máxima',
        descricao: 'Temperatura máxima diária na região. Calor extremo aumenta '
            'risco à saúde de idosos e crianças e o consumo de água e energia.',
        unidade: '°C',
        categoria: CategoriaIndicador.clima,
        historico: clima.historico
            .map((d) => PontoSerie(d.data, d.temperaturaMaxima))
            .toList(),
        previsao: clima.previsao
            .map((d) => PontoSerie(d.data, d.temperaturaMaxima))
            .toList(),
        fonte: fonteOpenMeteo,
      ),
      Indicador(
        id: 'chuva',
        nome: 'Chuva diária',
        descricao: 'Precipitação acumulada por dia. Volumes altos em poucos dias '
            'aumentam o risco de alagamentos nas áreas baixas.',
        unidade: 'mm',
        categoria: CategoriaIndicador.clima,
        historico:
            clima.historico.map((d) => PontoSerie(d.data, d.chuva)).toList(),
        previsao: clima.previsao.map((d) => PontoSerie(d.data, d.chuva)).toList(),
        fonte: fonteOpenMeteo,
      ),
    ];

    if (clima.pm25.isNotEmpty) {
      final hoje = DateTime.now();
      final diaHoje = DateTime(hoje.year, hoje.month, hoje.day);
      lista.add(Indicador(
        id: 'pm25',
        nome: 'Qualidade do ar (PM2.5)',
        descricao: 'Material particulado fino, média diária. A OMS recomenda '
            'no máximo 15 µg/m³ em 24 horas.',
        unidade: 'µg/m³',
        categoria: CategoriaIndicador.clima,
        historico: clima.pm25.where((p) => !p.data.isAfter(diaHoje)).toList(),
        previsao: clima.pm25.where((p) => p.data.isAfter(diaHoje)).toList(),
        fonte: 'Open-Meteo Air Quality (CAMS)',
      ));
    }
    return lista;
  }

  static List<Indicador> _recursos(DadosTerritorio t) {
    final lista = <Indicador>[
      Indicador(
        id: 'reservatorio',
        nome: 'Nível do reservatório',
        descricao: 'Volume útil do reservatório que abastece a região. '
            'Abaixo de 35% a Sabesp costuma adotar medidas de contingência.',
        unidade: '%',
        categoria: CategoriaIndicador.recursos,
        historico: t.nivelReservatorio,
        fonte: fonteSintetica,
        subirEhRuim: false,
      ),
      Indicador(
        id: 'consumo_agua',
        nome: 'Consumo de água (média)',
        descricao: 'Consumo médio por habitante na região, em litros por dia.',
        unidade: 'L/hab/dia',
        categoria: CategoriaIndicador.recursos,
        historico: _mediaEntreBairros(t.consumoAguaPorBairro),
        fonte: fonteSintetica,
      ),
      Indicador(
        id: 'energia',
        nome: 'Consumo de energia',
        descricao: 'Energia elétrica consumida na região por dia.',
        unidade: 'MWh',
        categoria: CategoriaIndicador.recursos,
        historico: t.energia,
        fonte: fonteSintetica,
        casasDecimais: 0,
      ),
      Indicador(
        id: 'residuos',
        nome: 'Resíduos coletados',
        descricao: 'Toneladas de lixo coletadas por dia na região.',
        unidade: 't',
        categoria: CategoriaIndicador.recursos,
        historico: t.residuos,
        fonte: fonteSintetica,
      ),
      Indicador(
        id: 'reciclagem',
        nome: 'Resíduos reciclados',
        descricao: 'Parte do lixo coletado que foi para a reciclagem.',
        unidade: '%',
        categoria: CategoriaIndicador.recursos,
        historico: t.reciclagem,
        fonte: fonteSintetica,
        subirEhRuim: false,
      ),
    ];

    for (final b in t.bairros) {
      final serie = t.consumoAguaPorBairro[b.id];
      if (serie == null) continue;
      lista.add(Indicador(
        id: 'agua_${b.id}',
        nome: 'Consumo de água - ${b.nome}',
        descricao: 'Consumo médio por habitante no bairro ${b.nome}.',
        unidade: 'L/hab/dia',
        categoria: CategoriaIndicador.recursos,
        historico: serie,
        fonte: fonteSintetica,
        bairroId: b.id,
      ));
    }
    return lista;
  }

  static List<Indicador> _servicos(DadosTerritorio t) {
    final lista = <Indicador>[
      Indicador(
        id: 'atendimentos_ubs',
        nome: 'Atendimentos nas UBS',
        descricao: 'Total de atendimentos por dia nas Unidades Básicas de Saúde '
            'da região. Alta repentina pode indicar surto (ex.: dengue).',
        unidade: 'atend.',
        categoria: CategoriaIndicador.servicos,
        historico: t.atendimentosUbs,
        fonte: fonteSintetica,
        casasDecimais: 0,
      ),
      Indicador(
        id: 'chamados_total',
        nome: 'Chamados de zeladoria',
        descricao: 'Pedidos feitos pela população (156) por dia: bueiro, '
            'buraco, iluminação, entulho...',
        unidade: 'chamados',
        categoria: CategoriaIndicador.servicos,
        historico: _somaEntreBairros(t.chamadosPorBairro),
        fonte: fonteSintetica,
        casasDecimais: 0,
      ),
    ];

    for (final b in t.bairros) {
      final serie = t.chamadosPorBairro[b.id];
      if (serie == null) continue;
      lista.add(Indicador(
        id: 'chamados_${b.id}',
        nome: 'Chamados - ${b.nome}',
        descricao: 'Chamados de zeladoria abertos por dia no bairro ${b.nome}.',
        unidade: 'chamados',
        categoria: CategoriaIndicador.servicos,
        historico: serie,
        fonte: fonteSintetica,
        casasDecimais: 0,
        bairroId: b.id,
      ));
    }
    return lista;
  }

  static List<PontoSerie> _mediaEntreBairros(Map<String, List<PontoSerie>> mapa) {
    final soma = _somaEntreBairros(mapa);
    final qtd = mapa.length;
    return soma.map((p) => PontoSerie(p.data, p.valor / qtd)).toList();
  }

  static List<PontoSerie> _somaEntreBairros(Map<String, List<PontoSerie>> mapa) {
    if (mapa.isEmpty) return [];
    final primeira = mapa.values.first;
    return List.generate(primeira.length, (i) {
      var total = 0.0;
      for (final serie in mapa.values) {
        if (i < serie.length) total += serie[i].valor;
      }
      return PontoSerie(primeira[i].data, total);
    });
  }
}

import 'indicador.dart';

class DiaClima {
  final DateTime data;
  final double temperaturaMaxima;
  final double temperaturaMinima;
  final double chuva;
  final int? probabilidadeChuva;
  final bool ehPrevisao;

  const DiaClima({
    required this.data,
    required this.temperaturaMaxima,
    required this.temperaturaMinima,
    required this.chuva,
    required this.ehPrevisao,
    this.probabilidadeChuva,
  });
}

/// Dados de clima e qualidade do ar vindos do Open-Meteo
/// (ou do cache local quando estiver sem internet).
class DadosClima {
  final List<DiaClima> dias;
  final double? temperaturaAtual;
  final double? umidadeAtual;

  /// Média diária de PM2.5 (passado + previsão). Pode vir vazia se a API
  /// de qualidade do ar falhar.
  final List<PontoSerie> pm25;
  final DateTime atualizadoEm;
  final bool doCache;

  const DadosClima({
    required this.dias,
    required this.pm25,
    required this.atualizadoEm,
    this.temperaturaAtual,
    this.umidadeAtual,
    this.doCache = false,
  });

  List<DiaClima> get historico => dias.where((d) => !d.ehPrevisao).toList();
  List<DiaClima> get previsao => dias.where((d) => d.ehPrevisao).toList();

  DadosClima comoCache() => DadosClima(
        dias: dias,
        pm25: pm25,
        atualizadoEm: atualizadoEm,
        temperaturaAtual: temperaturaAtual,
        umidadeAtual: umidadeAtual,
        doCache: true,
      );

  /// Converte a resposta JSON do Open-Meteo.
  /// [hoje] é passado de fora pra facilitar os testes.
  factory DadosClima.fromApi(
    Map<String, dynamic> clima,
    Map<String, dynamic>? qualidadeAr, {
    required DateTime atualizadoEm,
    required DateTime hoje,
    bool doCache = false,
  }) {
    final daily = clima['daily'] as Map<String, dynamic>;
    final datas = (daily['time'] as List).cast<String>();
    final maximas = daily['temperature_2m_max'] as List;
    final minimas = daily['temperature_2m_min'] as List;
    final chuvas = daily['precipitation_sum'] as List;
    final probs = daily['precipitation_probability_max'] as List?;

    final diaHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final dias = <DiaClima>[];

    for (var i = 0; i < datas.length; i++) {
      // a API às vezes manda null em algum dia, nesse caso pula
      if (maximas[i] == null || minimas[i] == null) continue;
      final data = DateTime.parse(datas[i]);
      dias.add(DiaClima(
        data: data,
        temperaturaMaxima: (maximas[i] as num).toDouble(),
        temperaturaMinima: (minimas[i] as num).toDouble(),
        chuva: (chuvas[i] as num?)?.toDouble() ?? 0,
        probabilidadeChuva: probs == null ? null : (probs[i] as num?)?.toInt(),
        ehPrevisao: data.isAfter(diaHoje),
      ));
    }

    final atual = clima['current'] as Map<String, dynamic>?;

    return DadosClima(
      dias: dias,
      pm25: qualidadeAr == null ? [] : _pm25Diario(qualidadeAr),
      atualizadoEm: atualizadoEm,
      temperaturaAtual: (atual?['temperature_2m'] as num?)?.toDouble(),
      umidadeAtual: (atual?['relative_humidity_2m'] as num?)?.toDouble(),
      doCache: doCache,
    );
  }

  /// A API de qualidade do ar devolve valores por hora. Aqui agrupo por dia
  /// e tiro a média.
  static List<PontoSerie> _pm25Diario(Map<String, dynamic> json) {
    final hourly = json['hourly'] as Map<String, dynamic>?;
    if (hourly == null) return [];
    final horas = (hourly['time'] as List).cast<String>();
    final valores = hourly['pm2_5'] as List;

    final somas = <String, double>{};
    final contagem = <String, int>{};
    for (var i = 0; i < horas.length; i++) {
      final v = valores[i];
      if (v == null) continue;
      final dia = horas[i].substring(0, 10);
      somas[dia] = (somas[dia] ?? 0) + (v as num).toDouble();
      contagem[dia] = (contagem[dia] ?? 0) + 1;
    }

    final dias = somas.keys.toList()..sort();
    return dias
        .map((d) => PontoSerie(DateTime.parse(d), somas[d]! / contagem[d]!))
        .toList();
  }
}

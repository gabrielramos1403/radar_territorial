/// Limiares que disparam os alertas. O gestor pode mudar na tela de
/// configuração, e eles ficam salvos no aparelho.
class Limiares {
  /// Temperatura máxima prevista (°C) a partir da qual vira alerta de calor.
  final double temperaturaMaxima;

  /// Chuva acumulada prevista em 3 dias (mm) para alerta de alagamento.
  final double chuvaAcumulada3Dias;

  /// Nível mínimo aceitável do reservatório (%).
  final double nivelReservatorioMinimo;

  /// Aumento de consumo de água por bairro (%) considerado anormal.
  final double aumentoConsumoAgua;

  /// Aumento na demanda de serviços (UBS / zeladoria) em %.
  final double aumentoDemandaServicos;

  /// PM2.5 médio diário (µg/m³). A OMS recomenda até 15 µg/m³ em 24h.
  final double pm25Maximo;

  const Limiares({
    required this.temperaturaMaxima,
    required this.chuvaAcumulada3Dias,
    required this.nivelReservatorioMinimo,
    required this.aumentoConsumoAgua,
    required this.aumentoDemandaServicos,
    required this.pm25Maximo,
  });

  static const padrao = Limiares(
    temperaturaMaxima: 32,
    chuvaAcumulada3Dias: 50,
    nivelReservatorioMinimo: 35,
    aumentoConsumoAgua: 15,
    aumentoDemandaServicos: 15,
    pm25Maximo: 25,
  );

  Limiares copyWith({
    double? temperaturaMaxima,
    double? chuvaAcumulada3Dias,
    double? nivelReservatorioMinimo,
    double? aumentoConsumoAgua,
    double? aumentoDemandaServicos,
    double? pm25Maximo,
  }) {
    return Limiares(
      temperaturaMaxima: temperaturaMaxima ?? this.temperaturaMaxima,
      chuvaAcumulada3Dias: chuvaAcumulada3Dias ?? this.chuvaAcumulada3Dias,
      nivelReservatorioMinimo:
          nivelReservatorioMinimo ?? this.nivelReservatorioMinimo,
      aumentoConsumoAgua: aumentoConsumoAgua ?? this.aumentoConsumoAgua,
      aumentoDemandaServicos:
          aumentoDemandaServicos ?? this.aumentoDemandaServicos,
      pm25Maximo: pm25Maximo ?? this.pm25Maximo,
    );
  }

  Map<String, dynamic> toJson() => {
        'temperaturaMaxima': temperaturaMaxima,
        'chuvaAcumulada3Dias': chuvaAcumulada3Dias,
        'nivelReservatorioMinimo': nivelReservatorioMinimo,
        'aumentoConsumoAgua': aumentoConsumoAgua,
        'aumentoDemandaServicos': aumentoDemandaServicos,
        'pm25Maximo': pm25Maximo,
      };

  factory Limiares.fromJson(Map<String, dynamic> json) {
    double ler(String chave, double padrao) =>
        (json[chave] as num?)?.toDouble() ?? padrao;

    return Limiares(
      temperaturaMaxima: ler('temperaturaMaxima', padrao.temperaturaMaxima),
      chuvaAcumulada3Dias:
          ler('chuvaAcumulada3Dias', padrao.chuvaAcumulada3Dias),
      nivelReservatorioMinimo:
          ler('nivelReservatorioMinimo', padrao.nivelReservatorioMinimo),
      aumentoConsumoAgua: ler('aumentoConsumoAgua', padrao.aumentoConsumoAgua),
      aumentoDemandaServicos:
          ler('aumentoDemandaServicos', padrao.aumentoDemandaServicos),
      pm25Maximo: ler('pm25Maximo', padrao.pm25Maximo),
    );
  }
}

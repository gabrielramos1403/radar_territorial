/// Configurações de API.
///
/// O Open-Meteo não precisa de chave, então nada sensível fica no código.
/// Mesmo assim os valores podem ser trocados na hora de rodar com
/// --dart-define (ver README), sem precisar mexer aqui.
class ApiConfig {
  ApiConfig._();

  static const urlClima = String.fromEnvironment(
    'URL_CLIMA',
    defaultValue: 'https://api.open-meteo.com/v1/forecast',
  );

  static const urlQualidadeAr = String.fromEnvironment(
    'URL_QUALIDADE_AR',
    defaultValue: 'https://air-quality-api.open-meteo.com/v1/air-quality',
  );

  // centro aproximado da Subprefeitura do Butantã
  static const latitude = -23.5717;
  static const longitude = -46.7081;

  static const timeout = Duration(seconds: 20);

  /// Depois desse tempo o cache é considerado velho e a confiança
  /// dos alertas de clima cai.
  static const validadeCache = Duration(hours: 6);
}

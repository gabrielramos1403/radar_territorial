import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';

class ApiException implements Exception {
  final String mensagem;
  const ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Resposta "crua" das duas APIs do Open-Meteo.
class RespostaClima {
  final Map<String, dynamic> clima;
  final Map<String, dynamic>? qualidadeAr;

  const RespostaClima(this.clima, this.qualidadeAr);
}

/// Busca previsão do tempo e qualidade do ar no Open-Meteo (dados reais).
/// https://open-meteo.com - API aberta, sem chave.
class ClimaApiService {
  final http.Client _client;

  ClimaApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<RespostaClima> buscar() async {
    final uriClima = Uri.parse(ApiConfig.urlClima).replace(queryParameters: {
      'latitude': '${ApiConfig.latitude}',
      'longitude': '${ApiConfig.longitude}',
      'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,'
          'precipitation_probability_max',
      'current': 'temperature_2m,relative_humidity_2m',
      'past_days': '14',
      'forecast_days': '7',
      'timezone': 'America/Sao_Paulo',
    });

    final uriAr = Uri.parse(ApiConfig.urlQualidadeAr).replace(queryParameters: {
      'latitude': '${ApiConfig.latitude}',
      'longitude': '${ApiConfig.longitude}',
      'hourly': 'pm2_5',
      'past_days': '7',
      'forecast_days': '3',
      'timezone': 'America/Sao_Paulo',
    });

    // as duas chamadas saem ao mesmo tempo.
    // A qualidade do ar é um "extra": se falhar, o resto continua.
    final futuroAr = _get(uriAr)
        .then<Map<String, dynamic>?>((r) => r)
        .catchError((Object _) => null);
    final clima = await _get(uriClima);
    final ar = await futuroAr;

    return RespostaClima(clima, ar);
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final resposta = await _client.get(uri).timeout(ApiConfig.timeout);
      if (resposta.statusCode != 200) {
        throw ApiException('Servidor respondeu com erro ${resposta.statusCode}.');
      }
      return jsonDecode(resposta.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw const ApiException('A conexão demorou demais para responder.');
    } on http.ClientException {
      // o pacote http já transforma erro de rede (sem internet) nisso
      throw const ApiException('Sem conexão com a internet ou serviço fora do ar.');
    } on FormatException {
      throw const ApiException('Resposta inválida do serviço de clima.');
    }
  }
}

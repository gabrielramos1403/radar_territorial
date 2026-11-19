import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/alertas_provider.dart';
import 'providers/config_provider.dart';
import 'providers/ocorrencias_provider.dart';
import 'providers/territorio_provider.dart';
import 'services/clima_api_service.dart';
import 'services/storage_service.dart';
import 'services/territorio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // o storage precisa estar pronto antes de montar os providers,
  // assim as preferências já aparecem certas na primeira tela
  final storage = await StorageService.iniciar();

  final config = ConfigProvider(storage);
  final ocorrencias = OcorrenciasProvider(storage);
  final territorio = TerritorioProvider(
    climaApi: ClimaApiService(),
    territorioService: TerritorioService(),
    storage: storage,
    config: config,
  );
  final alertas = AlertasProvider(
    config: config,
    territorio: territorio,
    ocorrencias: ocorrencias,
    storage: storage,
  );

  // já começa a buscar os dados enquanto o app abre
  territorio.carregar();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: config),
        ChangeNotifierProvider.value(value: ocorrencias),
        ChangeNotifierProvider.value(value: territorio),
        ChangeNotifierProvider.value(value: alertas),
      ],
      child: const RadarTerritorialApp(),
    ),
  );
}

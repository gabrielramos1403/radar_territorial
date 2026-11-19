import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/config_provider.dart';

class RadarTerritorialApp extends StatelessWidget {
  const RadarTerritorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();

    final temaClaro = config.altoContraste ? AppTheme.altoContraste() : AppTheme.claro();
    final temaEscuro = config.altoContraste ? AppTheme.altoContraste() : AppTheme.escuro();

    return MaterialApp(
      title: 'Radar Territorial',
      debugShowCheckedModeBanner: false,
      theme: temaClaro,
      darkTheme: temaEscuro,
      themeMode: config.altoContraste ? ThemeMode.dark : config.tema,
      // sem consentimento o app abre direto na tela de LGPD
      initialRoute: config.consentimento ? AppRoutes.home : AppRoutes.consentimento,
      onGenerateRoute: AppRoutes.gerarRota,
      onUnknownRoute: AppRoutes.rotaDesconhecida,
      builder: (context, child) {
        // respeita o tamanho de fonte do sistema e multiplica pela
        // escala escolhida dentro do app
        final sistema = MediaQuery.textScalerOf(context).scale(10) / 10;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(sistema * config.escalaFonte),
          ),
          child: child!,
        );
      },
    );
  }
}

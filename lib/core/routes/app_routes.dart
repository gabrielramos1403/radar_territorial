import 'package:flutter/material.dart';

import '../../screens/alertas/alerta_detalhe_screen.dart';
import '../../screens/configuracoes/limiares_screen.dart';
import '../../screens/consentimento/consentimento_screen.dart';
import '../../screens/dashboards/clima_dashboard_screen.dart';
import '../../screens/dashboards/recursos_dashboard_screen.dart';
import '../../screens/dashboards/servicos_dashboard_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/indicador/indicador_detalhe_screen.dart';
import '../../screens/ocorrencia/nova_ocorrencia_screen.dart';
import '../../screens/sobre/sobre_dados_screen.dart';

/// Todas as rotas nomeadas do app ficam aqui.
/// As telas de detalhe recebem o id pelo `arguments` da rota.
class AppRoutes {
  AppRoutes._();

  static const consentimento = '/consentimento';
  static const home = '/home';
  static const dashboardClima = '/dashboard/clima';
  static const dashboardRecursos = '/dashboard/recursos';
  static const dashboardServicos = '/dashboard/servicos';
  static const indicadorDetalhe = '/indicador';
  static const alertaDetalhe = '/alerta';
  static const novaOcorrencia = '/ocorrencia/nova';
  static const limiares = '/configuracoes/limiares';
  static const sobreDados = '/sobre-dados';

  /// Devolve null para rota desconhecida. Assim, na abertura do app,
  /// o Flutter ignora rotas intermediárias (como "/") em vez de empilhar
  /// uma página de erro embaixo da tela inicial.
  static Route<dynamic>? gerarRota(RouteSettings settings) {
    Widget tela;

    // também aceita o id no próprio caminho (ex.: /alerta/reservatorio),
    // útil para abrir uma tela direto pela URL na versão web
    final nome = settings.name ?? '';
    if (nome.startsWith('$indicadorDetalhe/') || nome.startsWith('$alertaDetalhe/')) {
      final partes = nome.split('/');
      return gerarRota(RouteSettings(
        name: '/${partes[1]}',
        arguments: partes.sublist(2).join('/'),
      ));
    }

    switch (settings.name) {
      case consentimento:
        tela = const ConsentimentoScreen();
        break;
      case home:
        tela = const HomeScreen();
        break;
      case dashboardClima:
        tela = const ClimaDashboardScreen();
        break;
      case dashboardRecursos:
        tela = const RecursosDashboardScreen();
        break;
      case dashboardServicos:
        tela = const ServicosDashboardScreen();
        break;
      case indicadorDetalhe:
        final id = settings.arguments as String?;
        if (id == null || id.isEmpty) return null;
        tela = IndicadorDetalheScreen(indicadorId: id);
        break;
      case alertaDetalhe:
        final id = settings.arguments as String?;
        if (id == null || id.isEmpty) return null;
        tela = AlertaDetalheScreen(alertaId: id);
        break;
      case novaOcorrencia:
        tela = const NovaOcorrenciaScreen();
        break;
      case limiares:
        tela = const LimiaresScreen();
        break;
      case sobreDados:
        tela = const SobreDadosScreen();
        break;
      default:
        return null;
    }

    return MaterialPageRoute(builder: (_) => tela, settings: settings);
  }

  static Route<dynamic> rotaDesconhecida(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Página não encontrada')),
        body: Center(
          child: Text('A rota "${settings.name}" não existe ou faltou parâmetro.'),
        ),
      ),
    );
  }
}

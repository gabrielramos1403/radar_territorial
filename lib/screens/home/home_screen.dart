import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../providers/alertas_provider.dart';
import '../../providers/territorio_provider.dart';
import '../alertas/alertas_screen.dart';
import '../configuracoes/configuracoes_screen.dart';
import '../ocorrencia/ocorrencias_screen.dart';
import 'visao_geral_tab.dart';

/// Tela principal com a barra de navegação inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _abaAtual = 0;

  @override
  void initState() {
    super.initState();
    // carrega os dados depois do primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TerritorioProvider>();
      if (provider.estadoTerritorio == EstadoCarregamento.inicial) {
        provider.carregar();
      }
    });
  }

  void _irParaAba(int indice) => setState(() => _abaAtual = indice);

  @override
  Widget build(BuildContext context) {
    final pendentes = context.watch<AlertasProvider>().pendentes.length;

    final abas = [
      VisaoGeralTab(onVerAlertas: () => _irParaAba(1)),
      const AlertasScreen(),
      const OcorrenciasScreen(),
      const ConfiguracoesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _abaAtual, children: abas),
      floatingActionButton: _abaAtual == 0 || _abaAtual == 2
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.novaOcorrencia),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Registrar ocorrência'),
              tooltip: 'Registrar uma ocorrência anônima no bairro',
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: _irParaAba,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Visão geral',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendentes > 0,
              label: Text('$pendentes'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendentes > 0,
              label: Text('$pendentes'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alertas',
            tooltip: 'Alertas, $pendentes aguardando análise',
          ),
          const NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Ocorrências',
          ),
          const NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

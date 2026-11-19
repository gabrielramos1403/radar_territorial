import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:radar_territorial/core/theme/app_theme.dart';
import 'package:radar_territorial/providers/config_provider.dart';
import 'package:radar_territorial/providers/ocorrencias_provider.dart';
import 'package:radar_territorial/providers/territorio_provider.dart';
import 'package:radar_territorial/screens/consentimento/consentimento_screen.dart';
import 'package:radar_territorial/screens/ocorrencia/nova_ocorrencia_screen.dart';
import 'package:radar_territorial/services/clima_api_service.dart';
import 'package:radar_territorial/services/storage_service.dart';
import 'package:radar_territorial/services/territorio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storage;
  late ConfigProvider config;
  late OcorrenciasProvider ocorrencias;
  late TerritorioProvider territorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.iniciar();
    config = ConfigProvider(storage);
    ocorrencias = OcorrenciasProvider(storage);
    territorio = TerritorioProvider(
      // API de clima "fora do ar" pra não depender de internet no teste
      climaApi: ClimaApiService(
        client: MockClient((_) async => http.Response('erro', 500)),
      ),
      territorioService: TerritorioService(atraso: Duration.zero),
      storage: storage,
      config: config,
    );
  });

  // o ListView só constrói o que está visível, então precisa rolar
  // até o elemento antes de interagir com ele
  Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
    await tester.scrollUntilVisible(
      alvo,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  void telaDeCelular(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
  }

  Widget montar(Widget tela) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: config),
        ChangeNotifierProvider.value(value: ocorrencias),
        ChangeNotifierProvider.value(value: territorio),
      ],
      child: MaterialApp(theme: AppTheme.claro(), home: tela),
    );
  }

  testWidgets('formulário mostra erros quando enviado vazio', (tester) async {
    telaDeCelular(tester);
    await tester.runAsync(() => territorio.carregar());
    await tester.pumpWidget(montar(const NovaOcorrenciaScreen()));
    await tester.pumpAndSettle();

    await rolarAte(tester, find.text('Enviar ocorrência'));
    await tester.tap(find.text('Enviar ocorrência'));
    await tester.pumpAndSettle();

    expect(find.text('Selecione o tipo de problema.'), findsOneWidget);
    expect(find.text('Selecione o bairro.'), findsOneWidget);
    expect(find.text('Preencha a descrição.'), findsOneWidget);
    expect(find.text('Você precisa confirmar para enviar.'), findsOneWidget);
    expect(ocorrencias.total, 0);
  });

  testWidgets('formulário bloqueia telefone na descrição', (tester) async {
    telaDeCelular(tester);
    await tester.runAsync(() => territorio.carregar());
    await tester.pumpWidget(montar(const NovaOcorrenciaScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'O que está acontecendo? *'),
      'Vazamento grande, me liga 11 98888-7777',
    );
    await rolarAte(tester, find.text('Enviar ocorrência'));
    await tester.tap(find.text('Enviar ocorrência'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não informe telefone, e-mail ou CPF. A ocorrência é anônima.'),
      findsOneWidget,
    );
  });

  testWidgets('consentimento só libera o botão depois de marcar as opções',
      (tester) async {
    telaDeCelular(tester);
    await tester.pumpWidget(montar(const ConsentimentoScreen()));
    await tester.pumpAndSettle();

    final botao = find.widgetWithText(FilledButton, 'Concordo e quero continuar');
    await rolarAte(tester, botao);
    expect(tester.widget<FilledButton>(botao).onPressed, isNull);

    await tester.tap(find.text('Li e entendi como meus dados são usados.'));
    await tester.tap(find.textContaining('Concordo que minhas ocorrências'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(botao).onPressed, isNotNull);
  });
}

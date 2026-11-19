import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorial/models/alerta.dart';
import 'package:radar_territorial/models/dados_clima.dart';
import 'package:radar_territorial/models/dados_territorio.dart';
import 'package:radar_territorial/models/limiares.dart';
import 'package:radar_territorial/models/ocorrencia.dart';
import 'package:radar_territorial/services/motor_alertas.dart';

/// Monta um DadosClima "falso" com 14 dias de histórico e 7 de previsão.
DadosClima climaFalso({
  required DateTime hoje,
  List<double>? maximasPrevistas,
  List<double>? chuvasPrevistas,
  bool doCache = false,
  DateTime? atualizadoEm,
}) {
  final base = DateTime(hoje.year, hoje.month, hoje.day);
  final previstas = maximasPrevistas ?? List.filled(7, 27);
  final chuvas = chuvasPrevistas ?? List.filled(7, 0);
  final dias = <DiaClima>[
    for (var i = 13; i >= 0; i--)
      DiaClima(
        data: base.subtract(Duration(days: i)),
        temperaturaMaxima: 26,
        temperaturaMinima: 17,
        chuva: 1,
        ehPrevisao: false,
      ),
    for (var i = 0; i < previstas.length; i++)
      DiaClima(
        data: base.add(Duration(days: i + 1)),
        temperaturaMaxima: previstas[i],
        temperaturaMinima: 18,
        chuva: chuvas[i],
        probabilidadeChuva: 80,
        ehPrevisao: true,
      ),
  ];
  return DadosClima(
    dias: dias,
    pm25: const [],
    atualizadoEm: atualizadoEm ?? hoje,
    doCache: doCache,
  );
}

void main() {
  final hoje = DateTime(2026, 11, 18, 10);
  late DadosTerritorio territorio;

  setUpAll(() {
    // usa o mesmo arquivo de dados sintéticos do app
    final texto = File('assets/data/territorio.json').readAsStringSync();
    territorio = DadosTerritorio.fromJson(
      jsonDecode(texto) as Map<String, dynamic>,
      hoje,
    );
  });

  group('Alertas de clima', () {
    test('não gera alerta de calor quando a previsão está abaixo do limiar', () {
      final motor = MotorAlertas(limiares: Limiares.padrao, agora: hoje);
      final alertas = motor.gerar(clima: climaFalso(hoje: hoje));
      expect(alertas.where((a) => a.id.startsWith('calor')), isEmpty);
    });

    test('gera alerta de calor com justificativa, evidências e limitações', () {
      final motor = MotorAlertas(limiares: Limiares.padrao, agora: hoje);
      final clima = climaFalso(hoje: hoje, maximasPrevistas: [34, 28, 27, 27, 27, 27, 27]);
      final calor = motor.gerar(clima: clima).firstWhere((a) => a.id.startsWith('calor'));

      expect(calor.justificativa, isNotEmpty);
      expect(calor.evidencias, isNotEmpty);
      expect(calor.limitacoes, isNotEmpty);
      // previsão para amanhã = confiança alta
      expect(calor.nivelConfianca, NivelConfianca.alta);
    });

    test('confiança cai quando o dia quente está longe', () {
      final motor = MotorAlertas(limiares: Limiares.padrao, agora: hoje);
      final perto = motor
          .gerar(clima: climaFalso(hoje: hoje, maximasPrevistas: [34, 27, 27, 27, 27, 27, 27]))
          .firstWhere((a) => a.id.startsWith('calor'));
      final longe = motor
          .gerar(clima: climaFalso(hoje: hoje, maximasPrevistas: [27, 27, 27, 27, 27, 27, 34]))
          .firstWhere((a) => a.id.startsWith('calor'));

      expect(longe.confianca, lessThan(perto.confianca));
    });

    test('três dias seguidos de calor viram onda de calor (mais grave)', () {
      final motor = MotorAlertas(limiares: Limiares.padrao, agora: hoje);
      final umDia = motor
          .gerar(clima: climaFalso(hoje: hoje, maximasPrevistas: [33, 27, 27, 27, 27, 27, 27]))
          .firstWhere((a) => a.id.startsWith('calor'));
      final onda = motor
          .gerar(clima: climaFalso(hoje: hoje, maximasPrevistas: [33, 33, 33, 27, 27, 27, 27]))
          .firstWhere((a) => a.id.startsWith('calor'));

      expect(onda.titulo, contains('onda de calor'));
      expect(onda.severidade.index, greaterThan(umDia.severidade.index));
    });

    test('cache antigo reduz a confiança e adiciona limitação', () {
      final motor = MotorAlertas(limiares: Limiares.padrao, agora: hoje);
      final atual = motor
          .gerar(clima: climaFalso(hoje: hoje, maximasPrevistas: [34, 27, 27, 27, 27, 27, 27]))
          .firstWhere((a) => a.id.startsWith('calor'));
      final velho = motor
          .gerar(
            clima: climaFalso(
              hoje: hoje,
              maximasPrevistas: [34, 27, 27, 27, 27, 27, 27],
              doCache: true,
              atualizadoEm: hoje.subtract(const Duration(hours: 20)),
            ),
          )
          .firstWhere((a) => a.id.startsWith('calor'));

      expect(velho.confianca, lessThan(atual.confianca));
      expect(velho.limitacoes.any((l) => l.contains('cache')), isTrue);
    });

    test('gera alerta de alagamento quando a chuva de 3 dias passa do limiar', () {
      final motor = MotorAlertas(limiares: Limiares.padrao, agora: hoje);
      final alertas = motor.gerar(
        clima: climaFalso(hoje: hoje, chuvasPrevistas: [30, 25, 10, 0, 0, 0, 0]),
      );
      expect(alertas.any((a) => a.id.startsWith('chuva')), isTrue);
    });

    test('mudar o limiar muda o resultado', () {
      final clima = climaFalso(hoje: hoje, maximasPrevistas: [31, 27, 27, 27, 27, 27, 27]);
      final padrao = MotorAlertas(limiares: Limiares.padrao, agora: hoje).gerar(clima: clima);
      final sensivel = MotorAlertas(
        limiares: Limiares.padrao.copyWith(temperaturaMaxima: 30),
        agora: hoje,
      ).gerar(clima: clima);

      expect(padrao.any((a) => a.id.startsWith('calor')), isFalse);
      expect(sensivel.any((a) => a.id.startsWith('calor')), isTrue);
    });
  });

  group('Alertas de recursos e serviços (dados sintéticos)', () {
    late List<Alerta> alertas;

    setUp(() {
      alertas = MotorAlertas(limiares: Limiares.padrao, agora: hoje)
          .gerar(territorio: territorio);
    });

    test('detecta a tendência de queda do reservatório', () {
      final r = alertas.firstWhere((a) => a.id == 'reservatorio');
      expect(r.categoria.name, 'recursos');
      expect(r.confianca, greaterThan(0.75)); // a queda é bem linear
    });

    test('detecta consumo anormal só na Vila Sônia', () {
      final agua = alertas.where((a) => a.id.startsWith('agua_')).toList();
      expect(agua.length, 1);
      expect(agua.first.bairroId, 'vila_sonia');
      expect(agua.first.litrosDiaEvitaveis, greaterThan(0));
    });

    test('detecta aumento de procura nas UBS', () {
      expect(alertas.any((a) => a.id == 'ubs_demanda'), isTrue);
    });

    test('detecta alta de chamados no Rio Pequeno', () {
      final chamados = alertas.where((a) => a.id.startsWith('chamados_')).toList();
      expect(chamados.map((a) => a.bairroId), contains('rio_pequeno'));
    });

    test('todo alerta tem justificativa, confiança e limitações', () {
      expect(alertas, isNotEmpty);
      for (final a in alertas) {
        expect(a.justificativa, isNotEmpty, reason: a.id);
        expect(a.limitacoes, isNotEmpty, reason: a.id);
        expect(a.evidencias, isNotEmpty, reason: a.id);
        expect(a.confianca, inInclusiveRange(0.2, 0.95), reason: a.id);
      }
    });

    test('alertas vêm ordenados do mais grave para o menos grave', () {
      for (var i = 1; i < alertas.length; i++) {
        expect(
          alertas[i - 1].severidade.index,
          greaterThanOrEqualTo(alertas[i].severidade.index),
        );
      }
    });
  });

  group('Relatos de cidadãos', () {
    Ocorrencia relato(int horasAtras, {String bairro = 'butanta'}) => Ocorrencia(
          id: 'OC-$horasAtras',
          categoria: CategoriaOcorrencia.lixo,
          bairroId: bairro,
          descricao: 'Entulho acumulado na calçada',
          data: hoje.subtract(Duration(hours: horasAtras)),
        );

    test('3 relatos iguais no mesmo bairro geram alerta', () {
      final alertas = MotorAlertas(limiares: Limiares.padrao, agora: hoje).gerar(
        territorio: territorio,
        ocorrencias: [relato(1), relato(5), relato(30)],
      );
      expect(alertas.any((a) => a.id == 'relatos_butanta_lixo'), isTrue);
    });

    test('relatos em bairros diferentes não geram alerta', () {
      final alertas = MotorAlertas(limiares: Limiares.padrao, agora: hoje).gerar(
        territorio: territorio,
        ocorrencias: [
          relato(1),
          relato(5, bairro: 'morumbi'),
          relato(30, bairro: 'vila_sonia'),
        ],
      );
      expect(alertas.any((a) => a.id.startsWith('relatos_')), isFalse);
    });
  });
}

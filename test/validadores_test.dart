import 'package:flutter_test/flutter_test.dart';
import 'package:radar_territorial/core/utils/estatistica.dart';
import 'package:radar_territorial/core/utils/validadores.dart';

void main() {
  group('Validadores do formulário de ocorrência', () {
    test('descrição vazia ou curta é inválida', () {
      expect(Validadores.descricaoOcorrencia(''), isNotNull);
      expect(Validadores.descricaoOcorrencia('   '), isNotNull);
      expect(Validadores.descricaoOcorrencia('vazamento'), contains('15 caracteres'));
    });

    test('descrição boa é válida', () {
      expect(
        Validadores.descricaoOcorrencia('Água vazando na calçada há dois dias'),
        isNull,
      );
    });

    test('bloqueia telefone, e-mail e CPF na descrição', () {
      expect(
        Validadores.descricaoOcorrencia('Me liga no 11 98765-4321 pra combinar'),
        contains('telefone'),
      );
      expect(
        Validadores.descricaoOcorrencia('meu email é fulano@gmail.com ok'),
        isNotNull,
      );
      expect(
        Validadores.descricaoOcorrencia('meu cpf 123.456.789-09 caso precise'),
        isNotNull,
      );
    });

    test('ponto de referência é opcional mas não aceita número de casa', () {
      expect(Validadores.pontoReferencia(null), isNull);
      expect(Validadores.pontoReferencia(''), isNull);
      expect(Validadores.pontoReferencia('perto da praça'), isNull);
      expect(Validadores.pontoReferencia('Rua X, 1234'), isNotNull);
    });

    test('seleção obrigatória', () {
      expect(Validadores.selecionado(null), isNotNull);
      expect(Validadores.selecionado('butanta'), isNull);
    });
  });

  group('Validador de limiares', () {
    test('aceita vírgula e ponto', () {
      expect(Validadores.numeroNaFaixa('32,5', minimo: 25, maximo: 45), isNull);
      expect(Validadores.numeroNaFaixa('32.5', minimo: 25, maximo: 45), isNull);
    });

    test('recusa texto e valores fora da faixa', () {
      expect(Validadores.numeroNaFaixa('abc', minimo: 25, maximo: 45), 'Digite apenas números.');
      expect(Validadores.numeroNaFaixa('', minimo: 25, maximo: 45), isNotNull);
      expect(Validadores.numeroNaFaixa('50', minimo: 25, maximo: 45), contains('entre 25 e 45'));
    });
  });

  group('Anonimizador', () {
    test('mascara dados pessoais', () {
      final texto = Anonimizador.mascarar('falar com joao@email.com ou 11 91234-5678');
      expect(texto, isNot(contains('joao@email.com')));
      expect(texto, isNot(contains('91234')));
      expect(texto, contains('[removido]'));
    });
  });

  group('Estatística', () {
    test('regressão de uma reta perfeita tem R² = 1', () {
      final reg = Estatistica.regressao([10, 8, 6, 4, 2]);
      expect(reg.inclinacao, closeTo(-2, 0.0001));
      expect(reg.r2, closeTo(1, 0.0001));
    });

    test('variação percentual da última semana', () {
      final serie = [...List.filled(28, 100.0), ...List.filled(7, 120.0)];
      expect(Estatistica.variacaoPercentual(serie), closeTo(20, 0.001));
    });

    test('média e desvio padrão', () {
      expect(Estatistica.media([2, 4, 6]), 4);
      expect(Estatistica.desvioPadrao([2, 4, 6]), closeTo(2, 0.0001));
    });
  });
}

import 'indicador.dart';

class Bairro {
  final String id;
  final String nome;
  final int populacao;

  const Bairro({required this.id, required this.nome, required this.populacao});

  factory Bairro.fromJson(Map<String, dynamic> json) => Bairro(
        id: json['id'] as String,
        nome: json['nome'] as String,
        populacao: (json['populacao'] as num).toInt(),
      );
}

/// Dados de recursos e serviços do território (vêm do serviço simulado).
class DadosTerritorio {
  final String nome;
  final String cidade;
  final String fonte;
  final List<Bairro> bairros;

  final List<PontoSerie> nivelReservatorio;
  final Map<String, List<PontoSerie>> consumoAguaPorBairro;
  final List<PontoSerie> energia;
  final List<PontoSerie> residuos;
  final List<PontoSerie> reciclagem;
  final List<PontoSerie> atendimentosUbs;
  final Map<String, List<PontoSerie>> chamadosPorBairro;

  const DadosTerritorio({
    required this.nome,
    required this.cidade,
    required this.fonte,
    required this.bairros,
    required this.nivelReservatorio,
    required this.consumoAguaPorBairro,
    required this.energia,
    required this.residuos,
    required this.reciclagem,
    required this.atendimentosUbs,
    required this.chamadosPorBairro,
  });

  int get populacaoTotal => bairros.fold(0, (soma, b) => soma + b.populacao);

  Bairro? bairroPorId(String id) {
    for (final b in bairros) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// O JSON guarda só a lista de valores. O último valor é "hoje", então
  /// aqui eu transformo cada posição numa data de verdade.
  factory DadosTerritorio.fromJson(Map<String, dynamic> json, DateTime hoje) {
    final base = DateTime(hoje.year, hoje.month, hoje.day);

    List<PontoSerie> serie(List<dynamic> valores) {
      final n = valores.length;
      return List.generate(
        n,
        (i) => PontoSerie(
          base.subtract(Duration(days: n - 1 - i)),
          (valores[i] as num).toDouble(),
        ),
      );
    }

    Map<String, List<PontoSerie>> seriesPorBairro(Map<String, dynamic> mapa) {
      return mapa.map((k, v) => MapEntry(k, serie(v as List)));
    }

    final territorio = json['territorio'] as Map<String, dynamic>;
    final recursos = json['recursos'] as Map<String, dynamic>;
    final servicos = json['servicos'] as Map<String, dynamic>;

    return DadosTerritorio(
      nome: territorio['nome'] as String,
      cidade: territorio['cidade'] as String,
      fonte: json['fonte'] as String,
      bairros: (json['bairros'] as List)
          .map((b) => Bairro.fromJson(b as Map<String, dynamic>))
          .toList(),
      nivelReservatorio: serie(recursos['nivel_reservatorio'] as List),
      consumoAguaPorBairro:
          seriesPorBairro(recursos['consumo_agua'] as Map<String, dynamic>),
      energia: serie(recursos['energia_mwh'] as List),
      residuos: serie(recursos['residuos_t'] as List),
      reciclagem: serie(recursos['reciclagem_pct'] as List),
      atendimentosUbs: serie(servicos['atendimentos_ubs'] as List),
      chamadosPorBairro: seriesPorBairro(
          servicos['chamados_zeladoria'] as Map<String, dynamic>),
    );
  }
}

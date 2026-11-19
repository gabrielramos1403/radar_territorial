import 'dart:math';

/// Resultado de uma regressão linear simples (y = a + b*x).
class RegressaoLinear {
  final double intercepto;
  final double inclinacao;

  /// Coeficiente de determinação (0 a 1). Quanto mais perto de 1,
  /// melhor a reta explica os dados.
  final double r2;

  const RegressaoLinear(this.intercepto, this.inclinacao, this.r2);

  double prever(double x) => intercepto + inclinacao * x;
}

/// Funções estatísticas usadas pelo motor de alertas.
class Estatistica {
  Estatistica._();

  static double media(List<double> valores) {
    if (valores.isEmpty) return 0;
    return valores.reduce((a, b) => a + b) / valores.length;
  }

  static double desvioPadrao(List<double> valores) {
    if (valores.length < 2) return 0;
    final m = media(valores);
    final soma = valores.fold<double>(0, (acc, v) => acc + pow(v - m, 2));
    return sqrt(soma / (valores.length - 1));
  }

  /// Variação percentual da média dos últimos [janela] dias contra a média
  /// do período anterior (mesmo tamanho * [periodosAnteriores]).
  static double variacaoPercentual(
    List<double> serie, {
    int janela = 7,
    int periodosAnteriores = 4,
  }) {
    if (serie.length < janela * 2) return 0;
    final recente = serie.sublist(serie.length - janela);
    final inicio = max(0, serie.length - janela - janela * periodosAnteriores);
    final anterior = serie.sublist(inicio, serie.length - janela);
    final mediaAnterior = media(anterior);
    if (mediaAnterior == 0) return 0;
    return (media(recente) - mediaAnterior) / mediaAnterior * 100;
  }

  /// z-score da média recente em relação ao histórico anterior.
  static double zScore(List<double> serie, {int janela = 7}) {
    if (serie.length <= janela + 2) return 0;
    final anterior = serie.sublist(0, serie.length - janela);
    final recente = serie.sublist(serie.length - janela);
    final dp = desvioPadrao(anterior);
    if (dp == 0) return 0;
    return (media(recente) - media(anterior)) / dp;
  }

  /// Regressão linear simples por mínimos quadrados, com x = 0, 1, 2...
  static RegressaoLinear regressao(List<double> y) {
    final n = y.length;
    if (n < 2) return RegressaoLinear(n == 1 ? y.first : 0, 0, 0);

    final xs = List<double>.generate(n, (i) => i.toDouble());
    final mx = media(xs);
    final my = media(y);

    double sxy = 0;
    double sxx = 0;
    for (var i = 0; i < n; i++) {
      sxy += (xs[i] - mx) * (y[i] - my);
      sxx += pow(xs[i] - mx, 2);
    }
    final b = sxx == 0 ? 0.0 : sxy / sxx;
    final a = my - b * mx;

    double ssTot = 0;
    double ssRes = 0;
    for (var i = 0; i < n; i++) {
      final previsto = a + b * xs[i];
      ssTot += pow(y[i] - my, 2);
      ssRes += pow(y[i] - previsto, 2);
    }
    final r2 = ssTot == 0 ? 0.0 : (1 - ssRes / ssTot).clamp(0.0, 1.0).toDouble();

    return RegressaoLinear(a, b, r2);
  }

  /// Média móvel simples, usada para suavizar os gráficos.
  static List<double> mediaMovel(List<double> serie, int janela) {
    final resultado = <double>[];
    for (var i = 0; i < serie.length; i++) {
      final inicio = max(0, i - janela + 1);
      resultado.add(media(serie.sublist(inicio, i + 1)));
    }
    return resultado;
  }
}

/// Funções simples de formatação (preferi não usar o pacote intl só pra isso).
class Formatadores {
  Formatadores._();

  static const _diasSemana = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

  static String _doisDigitos(int n) => n.toString().padLeft(2, '0');

  /// 18/11
  static String diaMes(DateTime data) =>
      '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}';

  /// 18/11/2026
  static String data(DateTime data) => '${diaMes(data)}/${data.year}';

  /// 18/11 às 14:05
  static String dataHora(DateTime data) =>
      '${diaMes(data)} às ${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}';

  /// "qua, 18/11"
  static String diaSemana(DateTime data) =>
      '${_diasSemana[data.weekday - 1]}, ${diaMes(data)}';

  /// Número no padrão brasileiro: 1.234,5
  static String numero(double valor, {int casas = 1}) {
    final negativo = valor < 0;
    final partes = valor.abs().toStringAsFixed(casas).split('.');
    final inteiro = partes[0];
    final buffer = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
      buffer.write(inteiro[i]);
    }
    var texto = buffer.toString();
    if (casas > 0) texto += ',${partes[1]}';
    return negativo ? '-$texto' : texto;
  }

  static String inteiro(num valor) => numero(valor.toDouble(), casas: 0);

  static String porcentagem(double valor, {int casas = 0}) =>
      '${numero(valor, casas: casas)}%';

  /// "+12%" ou "-3%"
  static String variacao(double valor) {
    final sinal = valor > 0 ? '+' : '';
    return '$sinal${numero(valor, casas: 1)}%';
  }

  /// "há 5 min", "há 2 h", "há 3 dias"
  static String tempoAtras(DateTime data, {DateTime? agora}) {
    final diff = (agora ?? DateTime.now()).difference(data);
    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return 'há ${diff.inDays} ${diff.inDays == 1 ? 'dia' : 'dias'}';
  }

  /// Quebra nomes grandes em duas linhas pra caber no eixo dos gráficos.
  static String abreviarRotulo(String nome) {
    if (nome.length <= 9) return nome;
    final partes = nome.split(' ');
    if (partes.length == 1) return '${nome.substring(0, 8)}.';
    return '${partes.first}\n${partes.sublist(1).join(' ')}';
  }
}

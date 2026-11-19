/// Validações usadas nos formulários (ocorrência e limiares).
/// Retornam null quando está tudo certo, ou a mensagem de erro.
class Validadores {
  Validadores._();

  static String? obrigatorio(String? valor, {String campo = 'este campo'}) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Preencha $campo.';
    }
    return null;
  }

  static String? selecionado(Object? valor, {String campo = 'uma opção'}) {
    if (valor == null) return 'Selecione $campo.';
    return null;
  }

  static String? descricaoOcorrencia(String? valor) {
    final erro = obrigatorio(valor, campo: 'a descrição');
    if (erro != null) return erro;

    final texto = valor!.trim();
    if (texto.length < 15) {
      return 'Descreva com pelo menos 15 caracteres (faltam ${15 - texto.length}).';
    }
    if (texto.length > 280) {
      return 'Use no máximo 280 caracteres.';
    }
    if (Anonimizador.contemDadoPessoal(texto)) {
      return 'Não informe telefone, e-mail ou CPF. A ocorrência é anônima.';
    }
    return null;
  }

  /// Ponto de referência é opcional, mas não pode ter número de casa
  /// (pra não identificar a residência de ninguém).
  static String? pontoReferencia(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    final texto = valor.trim();
    if (texto.length > 80) return 'Use no máximo 80 caracteres.';
    if (RegExp(r'\d{2,}').hasMatch(texto)) {
      return 'Evite números (como nº da casa). Use algo como "perto da praça".';
    }
    if (Anonimizador.contemDadoPessoal(texto)) {
      return 'Não informe dados pessoais.';
    }
    return null;
  }

  /// Valida um número dentro de uma faixa. Aceita vírgula ou ponto.
  static String? numeroNaFaixa(
    String? valor, {
    required double minimo,
    required double maximo,
    String unidade = '',
  }) {
    if (valor == null || valor.trim().isEmpty) return 'Informe um valor.';
    final numero = double.tryParse(valor.trim().replaceAll(',', '.'));
    if (numero == null) return 'Digite apenas números.';
    if (numero < minimo || numero > maximo) {
      return 'O valor deve ficar entre ${_fmt(minimo)} e ${_fmt(maximo)}$unidade.';
    }
    return null;
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ',');
}

/// Detecta e mascara dados pessoais em texto livre (LGPD).
class Anonimizador {
  Anonimizador._();

  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
  static final _cpf = RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b');
  static final _telefone = RegExp(r'(\(?\d{2}\)?\s?)?9?\d{4}[-\s]?\d{4}');

  static bool contemDadoPessoal(String texto) {
    return _email.hasMatch(texto) ||
        _cpf.hasMatch(texto) ||
        _telefone.hasMatch(texto);
  }

  /// Troca qualquer dado pessoal encontrado por [removido].
  /// Usado como segunda camada antes de salvar.
  static String mascarar(String texto) {
    return texto
        .replaceAll(_email, '[removido]')
        .replaceAll(_cpf, '[removido]')
        .replaceAll(_telefone, '[removido]');
  }
}

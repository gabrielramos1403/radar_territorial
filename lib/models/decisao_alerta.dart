enum StatusDecisao { pendente, emAnalise, confirmado, descartado }

extension StatusDecisaoInfo on StatusDecisao {
  String get nome {
    switch (this) {
      case StatusDecisao.pendente:
        return 'Aguardando análise';
      case StatusDecisao.emAnalise:
        return 'Em análise';
      case StatusDecisao.confirmado:
        return 'Confirmado pelo gestor';
      case StatusDecisao.descartado:
        return 'Descartado pelo gestor';
    }
  }
}

/// Registro da decisão HUMANA sobre um alerta.
/// O app só guarda o que o gestor decidiu, ele nunca decide sozinho.
class DecisaoAlerta {
  final String alertaId;
  final StatusDecisao status;
  final String observacao;
  final DateTime data;

  const DecisaoAlerta({
    required this.alertaId,
    required this.status,
    required this.observacao,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'alertaId': alertaId,
        'status': status.name,
        'observacao': observacao,
        'data': data.toIso8601String(),
      };

  factory DecisaoAlerta.fromJson(Map<String, dynamic> json) {
    return DecisaoAlerta(
      alertaId: json['alertaId'] as String,
      status: StatusDecisao.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => StatusDecisao.pendente,
      ),
      observacao: json['observacao'] as String? ?? '',
      data: DateTime.tryParse(json['data'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

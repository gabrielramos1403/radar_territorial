import 'package:flutter/material.dart';

enum CategoriaOcorrencia { alagamento, vazamento, lixo, iluminacao, buraco, saude }

extension CategoriaOcorrenciaInfo on CategoriaOcorrencia {
  String get nome {
    switch (this) {
      case CategoriaOcorrencia.alagamento:
        return 'Alagamento / bueiro entupido';
      case CategoriaOcorrencia.vazamento:
        return 'Vazamento de água';
      case CategoriaOcorrencia.lixo:
        return 'Lixo ou entulho irregular';
      case CategoriaOcorrencia.iluminacao:
        return 'Iluminação pública';
      case CategoriaOcorrencia.buraco:
        return 'Buraco na via';
      case CategoriaOcorrencia.saude:
        return 'Foco de mosquito / saúde';
    }
  }

  IconData get icone {
    switch (this) {
      case CategoriaOcorrencia.alagamento:
        return Icons.flood_outlined;
      case CategoriaOcorrencia.vazamento:
        return Icons.water_damage_outlined;
      case CategoriaOcorrencia.lixo:
        return Icons.delete_outline;
      case CategoriaOcorrencia.iluminacao:
        return Icons.lightbulb_outline;
      case CategoriaOcorrencia.buraco:
        return Icons.edit_road_outlined;
      case CategoriaOcorrencia.saude:
        return Icons.pest_control_outlined;
    }
  }
}

/// Ocorrência registrada pelo cidadão.
/// Não guarda nome, telefone nem endereço exato: só bairro, categoria
/// e uma descrição (que passa pelo anonimizador antes de salvar).
class Ocorrencia {
  /// Código aleatório, não tem relação com a pessoa.
  final String id;
  final CategoriaOcorrencia categoria;
  final String bairroId;
  final String descricao;
  final String? pontoReferencia;
  final DateTime data;

  const Ocorrencia({
    required this.id,
    required this.categoria,
    required this.bairroId,
    required this.descricao,
    required this.data,
    this.pontoReferencia,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoria': categoria.name,
        'bairroId': bairroId,
        'descricao': descricao,
        'pontoReferencia': pontoReferencia,
        'data': data.toIso8601String(),
      };

  factory Ocorrencia.fromJson(Map<String, dynamic> json) {
    return Ocorrencia(
      id: json['id'] as String,
      categoria: CategoriaOcorrencia.values.firstWhere(
        (c) => c.name == json['categoria'],
        orElse: () => CategoriaOcorrencia.lixo,
      ),
      bairroId: json['bairroId'] as String,
      descricao: json['descricao'] as String,
      pontoReferencia: json['pontoReferencia'] as String?,
      data: DateTime.parse(json['data'] as String),
    );
  }
}

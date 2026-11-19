import 'package:flutter/material.dart';

/// Paleta do Radar Territorial.
/// Verde-azulado lembra água/território e o laranja é usado para atenção.
/// As cores de severidade foram escolhidas checando contraste mínimo 4.5:1
/// com texto branco (WCAG AA).
class AppColors {
  AppColors._();

  static const primaria = Color(0xFF0B5D63);
  static const primariaEscura = Color(0xFF07403F);
  static const secundaria = Color(0xFFE07A1F);
  static const fundoClaro = Color(0xFFF3F6F5);
  static const fundoEscuro = Color(0xFF101716);
  static const superficieEscura = Color(0xFF1A2524);

  // categorias dos dashboards
  static const clima = Color(0xFF2563A8);
  static const recursos = Color(0xFF0B7A6E);
  static const servicos = Color(0xFF7A4BB3);

  // versões claras das categorias para os temas escuro e alto contraste
  // (as cores normais ficam com pouco contraste em fundo preto)
  static const climaClaro = Color(0xFF8DBBF7);
  static const recursosClaro = Color(0xFF5FD8C6);
  static const servicosClaro = Color(0xFFCDAAF7);

  // severidade dos alertas
  static const severidadeBaixa = Color(0xFF2E6B3A);
  static const severidadeModerada = Color(0xFF8A5A00);
  static const severidadeAlta = Color(0xFFB4441C);
  static const severidadeCritica = Color(0xFF9B1C2E);

  // usado no tema de alto contraste
  static const altoContrasteFundo = Colors.black;
  static const altoContrasteTexto = Colors.white;
  static const altoContrasteDestaque = Color(0xFFFFE14D);
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatadores.dart';
import '../../core/utils/validadores.dart';
import '../../models/limiares.dart';
import '../../providers/config_provider.dart';
import '../../widgets/aviso_decisao_humana.dart';
import '../../widgets/resumo_tile.dart';

/// Formulário para configurar os limiares que disparam os alertas.
class LimiaresScreen extends StatefulWidget {
  const LimiaresScreen({super.key});

  @override
  State<LimiaresScreen> createState() => _LimiaresScreenState();
}

class _CampoLimiar {
  final String rotulo;
  final String ajuda;
  final String unidade;
  final double minimo;
  final double maximo;
  final TextEditingController controller;

  _CampoLimiar({
    required this.rotulo,
    required this.ajuda,
    required this.unidade,
    required this.minimo,
    required this.maximo,
    required double valorInicial,
  }) : controller = TextEditingController(
          text: Formatadores.numero(valorInicial, casas: 0),
        );

  double get valor => double.parse(controller.text.trim().replaceAll(',', '.'));
}

class _LimiaresScreenState extends State<LimiaresScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, _CampoLimiar> _campos;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _montarCampos(context.read<ConfigProvider>().limiares);
  }

  void _montarCampos(Limiares l) {
    _campos = {
      'temp': _CampoLimiar(
        rotulo: 'Temperatura máxima prevista',
        ajuda: 'Alerta de calor quando a previsão passar desse valor.',
        unidade: '°C',
        minimo: 25,
        maximo: 45,
        valorInicial: l.temperaturaMaxima,
      ),
      'chuva': _CampoLimiar(
        rotulo: 'Chuva acumulada em 3 dias',
        ajuda: 'Alerta de alagamento a partir desse volume.',
        unidade: 'mm',
        minimo: 10,
        maximo: 300,
        valorInicial: l.chuvaAcumulada3Dias,
      ),
      'reservatorio': _CampoLimiar(
        rotulo: 'Nível mínimo do reservatório',
        ajuda: 'Alerta quando a projeção indicar que vai ficar abaixo disso.',
        unidade: '%',
        minimo: 5,
        maximo: 80,
        valorInicial: l.nivelReservatorioMinimo,
      ),
      'agua': _CampoLimiar(
        rotulo: 'Aumento no consumo de água',
        ajuda: 'Variação da semana (por bairro) considerada anormal.',
        unidade: '%',
        minimo: 5,
        maximo: 100,
        valorInicial: l.aumentoConsumoAgua,
      ),
      'servicos': _CampoLimiar(
        rotulo: 'Aumento na demanda de serviços',
        ajuda: 'Variação da semana nas UBS (chamados usam o dobro).',
        unidade: '%',
        minimo: 5,
        maximo: 100,
        valorInicial: l.aumentoDemandaServicos,
      ),
      'pm25': _CampoLimiar(
        rotulo: 'PM2.5 médio diário',
        ajuda: 'Referência da OMS: 15 µg/m³.',
        unidade: 'µg/m³',
        minimo: 10,
        maximo: 150,
        valorInicial: l.pm25Maximo,
      ),
    };
  }

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final novos = Limiares(
      temperaturaMaxima: _campos['temp']!.valor,
      chuvaAcumulada3Dias: _campos['chuva']!.valor,
      nivelReservatorioMinimo: _campos['reservatorio']!.valor,
      aumentoConsumoAgua: _campos['agua']!.valor,
      aumentoDemandaServicos: _campos['servicos']!.valor,
      pm25Maximo: _campos['pm25']!.valor,
    );
    await context.read<ConfigProvider>().salvarLimiares(novos);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Limiares salvos. Os alertas foram recalculados.')),
    );
    Navigator.of(context).pop();
  }

  void _restaurarPadrao() {
    const p = Limiares.padrao;
    final valores = {
      'temp': p.temperaturaMaxima,
      'chuva': p.chuvaAcumulada3Dias,
      'reservatorio': p.nivelReservatorioMinimo,
      'agua': p.aumentoConsumoAgua,
      'servicos': p.aumentoDemandaServicos,
      'pm25': p.pm25Maximo,
    };
    setState(() {
      valores.forEach((chave, valor) {
        _campos[chave]!.controller.text = Formatadores.numero(valor, casas: 0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Limiares dos alertas'),
        actions: [
          TextButton(
            onPressed: _restaurarPadrao,
            child: const Text('Padrão'),
          ),
        ],
      ),
      body: ConteudoCentralizado(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Text(
                'Os limiares definem quando os dados viram alerta. Valores mais '
                'baixos geram mais alertas (e mais falsos positivos).',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final campo in _campos.values) ...[
                TextFormField(
                  controller: campo.controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: campo.rotulo,
                    helperText: '${campo.ajuda} (entre ${Formatadores.numero(campo.minimo, casas: 0)} '
                        'e ${Formatadores.numero(campo.maximo, casas: 0)})',
                    helperMaxLines: 2,
                    suffixText: campo.unidade,
                  ),
                  validator: (v) => Validadores.numeroNaFaixa(
                    v,
                    minimo: campo.minimo,
                    maximo: campo.maximo,
                    unidade: ' ${campo.unidade}',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const AvisoDecisaoHumana(compacto: true),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar limiares'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

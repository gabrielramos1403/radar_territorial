import 'package:flutter/foundation.dart';

import '../models/dados_clima.dart';
import '../models/dados_territorio.dart';
import '../models/indicador.dart';
import '../services/clima_api_service.dart';
import '../services/indicadores_service.dart';
import '../services/storage_service.dart';
import '../services/territorio_service.dart';
import 'config_provider.dart';

enum EstadoCarregamento { inicial, carregando, sucesso, erro }

/// Estado GLOBAL com os dados do território (clima + recursos + serviços).
/// É usado pela visão geral, pelos 3 dashboards e pela tela de indicador.
class TerritorioProvider extends ChangeNotifier {
  final ClimaApiService _climaApi;
  final TerritorioService _territorioService;
  final StorageService _storage;
  final ConfigProvider _config;

  TerritorioProvider({
    required ClimaApiService climaApi,
    required TerritorioService territorioService,
    required StorageService storage,
    required ConfigProvider config,
  })  : _climaApi = climaApi,
        _territorioService = territorioService,
        _storage = storage,
        _config = config;

  EstadoCarregamento _estadoClima = EstadoCarregamento.inicial;
  EstadoCarregamento _estadoTerritorio = EstadoCarregamento.inicial;
  String? _erroClima;
  String? _erroTerritorio;

  DadosClima? _clima;
  DadosTerritorio? _territorio;
  List<Indicador> _indicadores = [];

  EstadoCarregamento get estadoClima => _estadoClima;
  EstadoCarregamento get estadoTerritorio => _estadoTerritorio;
  String? get erroClima => _erroClima;
  String? get erroTerritorio => _erroTerritorio;
  DadosClima? get clima => _clima;
  DadosTerritorio? get territorio => _territorio;
  List<Indicador> get indicadores => _indicadores;

  bool get carregando =>
      _estadoClima == EstadoCarregamento.carregando ||
      _estadoTerritorio == EstadoCarregamento.carregando;

  /// True quando o clima veio do cache (sem internet).
  bool get usandoCache => _clima?.doCache ?? false;

  List<Indicador> indicadoresDaCategoria(CategoriaIndicador categoria) =>
      _indicadores.where((i) => i.categoria == categoria && i.bairroId == null).toList();

  List<Indicador> indicadoresPorBairro(String prefixo) =>
      _indicadores.where((i) => i.bairroId != null && i.id.startsWith(prefixo)).toList();

  Indicador? indicadorPorId(String id) {
    for (final i in _indicadores) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> carregar() async {
    _estadoClima = EstadoCarregamento.carregando;
    _estadoTerritorio = EstadoCarregamento.carregando;
    _erroClima = null;
    _erroTerritorio = null;
    notifyListeners();

    // os dois carregam em paralelo e cada um atualiza a tela assim que
    // termina (o território não precisa esperar a API de clima)
    await Future.wait([
      _carregarClima().then((_) => _atualizarIndicadores()),
      _carregarTerritorio().then((_) => _atualizarIndicadores()),
    ]);
  }

  void _atualizarIndicadores() {
    _indicadores = IndicadoresService.montar(clima: _clima, territorio: _territorio);
    notifyListeners();
  }

  Future<void> _carregarTerritorio() async {
    try {
      _territorio = await _territorioService.buscar(simularFalha: _config.simularFalha);
      _estadoTerritorio = EstadoCarregamento.sucesso;
    } on ServicoIndisponivelException catch (e) {
      _erroTerritorio = e.mensagem;
      _estadoTerritorio =
          _territorio == null ? EstadoCarregamento.erro : EstadoCarregamento.sucesso;
    } catch (e) {
      _erroTerritorio = 'Erro ao ler os dados do território.';
      _estadoTerritorio =
          _territorio == null ? EstadoCarregamento.erro : EstadoCarregamento.sucesso;
    }
  }

  Future<void> _carregarClima() async {
    try {
      if (_config.simularOffline) {
        throw const ApiException('Modo sem conexão ativado nas configurações.');
      }
      final resposta = await _climaApi.buscar();
      final agora = DateTime.now();
      _clima = DadosClima.fromApi(
        resposta.clima,
        resposta.qualidadeAr,
        atualizadoEm: agora,
        hoje: agora,
      );
      await _salvarCache(resposta, agora);
      _estadoClima = EstadoCarregamento.sucesso;
    } on ApiException catch (e) {
      _usarCacheOuErro(e.mensagem);
    } catch (e) {
      debugPrint('Erro inesperado no clima: $e');
      _usarCacheOuErro('Não foi possível carregar os dados de clima.');
    }
  }

  void _usarCacheOuErro(String mensagem) {
    final cache = _lerCache();
    if (cache != null) {
      _clima = cache;
      _erroClima = mensagem;
      _estadoClima = EstadoCarregamento.sucesso;
    } else {
      _clima = null;
      _erroClima = '$mensagem Ainda não há dados de clima salvos no aparelho.';
      _estadoClima = EstadoCarregamento.erro;
    }
  }

  Future<void> _salvarCache(RespostaClima resposta, DateTime data) async {
    await _storage.salvarJson(StorageService.chaveCacheClima, resposta.clima);
    if (resposta.qualidadeAr != null) {
      await _storage.salvarJson(StorageService.chaveCacheAr, resposta.qualidadeAr!);
    }
    await _storage.salvarTexto(StorageService.chaveCacheData, data.toIso8601String());
  }

  DadosClima? _lerCache() {
    final clima = _storage.lerJson(StorageService.chaveCacheClima);
    final data = DateTime.tryParse(_storage.lerTexto(StorageService.chaveCacheData) ?? '');
    if (clima is! Map<String, dynamic> || data == null) return null;

    final ar = _storage.lerJson(StorageService.chaveCacheAr);
    try {
      return DadosClima.fromApi(
        clima,
        ar is Map<String, dynamic> ? ar : null,
        atualizadoEm: data,
        hoje: DateTime.now(),
        doCache: true,
      );
    } catch (_) {
      // cache corrompido, ignora
      return null;
    }
  }
}

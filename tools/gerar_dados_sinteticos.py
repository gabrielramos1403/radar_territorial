# Script usado para gerar o arquivo assets/data/territorio.json
# Os dados sao SINTETICOS (inventados), mas com ordem de grandeza parecida
# com a realidade da Subprefeitura do Butanta (SP).
# Cada serie tem 60 valores diarios: o ultimo valor e "hoje" e o primeiro e
# "hoje - 59 dias". O app converte isso em datas reais na hora de carregar.
#
# Para rodar: python tools/gerar_dados_sinteticos.py

import json
import math
import random

random.seed(2026)
DIAS = 60

bairros = [
    {"id": "butanta", "nome": "Butantã", "populacao": 54196},
    {"id": "morumbi", "nome": "Morumbi", "populacao": 46957},
    {"id": "raposo_tavares", "nome": "Raposo Tavares", "populacao": 100164},
    {"id": "rio_pequeno", "nome": "Rio Pequeno", "populacao": 118459},
    {"id": "vila_sonia", "nome": "Vila Sônia", "populacao": 108441},
]


def ruido(desvio):
    return random.gauss(0, desvio)


def eh_fim_de_semana(i):
    # Desativado: como as datas sao relativas a "hoje", o padrao semanal
    # ficava desalinhado com o calendario real. Deixei a funcao aqui caso
    # a gente queira usar datas fixas depois.
    return False


# nivel do reservatorio que abastece a regiao (%)
reservatorio = []
nivel = 48.5
for i in range(DIAS):
    nivel -= 0.2 + ruido(0.08)
    reservatorio.append(round(nivel, 1))

# consumo de agua por bairro (litros por habitante por dia)
base_consumo = {
    "butanta": 172,
    "morumbi": 238,
    "raposo_tavares": 141,
    "rio_pequeno": 148,
    "vila_sonia": 156,
}
consumo_agua = {}
for b in bairros:
    serie = []
    for i in range(DIAS):
        v = base_consumo[b["id"]]
        if eh_fim_de_semana(i):
            v *= 1.06
        v += ruido(3.5)
        # anomalia proposital: possivel vazamento na Vila Sonia
        if b["id"] == "vila_sonia" and i >= DIAS - 7:
            v *= 1.24
        serie.append(round(v, 1))
    consumo_agua[b["id"]] = serie

# energia consumida na regiao (MWh por dia)
energia = []
for i in range(DIAS):
    v = 1820 + ruido(25)
    if eh_fim_de_semana(i):
        v -= 160
    if i >= DIAS - 14:
        v *= 1 + 0.006 * (i - (DIAS - 14))
    energia.append(round(v))

# residuos coletados (toneladas por dia) e % reciclado
residuos = []
reciclado = []
for i in range(DIAS):
    v = 415 + ruido(12)
    if eh_fim_de_semana(i):
        v -= 60
    residuos.append(round(v, 1))
    reciclado.append(round(6.2 + i * 0.012 + ruido(0.25), 1))

# atendimentos nas UBS da regiao por dia (sobe nas ultimas 3 semanas)
atendimentos = []
for i in range(DIAS):
    v = 880 + ruido(30)
    if eh_fim_de_semana(i):
        v = 210 + ruido(15)
    elif i >= DIAS - 21:
        v *= 1 + 0.013 * (i - (DIAS - 21))
    atendimentos.append(round(v))

# chamados de zeladoria (156) por bairro por dia
base_chamados = {
    "butanta": 14,
    "morumbi": 9,
    "raposo_tavares": 17,
    "rio_pequeno": 19,
    "vila_sonia": 15,
}
chamados = {}
for b in bairros:
    serie = []
    for i in range(DIAS):
        lam = base_chamados[b["id"]]
        if eh_fim_de_semana(i):
            lam *= 0.5
        # rio pequeno com aumento recente (bueiros, alagamento)
        if b["id"] == "rio_pequeno" and i >= DIAS - 7:
            lam *= 1.55
        v = max(0, round(lam + ruido(math.sqrt(lam))))
        serie.append(v)
    chamados[b["id"]] = serie

dados = {
    "territorio": {
        "nome": "Subprefeitura do Butantã",
        "cidade": "São Paulo - SP",
        "latitude": -23.5717,
        "longitude": -46.7081,
    },
    "fonte": "Dados sintéticos gerados por tools/gerar_dados_sinteticos.py (seed 2026)",
    "dias": DIAS,
    "bairros": bairros,
    "recursos": {
        "nivel_reservatorio": reservatorio,
        "consumo_agua": consumo_agua,
        "energia_mwh": energia,
        "residuos_t": residuos,
        "reciclagem_pct": reciclado,
    },
    "servicos": {
        "atendimentos_ubs": atendimentos,
        "chamados_zeladoria": chamados,
    },
}

with open("assets/data/territorio.json", "w", encoding="utf-8") as f:
    json.dump(dados, f, ensure_ascii=False, indent=1)

print("ok, arquivo gerado")

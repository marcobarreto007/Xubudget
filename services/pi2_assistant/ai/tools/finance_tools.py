# C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant\ai\tools\finance_tools.py
# REM (WHY): lógica objetiva de orçamento -> IA decide quando chamar pra evitar "papagaio"

from typing import Dict

def budget_optimize(renda_mensal: float, categorias: Dict[str, float], metas: Dict[str, float]):
    # Regra simples: teto 50/30/20 ajustado por metas explícitas
    teto_essenciais = renda_mensal * 0.5
    teto_opcionais  = renda_mensal * 0.3
    teto_poupanca   = renda_mensal * 0.2

    essenciais = {k:v for k,v in categorias.items() if k.lower() in ["aluguel","aluguel/mortgage","mercado","contas","transporte"]}
    opcionais  = {k:v for k,v in categorias.items() if k.lower() not in ["aluguel","aluguel/mortgage","mercado","contas","transporte"]}

    total_ess = sum(essenciais.values())
    total_opc = sum(opcionais.values())

    dicas = []
    if total_ess > teto_essenciais: dicas.append(f"Essenciais acima do teto (+{total_ess-teto_essenciais:.2f}). Negocie aluguel/planos ou corte utilidades.")
    if total_opc > teto_opcionais:  dicas.append(f"Opcionais acima do teto (+{total_opc-teto_opcionais:.2f}). Corte assinaturas e refeições fora.")
    if (renda_mensal - total_ess - total_opc) < teto_poupanca:
        faltam = teto_poupanca - (renda_mensal - total_ess - total_opc)
        if faltam > 0:
            dicas.append(f"Poupar ficou curto em {faltam:.2f}. Redirecione 5–10% dos opcionais para poupança.")

    # metas específicas (sobrescreve 50/30/20)
    alertas = []
    for cat, limite in metas.items():
        gasto = categorias.get(cat, 0.0)
        if gasto > limite:
            alertas.append(f"Categoria '{cat}' estourou meta (+{gasto-limite:.2f}).")

    sugestao = {
        "teto_essenciais": round(teto_essenciais,2),
        "teto_opcionais": round(teto_opcionais,2),
        "teto_poupanca": round(teto_poupanca,2),
        "alertas": alertas,
        "dicas": dicas
    }
    return sugestao

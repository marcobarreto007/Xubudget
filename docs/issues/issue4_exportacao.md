# [Export] CSV/XLSX em data/exports + botão "Exportar agora"

**Objetivo**
Gerar export local CSV e XLSX para `data/exports/` com timestamp e acionar via botão no Dashboard.

**Arquivos**
1) mobile_app/lib/services/export_service.dart  (gera CSV/XLSX; cria pasta; usar `intl`)
2) mobile_app/lib/ui/budget_dashboard_page.dart (ATUALIZAR: botão "Exportar agora" -> chama export_service)
3) docs/export_readme.md                        (onde ficam arquivos, timezone, convenção de nome; caminho típico Windows)

**Regras**
- `WHY:` no topo de cada arquivo.
- Evitar hardcode de caminho; preferir `path_provider` + doc ensinando ajustar p/ `C:\\Users\\marco\\Xubudget\\data\\exports\\`
- Sem libs novas além de `csv`/`excel` (já no scaffold).

**Pronto quando**
- Ao clicar o botão, aparecem `.csv` e `.xlsx` em `data/exports/` com carimbo data/hora.

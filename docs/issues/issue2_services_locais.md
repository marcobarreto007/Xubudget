# [Services] OCR, Speech e Parser PT-BR integrados ao UI

**Objetivo**
Implementar serviços locais (Dart) e conectar às telas.

**Arquivos**
1) mobile_app/lib/services/ocr_service.dart        (MLKit: extrair texto de imagem local)
2) mobile_app/lib/services/voice_service.dart      (speech_to_text: iniciar/parar + transcrição)
3) mobile_app/lib/services/expense_parser.dart     (regex PT-BR: "comprei X por 12,34 no dia Y" -> {description, amount, date, category?})
4) mobile_app/lib/ui/capture_receipt_page.dart     (ATUALIZAR p/ chamar ocr_service e exibir texto)
5) mobile_app/lib/ui/manual_entry_page.dart        (ATUALIZAR p/ usar expense_parser)

**Regras**
- `WHY:` no topo de cada arquivo.
- Sem dependências novas além das já no pubspec.
- Nada de rede/http; tudo local.
- Somente os arquivos listados.

**Pronto quando**
- OCR retorna texto básico de imagem local.
- Speech transcreve frases curtas.
- Parser extrai amount/date/descrição em exemplos simples.

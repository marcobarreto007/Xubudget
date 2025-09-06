# [Fix] Completar scaffold Flutter com `flutter create` em mobile_app/

**Problema**
O scaffold atual não tem os diretórios de plataforma preenchidos. Pastas vazias não entram no git e o app não roda com `flutter run`.

**Tarefa**
- Executar `flutter create .` dentro de `mobile_app/` (ou recriar exatamente os arquivos padrão gerados pelo Flutter).
- Committar **todos** os arquivos de `android/`, `ios/`, `web/`, `test/`, `.metadata`, `.gitignore` específicos etc.
- Manter `pubspec.yaml` e `lib/` que já foram criados no PR anterior.

**Regras**
- Não alterar nomes de pacotes ou imports existentes.
- No topo do PR, explicar o que foi adicionado.
- Garantir que `flutter pub get` e `flutter analyze` passem.

**Aceite**
- `flutter run` compila e abre a `BudgetDashboardPage`.

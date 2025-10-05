# XUBUDGET AI - Smoke Test
# Testa todos os endpoints principais do sistema

$base = "http://127.0.0.1:8000"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    XUBUDGET AI - SMOKE TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Teste 1: Health Check
Write-Host "[1/6] Testando Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod "$base/" -Method Get
    Write-Host "✅ Health OK: $($health.service)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Teste 2: Listar Despesas
Write-Host "[2/6] Testando Listar Despesas..." -ForegroundColor Yellow
try {
    $list = Invoke-RestMethod "$base/api/chat/xuzinha" -Method Post -ContentType "application/json" -Body '{"user_id":"smoke","message":"listar despesas por categoria"}'
    Write-Host "✅ Listar OK: $($list.final_answer)" -ForegroundColor Green
    Write-Host "   Tools usadas: $($list.used_tools -join ', ')" -ForegroundColor Gray
} catch {
    Write-Host "❌ Listar FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Teste 3: Aumentar Despesa
Write-Host "[3/6] Testando Aumentar Despesa..." -ForegroundColor Yellow
try {
    $add = Invoke-RestMethod "$base/api/chat/xuzinha" -Method Post -ContentType "application/json" -Body '{"user_id":"smoke","message":"aumente Food em 25"}'
    Write-Host "✅ Aumentar OK: $($add.final_answer)" -ForegroundColor Green
    Write-Host "   Tools usadas: $($add.used_tools -join ', ')" -ForegroundColor Gray
} catch {
    Write-Host "❌ Aumentar FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Teste 4: Definir Categoria
Write-Host "[4/6] Testando Definir Categoria..." -ForegroundColor Yellow
try {
    $set = Invoke-RestMethod "$base/api/chat/xuzinha" -Method Post -ContentType "application/json" -Body '{"user_id":"smoke","message":"setar Transport para 100"}'
    Write-Host "✅ Setar OK: $($set.final_answer)" -ForegroundColor Green
    Write-Host "   Tools usadas: $($set.used_tools -join ', ')" -ForegroundColor Gray
} catch {
    Write-Host "❌ Setar FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Teste 5: Buscar Totais
Write-Host "[5/6] Testando Buscar Totais..." -ForegroundColor Yellow
try {
    $totals = Invoke-RestMethod "$base/api/expenses/totals" -Method Get
    Write-Host "✅ Totais OK: $($totals.totals.Count) categorias" -ForegroundColor Green
    foreach ($cat in $totals.totals.PSObject.Properties) {
        Write-Host "   $($cat.Name): R$ $($cat.Value)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Totais FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Teste 6: Zerar Tudo
Write-Host "[6/6] Testando Zerar Tudo..." -ForegroundColor Yellow
try {
    $reset = Invoke-RestMethod "$base/api/chat/xuzinha" -Method Post -ContentType "application/json" -Body '{"user_id":"smoke","message":"zerar tudo"}'
    Write-Host "✅ Reset OK: $($reset.final_answer)" -ForegroundColor Green
    Write-Host "   Tools usadas: $($reset.used_tools -join ', ')" -ForegroundColor Gray
} catch {
    Write-Host "❌ Reset FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    SMOKE TEST CONCLUÍDO!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Se todos os testes passaram, o sistema está funcionando!" -ForegroundColor Green
Write-Host "Se algum falhou, verifique se o backend está rodando na porta 8000." -ForegroundColor Yellow
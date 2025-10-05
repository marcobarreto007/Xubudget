# Xubudget Smoke Test
# Testa todos os endpoints críticos

Write-Host "🔥 XUBUDGET SMOKE TEST" -ForegroundColor Red
Write-Host "========================" -ForegroundColor Red

# Test 1: Health Check
Write-Host "`n1. Testing Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri "http://127.0.0.1:8000/" -Method GET
    $healthData = $health.Content | ConvertFrom-Json
    if ($healthData.ok) {
        Write-Host "✅ Health Check: OK" -ForegroundColor Green
        Write-Host "   Tools: $($healthData.tools -join ', ')" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Health Check: FAILED" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Health Check: ERROR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: List Expenses
Write-Host "`n2. Testing List Expenses..." -ForegroundColor Yellow
try {
    $listReq = @{
        user_id = "smoke"
        message = "listar despesas por categoria"
    } | ConvertTo-Json
    
    $listResp = Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/chat/xuzinha" -Method POST -Headers @{"Content-Type"="application/json"} -Body $listReq
    $listData = $listResp.Content | ConvertFrom-Json
    
    if ($listData.used_tools -contains "db.get_expenses") {
        Write-Host "✅ List Expenses: OK" -ForegroundColor Green
        Write-Host "   Response: $($listData.final_answer)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ List Expenses: FAILED - No db.get_expenses tool used" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ List Expenses: ERROR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Update Expense
Write-Host "`n3. Testing Update Expense..." -ForegroundColor Yellow
try {
    $updateReq = @{
        user_id = "smoke"
        message = "aumente Food em 20"
    } | ConvertTo-Json
    
    $updateResp = Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/chat/xuzinha" -Method POST -Headers @{"Content-Type"="application/json"} -Body $updateReq
    $updateData = $updateResp.Content | ConvertFrom-Json
    
    if ($updateData.used_tools -contains "db.update_expense") {
        Write-Host "✅ Update Expense: OK" -ForegroundColor Green
        Write-Host "   Response: $($updateData.final_answer)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Update Expense: FAILED - No db.update_expense tool used" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Update Expense: ERROR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Get Totals
Write-Host "`n4. Testing Get Totals..." -ForegroundColor Yellow
try {
    $totalsResp = Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/expenses/totals" -Method GET
    $totalsData = $totalsResp.Content | ConvertFrom-Json
    
    if ($totalsData.totals) {
        Write-Host "✅ Get Totals: OK" -ForegroundColor Green
        Write-Host "   Totals: $($totalsData.totals | ConvertTo-Json -Compress)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Get Totals: FAILED - No totals data" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Get Totals: ERROR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Set Category
Write-Host "`n5. Testing Set Category..." -ForegroundColor Yellow
try {
    $setReq = @{
        user_id = "smoke"
        message = "setar Transport para 100"
    } | ConvertTo-Json
    
    $setResp = Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/chat/xuzinha" -Method POST -Headers @{"Content-Type"="application/json"} -Body $setReq
    $setData = $setResp.Content | ConvertFrom-Json
    
    if ($setData.used_tools -contains "db.set_category") {
        Write-Host "✅ Set Category: OK" -ForegroundColor Green
        Write-Host "   Response: $($setData.final_answer)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Set Category: FAILED - No db.set_category tool used" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Set Category: ERROR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Reset All
Write-Host "`n6. Testing Reset All..." -ForegroundColor Yellow
try {
    $resetReq = @{
        user_id = "smoke"
        message = "zerar tudo"
    } | ConvertTo-Json
    
    $resetResp = Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/chat/xuzinha" -Method POST -Headers @{"Content-Type"="application/json"} -Body $resetReq
    $resetData = $resetResp.Content | ConvertFrom-Json
    
    if ($resetData.used_tools -contains "db.reset") {
        Write-Host "✅ Reset All: OK" -ForegroundColor Green
        Write-Host "   Response: $($resetData.final_answer)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Reset All: FAILED - No db.reset tool used" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Reset All: ERROR - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🔥 SMOKE TEST COMPLETED" -ForegroundColor Red
Write-Host "========================" -ForegroundColor Red

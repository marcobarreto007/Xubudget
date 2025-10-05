$ErrorActionPreference = "Stop"
$base = "http://127.0.0.1:8000"

"GET /" | Write-Host
Invoke-RestMethod "$base/" | ConvertTo-Json -Depth 4

"POST /api/chat/xuzinha listar" | Write-Host
Invoke-RestMethod "$base/api/chat/xuzinha" -Method Post -ContentType "application/json" -Body '{"user_id":"smoke","message":"listar despesas por categoria"}' | ConvertTo-Json -Depth 8

"POST /api/chat/xuzinha aumentar Food em 20" | Write-Host
Invoke-RestMethod "$base/api/chat/xuzinha" -Method Post -ContentType "application/json" -Body '{"user_id":"smoke","message":"aumente Food em 20"}' | ConvertTo-Json -Depth 8

"GET /api/expenses/totals" | Write-Host
Invoke-RestMethod "$base/api/expenses/totals" | ConvertTo-Json -Depth 8

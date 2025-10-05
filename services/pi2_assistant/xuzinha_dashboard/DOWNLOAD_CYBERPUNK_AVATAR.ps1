# Script para baixar avatar cyberpunk da Xuzinha
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   BAIXANDO AVATAR CYBERPUNK DA XUZINHA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Criar pasta se não existir
$imagePath = "public\images\xuzinha"
if (!(Test-Path $imagePath)) {
    New-Item -ItemType Directory -Path $imagePath -Force
    Write-Host "Pasta criada: $imagePath" -ForegroundColor Green
}

# URL de uma imagem cyberpunk gratuita (exemplo)
$imageUrl = "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=400&fit=crop&crop=face"
$outputPath = "$imagePath\xuzinha_avatar.png"

Write-Host "Baixando imagem cyberpunk..." -ForegroundColor Yellow
Write-Host "URL: $imageUrl" -ForegroundColor Gray
Write-Host "Destino: $outputPath" -ForegroundColor Gray
Write-Host ""

try {
    # Baixar a imagem
    Invoke-WebRequest -Uri $imageUrl -OutFile $outputPath -UseBasicParsing
    
    if (Test-Path $outputPath) {
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "   SUCESSO! IMAGEM BAIXADA!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Avatar cyberpunk salvo em: $outputPath" -ForegroundColor Green
        Write-Host ""
        Write-Host "Agora a Xuzinha tem um avatar cyberpunk real!" -ForegroundColor Cyan
        Write-Host "Recarregue a pagina para ver o novo avatar!" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host "Erro: Imagem nao foi baixada!" -ForegroundColor Red
    }
} catch {
    Write-Host "Erro ao baixar imagem: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Tentando alternativa..." -ForegroundColor Yellow
    
    # Tentar uma alternativa
    try {
        $altUrl = "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face"
        Invoke-WebRequest -Uri $altUrl -OutFile $outputPath -UseBasicParsing
        
        if (Test-Path $outputPath) {
            Write-Host "Imagem alternativa baixada com sucesso!" -ForegroundColor Green
        }
    } catch {
        Write-Host "Erro na alternativa tambem. Tente baixar manualmente." -ForegroundColor Red
        Write-Host ""
        Write-Host "INSTRUCOES MANUAIS:" -ForegroundColor Yellow
        Write-Host "1. Vá para: https://unsplash.com/s/photos/cyberpunk-woman" -ForegroundColor White
        Write-Host "2. Escolha uma imagem cyberpunk" -ForegroundColor White
        Write-Host "3. Baixe e salve como: $outputPath" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# WHY: PowerShell script to install Ollama and pull the required model for AI categorization
# This script automates the setup of Ollama with the Qwen2.5-1.5B model for local AI processing

Write-Host "Xubudget - Ollama Setup Script" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Please run as Administrator." -ForegroundColor Red
    pause
    exit 1
}

# Download and install Ollama
Write-Host "Step 1: Downloading Ollama installer..." -ForegroundColor Yellow
$ollamaUrl = "https://ollama.com/download/windows"
$installerPath = "$env:TEMP\OllamaSetup.exe"

try {
    Invoke-WebRequest -Uri $ollamaUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "Ollama installer downloaded successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to download Ollama installer: $_" -ForegroundColor Red
    pause
    exit 1
}

# Install Ollama
Write-Host "Step 2: Installing Ollama..." -ForegroundColor Yellow
try {
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
    Write-Host "Ollama installed successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to install Ollama: $_" -ForegroundColor Red
    pause
    exit 1
}

# Add Ollama to PATH if not already there
$ollamaPath = "$env:LOCALAPPDATA\Programs\Ollama"
if ($env:PATH -notlike "*$ollamaPath*") {
    [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$ollamaPath", [EnvironmentVariableTarget]::User)
    $env:PATH += ";$ollamaPath"
    Write-Host "Added Ollama to PATH." -ForegroundColor Green
}

# Wait for Ollama service to start
Write-Host "Step 3: Starting Ollama service..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Pull the required model
Write-Host "Step 4: Pulling Qwen2.5-1.5B-Instruct model..." -ForegroundColor Yellow
Write-Host "This may take several minutes depending on your internet connection..." -ForegroundColor Cyan

try {
    & ollama pull qwen2.5:1.5b-instruct
    Write-Host "Model pulled successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to pull model: $_" -ForegroundColor Red
    Write-Host "You can try manually running: ollama pull qwen2.5:1.5b-instruct" -ForegroundColor Yellow
}

# Test the installation
Write-Host "Step 5: Testing Ollama installation..." -ForegroundColor Yellow
try {
    $testResult = & ollama list
    Write-Host "Available models:" -ForegroundColor Green
    Write-Host $testResult -ForegroundColor Cyan
} catch {
    Write-Host "Warning: Could not list models. Ollama may need manual configuration." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=============" -ForegroundColor Green
Write-Host "Ollama is now installed and configured with the Qwen2.5-1.5B model." -ForegroundColor White
Write-Host "You can now start the Xubudget backend server using: xubudget_backend_run.bat" -ForegroundColor White
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "- ollama list                    # List installed models" -ForegroundColor Cyan
Write-Host "- ollama serve                   # Start Ollama server manually" -ForegroundColor Cyan
Write-Host "- ollama pull <model>           # Pull additional models" -ForegroundColor Cyan
Write-Host ""

pause
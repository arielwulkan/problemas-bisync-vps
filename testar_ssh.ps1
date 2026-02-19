# Script para diagnosticar SSH
Write-Host "=== DIAGNÓSTICO SSH VPS ===" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar se ssh está disponível
Write-Host "[1] Verificando SSH..." -ForegroundColor Yellow
$sshPath = Get-Command ssh -ErrorAction SilentlyContinue
if ($sshPath) {
    Write-Host "✅ SSH encontrado: $($sshPath.Source)" -ForegroundColor Green
} else {
    Write-Host "❌ SSH não encontrado" -ForegroundColor Red
    exit 1
}

# 2. Verificar chave privada
Write-Host ""
Write-Host "[2] Verificando chave privada..." -ForegroundColor Yellow
$keyPath = "$env:USERPROFILE\.ssh\id_rsa"
if (Test-Path $keyPath) {
    Write-Host "✅ Chave encontrada: $keyPath" -ForegroundColor Green
    $permissions = (Get-Acl $keyPath).Access | Select-Object IdentityReference, FileSystemRights
    Write-Host "Permissões:" -ForegroundColor Gray
    $permissions | Format-Table
} else {
    Write-Host "❌ Chave não encontrada em $keyPath" -ForegroundColor Red
}

# 3. Verificar config SSH
Write-Host ""
Write-Host "[3] Verificando ~/.ssh/config..." -ForegroundColor Yellow
$configPath = "$env:USERPROFILE\.ssh\config"
if (Test-Path $configPath) {
    Write-Host "✅ Config encontrado" -ForegroundColor Green
    Write-Host "Host vps-do:" -ForegroundColor Gray
    Get-Content $configPath | Select-String -Pattern "^Host (vps-do|agentes)" -Context 0,6
} else {
    Write-Host "❌ Config não encontrado" -ForegroundColor Red
}

# 4. Teste de conectividade
Write-Host ""
Write-Host "[4] Testando conectividade porta 22..." -ForegroundColor Yellow
$result = Test-NetConnection -ComputerName 143.198.9.121 -Port 22 -WarningAction SilentlyContinue
if ($result.TcpTestSucceeded) {
    Write-Host "✅ Porta 22 acessível" -ForegroundColor Green
} else {
    Write-Host "❌ Porta 22 não acessível" -ForegroundColor Red
}

# 5. Tentar conexão SSH com verbose
Write-Host ""
Write-Host "[5] Tentando conexão SSH (verbose)..." -ForegroundColor Yellow
Write-Host "Comando: ssh -vvv -i $keyPath -o ConnectTimeout=10 root@143.198.9.121 'whoami'" -ForegroundColor Gray
Write-Host ""

& ssh -vvv -i $keyPath -o ConnectTimeout=10 root@143.198.9.121 'whoami' 2>&1 | Tee-Object -FilePath "ssh_debug.log"

Write-Host ""
Write-Host "Log salvo em: ssh_debug.log" -ForegroundColor Cyan

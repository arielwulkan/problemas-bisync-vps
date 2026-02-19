Write-Host "=== TESTE SSH VPS ===" -ForegroundColor Cyan

$sshPath = Get-Command ssh -ErrorAction SilentlyContinue
if ($sshPath) {
    Write-Host "SSH encontrado: $($sshPath.Source)" -ForegroundColor Green
} else {
    Write-Host "SSH nao encontrado" -ForegroundColor Red
    exit 1
}

$keyPath = "$env:USERPROFILE\.ssh\id_rsa"
if (Test-Path $keyPath) {
    Write-Host "Chave encontrada: $keyPath" -ForegroundColor Green
} else {
    Write-Host "Chave nao encontrada" -ForegroundColor Red
}

Write-Host ""
Write-Host "Testando conectividade..." -ForegroundColor Yellow
$result = Test-NetConnection -ComputerName 143.198.9.121 -Port 22 -WarningAction SilentlyContinue
if ($result.TcpTestSucceeded) {
    Write-Host "Porta 22 acessivel" -ForegroundColor Green
} else {
    Write-Host "Porta 22 nao acessivel" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Tentando SSH com verbose..." -ForegroundColor Yellow
& ssh -vvv -i $keyPath -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@143.198.9.121 'whoami' 2>&1

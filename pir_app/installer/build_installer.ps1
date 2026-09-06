<#
.SYNOPSIS
    Script de automacao para compilacao e empacotamento do PIR App no Windows x64.
.DESCRIPTION
    1. Garante que processos anteriores do pir_app.exe foram encerrados.
    2. Executa flutter build windows --release.
    3. Gera pacote ZIP portatil em dist/.
    4. Procura o compilador do Inno Setup (ISCC.exe) e, se disponivel, compila o instalador .exe.
#>

param (
    [string]$Version = "1.1.0"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
Set-Location $ProjectRoot

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "Iniciando processo de distribuicao do PIR App v$Version" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

# 1. Terminar processos pir_app residuais
Write-Host "`n[1/4] A verificar instancias ativas do pir_app..." -ForegroundColor Yellow
Get-Process -Name "pir_app" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 2. Compilar aplicacao Flutter em modo Release
Write-Host "`n[2/4] A compilar aplicacao Flutter para Windows Release..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha na compilacao do Flutter Windows Release."
    exit 1
}

$ReleaseDir = "$ProjectRoot\build\windows\x64\runner\Release"
if (-not (Test-Path "$ReleaseDir\pir_app.exe")) {
    Write-Error "O executavel nao foi encontrado em: $ReleaseDir\pir_app.exe"
    exit 1
}

# 3. Criar diretorio dist e pacote ZIP portatil
Write-Host "`n[3/4] A gerar pacote portatil ZIP em dist/..." -ForegroundColor Yellow
$DistDir = "$ProjectRoot\dist"
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
}

$ZipPath = "$DistDir\PIR_App_v${Version}_Windows_x64.zip"
if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

Compress-Archive -Path "$ReleaseDir\*" -DestinationPath $ZipPath -CompressionLevel Optimal
$ZipSizeMB = [math]::Round(((Get-Item $ZipPath).Length / 1MB), 2)
Write-Host "Pacote portatil gerado com sucesso: $ZipPath ($ZipSizeMB MB)" -ForegroundColor Green

# 4. Compilar instalador Inno Setup (se ISCC estiver instalado)
Write-Host "`n[4/4] A verificar compilador do Inno Setup..." -ForegroundColor Yellow
$IsccPaths = @(
    "iscc.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
)

$IsccExe = $null
foreach ($p in $IsccPaths) {
    if (Get-Command $p -ErrorAction SilentlyContinue) {
        $IsccExe = $p
        break
    }
    if (Test-Path $p) {
        $IsccExe = $p
        break
    }
}

if ($IsccExe) {
    Write-Host "Compilador Inno Setup encontrado em: $IsccExe" -ForegroundColor Cyan
    $IssScript = "$ProjectRoot\installer\pir_app_setup.iss"
    & $IsccExe $IssScript
    if ($LASTEXITCODE -eq 0) {
        $SetupExe = "$DistDir\PIR_App_v${Version}_Setup.exe"
        if (Test-Path $SetupExe) {
            $SetupSizeMB = [math]::Round(((Get-Item $SetupExe).Length / 1MB), 2)
            Write-Host "Instalador gerado com sucesso: $SetupExe ($SetupSizeMB MB)" -ForegroundColor Green
        }
    } else {
        Write-Warning "Falha na compilacao do instalador Inno Setup."
    }
} else {
    Write-Host "Inno Setup (ISCC.exe) nao detectado no sistema." -ForegroundColor DarkYellow
    Write-Host "   O pacote portatil ZIP esta pronto a utilizar em: $ZipPath" -ForegroundColor DarkYellow
    Write-Host "   Para gerar o instalador .exe, instale o Inno Setup 6 (https://jrsoftware.org/isinfo.php) e execute este script novamente." -ForegroundColor DarkYellow
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "Processo de empacotamento concluido com sucesso!" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

function Install-ClaudeCode {
    [CmdletBinding()]
    param()

    $ErrorActionPreference = 'Stop'

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch { }

    $installerUrl = 'https://claude.ai/install.ps1'
    $binDir       = Join-Path $env:USERPROFILE '.local\bin'

    Write-Host ''
    Write-Host '==> Instalando Claude Code' -ForegroundColor Cyan
    Write-Host "    Windows PowerShell/PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray

    try {
        Write-Host "==> Baixando instalador oficial: $installerUrl" -ForegroundColor Cyan
        $installerCode = Invoke-RestMethod -Uri $installerUrl -UseBasicParsing
        & ([scriptblock]::Create($installerCode))
    } catch {
        Write-Host "[ERRO] Falha ao executar o instalador oficial: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    Write-Host "==> Configurando PATH do usuario: $binDir" -ForegroundColor Cyan
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ([string]::IsNullOrEmpty($userPath)) { $userPath = '' }

    $entries = $userPath -split ';' | Where-Object { $_ -ne '' }
    $alreadyInUserPath = $entries | Where-Object { $_.TrimEnd('\') -ieq $binDir.TrimEnd('\') }

    if ($alreadyInUserPath) {
        Write-Host '    Ja estava no PATH do usuario.' -ForegroundColor DarkGray
    } else {
        $newUserPath = (@($entries) + $binDir) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
        Write-Host '    Adicionado ao PATH do usuario.' -ForegroundColor Green
    }

    $sessionEntries = $env:Path -split ';' | Where-Object { $_ -ne '' }
    if (-not ($sessionEntries | Where-Object { $_.TrimEnd('\') -ieq $binDir.TrimEnd('\') })) {
        $env:Path = ($env:Path.TrimEnd(';')) + ";$binDir"
    }

    Write-Host '==> Verificando instalacao' -ForegroundColor Cyan
    $cmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($cmd) {
        $version = & claude --version 2>$null
        Write-Host "[OK] Claude Code instalado: $version" -ForegroundColor Green
        Write-Host "     Local: $($cmd.Source)" -ForegroundColor DarkGray
        Write-Host ''
        Write-Host "Execute 'claude' para comecar." -ForegroundColor Cyan
    } else {
        Write-Host "[AVISO] O comando 'claude' nao foi encontrado nesta sessao." -ForegroundColor Yellow
        Write-Host '        Feche e abra o terminal e tente novamente.' -ForegroundColor Yellow
    }
}

Install-ClaudeCode

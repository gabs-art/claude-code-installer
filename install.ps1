function Install-ClaudeCode {
    [CmdletBinding()]
    param()

    $ErrorActionPreference = 'Stop'

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch { }

    $installerUrl = 'https://claude.ai/install.ps1'
    $binDir       = Join-Path $env:USERPROFILE '.local\bin'

    function Test-GitInstalled {
        if (Get-Command git -ErrorAction SilentlyContinue) { return $true }
        $paths = @(
            "$env:ProgramFiles\Git\bin\bash.exe",
            "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
            "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
        )
        foreach ($p in $paths) {
            if ($p -and (Test-Path $p)) { return $true }
        }
        return $false
    }

    function Update-SessionPath {
        $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')
        $env:Path = (@($machinePath, $userPath) | Where-Object { $_ }) -join ';'
    }

    Write-Host ''
    Write-Host '==> Instalando Claude Code' -ForegroundColor Cyan
    Write-Host "    Windows PowerShell/PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray

    Write-Host '==> Verificando Git for Windows' -ForegroundColor Cyan
    $gitOk = Test-GitInstalled
    if ($gitOk) {
        Write-Host '    Git encontrado.' -ForegroundColor DarkGray
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host '    Git nao encontrado. Instalando via winget...' -ForegroundColor Yellow
        & winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements
        Update-SessionPath
        $gitOk = Test-GitInstalled
        if ($gitOk) {
            Write-Host '    Git instalado.' -ForegroundColor Green
        } else {
            Write-Host '    [AVISO] Nao foi possivel instalar o Git via winget.' -ForegroundColor Yellow
        }
    } else {
        Write-Host '    [AVISO] Git nao encontrado e winget indisponivel.' -ForegroundColor Yellow
    }

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
    if (-not $cmd) {
        Write-Host "[AVISO] O comando 'claude' nao foi encontrado nesta sessao." -ForegroundColor Yellow
        Write-Host '        Feche e abra o terminal e tente novamente.' -ForegroundColor Yellow
        return
    }

    $version = & claude --version 2>$null
    if ($gitOk) {
        Write-Host "[OK] Claude Code instalado: $version" -ForegroundColor Green
        Write-Host "     Local: $($cmd.Source)" -ForegroundColor DarkGray
        Write-Host ''
        Write-Host "Execute 'claude' para comecar." -ForegroundColor Cyan
    } else {
        Write-Host "[AVISO] Claude Code instalado ($version), mas o Git for Windows esta faltando." -ForegroundColor Yellow
        Write-Host '        O Claude Code nao vai funcionar sem ele.' -ForegroundColor Yellow
        Write-Host '        Instale em https://git-scm.com/download/win e abra um terminal novo.' -ForegroundColor Yellow
    }
}

Install-ClaudeCode

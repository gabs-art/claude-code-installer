function Install-ClaudeCode {
    [CmdletBinding()]
    param()

    $ErrorActionPreference = 'Stop'
    $ProgressPreference    = 'SilentlyContinue'

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
    } catch { }

    $installerUrl = 'https://claude.ai/install.ps1'
    $binDir       = Join-Path $env:USERPROFILE '.local\bin'
    $claudeExe    = Join-Path $binDir 'claude.exe'

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

    function Install-GitDirect {
        if (-not [Environment]::Is64BitOperatingSystem) {
            Write-Host '    [AVISO] Sistema 32 bits: instale o Git manualmente.' -ForegroundColor Yellow
            return
        }
        try {
            Write-Host '    Buscando a versao mais recente do Git for Windows...' -ForegroundColor DarkGray
            $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest' -UseBasicParsing -Headers @{ 'User-Agent' = 'claude-code-installer' }
            $asset = $release.assets | Where-Object { $_.name -match '^Git-.+-64-bit\.exe$' } | Select-Object -First 1
            if (-not $asset) {
                Write-Host '    [AVISO] Instalador do Git nao encontrado na release.' -ForegroundColor Yellow
                return
            }

            $gitInstaller = Join-Path $env:TEMP $asset.name
            Write-Host "    Baixando $($asset.name)..." -ForegroundColor DarkGray
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $gitInstaller -UseBasicParsing

            Write-Host '    Instalando Git (pode pedir permissao de administrador)...' -ForegroundColor DarkGray
            $proc = Start-Process -FilePath $gitInstaller -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-', '/SUPPRESSMSGBOXES' -Verb RunAs -Wait -PassThru
            Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue

            if ($proc.ExitCode -ne 0) {
                Write-Host "    [AVISO] Instalador do Git terminou com codigo $($proc.ExitCode)." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "    [AVISO] Falha ao instalar o Git: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    Write-Host ''
    Write-Host '==> Instalando Claude Code' -ForegroundColor Cyan
    Write-Host "    Windows $([Environment]::OSVersion.Version) | PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray

    Write-Host '==> Verificando Git for Windows' -ForegroundColor Cyan
    $gitOk = Test-GitInstalled
    if ($gitOk) {
        Write-Host '    Git encontrado.' -ForegroundColor DarkGray
    } else {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host '    Git nao encontrado. Instalando via winget...' -ForegroundColor Yellow
            & winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements
            Update-SessionPath
            $gitOk = Test-GitInstalled
        }
        if (-not $gitOk) {
            Write-Host '    Git nao encontrado. Instalando direto do GitHub...' -ForegroundColor Yellow
            Install-GitDirect
            Update-SessionPath
            $gitOk = Test-GitInstalled
        }
        if ($gitOk) {
            Write-Host '    Git instalado.' -ForegroundColor Green
        } else {
            Write-Host '    [AVISO] Nao foi possivel instalar o Git.' -ForegroundColor Yellow
        }
    }

    Write-Host "==> Executando instalador oficial: $installerUrl" -ForegroundColor Cyan
    $nativeOk = $false
    try {
        $installerCode = Invoke-RestMethod -Uri $installerUrl -UseBasicParsing
        & ([scriptblock]::Create($installerCode))
        $nativeOk = Test-Path $claudeExe
    } catch {
        Write-Host "    [AVISO] Instalador oficial falhou: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    if ($nativeOk) {
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
    } else {
        Write-Host '==> Instalador oficial nao concluiu. Tentando via npm' -ForegroundColor Yellow
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            try {
                & npm install -g @anthropic-ai/claude-code
                Update-SessionPath
            } catch {
                Write-Host "    [AVISO] Falha na instalacao via npm: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        } else {
            Write-Host '    [ERRO] npm nao encontrado.' -ForegroundColor Red
            Write-Host '           Instale o Node.js 18+ (https://nodejs.org) e rode o comando novamente.' -ForegroundColor Red
            return
        }
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

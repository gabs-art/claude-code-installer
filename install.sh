#!/usr/bin/env bash
set -euo pipefail

INSTALLER_URL="https://claude.ai/install.sh"
BIN_DIR="$HOME/.local/bin"
CLAUDE_BIN="$BIN_DIR/claude"
MARKER="# claude-code-path"
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

info()  { printf '\033[36m==> %s\033[0m\n' "$*"; }
note()  { printf '\033[90m    %s\033[0m\n' "$*"; }
ok()    { printf '\033[32m[OK] %s\033[0m\n' "$*"; }
warn()  { printf '\033[33m[AVISO] %s\033[0m\n' "$*"; }
fail()  { printf '\033[31m[ERRO] %s\033[0m\n' "$*" >&2; exit 1; }

download() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$1"
    else
        fail "Nem curl nem wget encontrados."
    fi
}

add_path_to() {
    local rc="$1"
    [ -f "$rc" ] || return 0
    if grep -qF "$MARKER" "$rc"; then
        note "$rc: ja configurado"
    else
        printf '\n%s\n%s\n' "$MARKER" "$PATH_LINE" >> "$rc"
        note "$rc: adicionado"
    fi
}

printf '\n'
info "Instalando Claude Code"
note "Usuario: $(whoami) | Sistema: $(uname -sm)"

if [ "$(id -u)" -eq 0 ]; then
    warn "Executando como root: o Claude Code sera instalado apenas para o root."
fi

info "Executando instalador oficial: $INSTALLER_URL"
native_ok=false
if installer="$(download "$INSTALLER_URL")"; then
    if printf '%s\n' "$installer" | bash && [ -x "$CLAUDE_BIN" ]; then
        native_ok=true
    else
        warn "Instalador oficial nao concluiu."
    fi
else
    warn "Falha ao baixar o instalador oficial."
fi

if [ "$native_ok" = true ]; then
    info "Configurando PATH permanente: $BIN_DIR"
    [ -f "$HOME/.profile" ] || touch "$HOME/.profile"
    add_path_to "$HOME/.profile"
    add_path_to "$HOME/.bashrc"
    add_path_to "$HOME/.zshrc"
    export PATH="$BIN_DIR:$PATH"
else
    info "Tentando instalar via npm"
    if command -v npm >/dev/null 2>&1; then
        npm install -g @anthropic-ai/claude-code || fail "Falha na instalacao via npm. Se for erro de permissao, configure um prefixo do npm no seu usuario (npm config set prefix ~/.npm-global)."
    else
        fail "npm nao encontrado. Instale o Node.js 18+ (https://nodejs.org) e rode o comando novamente."
    fi
fi

info "Verificando instalacao"
if command -v claude >/dev/null 2>&1; then
    ok "Claude Code instalado: $(claude --version 2>/dev/null || echo 'versao desconhecida')"
    note "Local: $(command -v claude)"
    printf '\n'
    if [ "$native_ok" = true ]; then
        warn "Para usar neste terminal, rode:  source ~/.bashrc   (ou abra um terminal novo)"
    else
        printf "Execute 'claude' para comecar.\n"
    fi
else
    warn "O comando 'claude' nao foi encontrado. Abra um terminal novo e tente novamente."
fi

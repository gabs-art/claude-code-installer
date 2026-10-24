# claude-code-installer

Instale o [Claude Code](https://docs.claude.com/en/docs/claude-code/overview) com um único comando no PowerShell, no CMD ou no Linux, já com o PATH configurado de forma permanente.

> **Aviso:** este é um projeto **não oficial**, mantido pela comunidade, sem nenhuma ligação com a Anthropic. Ele utiliza o instalador oficial do Claude Code e apenas automatiza as etapas de preparação e configuração ao redor dele.

## Por que usar

O instalador oficial do Claude Code baixa e instala o programa, mas em algumas máquinas ainda é preciso ajustar o PATH manualmente, instalar dependências ou contornar limitações de sistemas mais antigos. Este projeto junta tudo isso em um único comando, o que é útil principalmente para quem precisa instalar o Claude Code em várias máquinas, servidores ou máquinas virtuais.

## Instalação

### Windows (PowerShell)

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; irm https://raw.githubusercontent.com/gabs-art/claude-code-installer/main/install.ps1 | iex
```

### Windows (CMD)

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; irm https://raw.githubusercontent.com/gabs-art/claude-code-installer/main/install.ps1 | iex"
```

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/gabs-art/claude-code-installer/main/install.sh | bash
```

Se a sua distribuição não tiver `curl`:

```bash
wget -qO- https://raw.githubusercontent.com/gabs-art/claude-code-installer/main/install.sh | bash
```

Nenhum dos comandos exige instalar algo antes: eles usam apenas ferramentas que já vêm com o sistema.

## Depois de instalar

No PowerShell, o comando `claude` já funciona na mesma janela. No CMD e no Linux, abra um terminal novo (no Linux, também é possível rodar `source ~/.bashrc`). Para confirmar a instalação:

```bash
claude --version
```

Para começar a usar, entre na pasta do seu projeto e execute:

```bash
claude
```

Na primeira execução, o Claude Code vai pedir que você faça login com a sua conta.

## O que o script faz

### Windows

1. Habilita o TLS 1.2, necessário em versões antigas do Windows para baixar arquivos do GitHub.
2. Verifica se o Git for Windows está instalado, já que o Claude Code depende dele no Windows. Se não estiver, instala via `winget` ou, quando o `winget` não está disponível, baixando o instalador oficial do Git direto do GitHub.
3. Executa o instalador oficial do Claude Code (`https://claude.ai/install.ps1`).
4. Se o instalador oficial falhar, tenta instalar via `npm`, caso o Node.js esteja disponível.
5. Adiciona `%USERPROFILE%\.local\bin` ao PATH do usuário de forma permanente.
6. Confirma se o comando `claude` está funcionando.

### Linux

1. Executa o instalador oficial do Claude Code (`https://claude.ai/install.sh`).
2. Adiciona `~/.local/bin` ao PATH nos arquivos `~/.profile`, `~/.bashrc` e `~/.zshrc` (quando existir).
3. Confirma se o comando `claude` está funcionando.

O script pode ser executado mais de uma vez com segurança: ele reinstala ou atualiza o Claude Code sem duplicar entradas no PATH.

## Requisitos

- **Windows:** Windows 10 ou Windows Server 2019 e versões mais recentes, conforme os requisitos oficiais do Claude Code. Versões anteriores, como o Windows Server 2016, podem funcionar, mas não são suportadas oficialmente.
- **Linux:** qualquer distribuição com `bash` e `curl` ou `wget`.
- Acesso à internet para `claude.ai`, `github.com` e `raw.githubusercontent.com`.
- Uma conta com acesso ao Claude Code.

Consulte a [documentação oficial](https://docs.claude.com/en/docs/claude-code/overview) para os requisitos atualizados.

## Solução de problemas

**"Não foi possível criar um canal seguro para SSL/TLS"**
O comando foi executado sem o trecho inicial que habilita o TLS 1.2. Copie o comando completo da seção de instalação.

**O comando `claude` não é reconhecido**
Feche todos os terminais e abra um novo. Terminais e editores (como o VS Code) que já estavam abertos durante a instalação só enxergam o PATH atualizado depois de reiniciados.

**"Git não encontrado" mesmo após a instalação**
A instalação do Git pode ter sido bloqueada ou cancelada na janela de permissão de administrador. Instale manualmente pelo [site oficial do Git](https://git-scm.com/download/win) e abra um terminal novo.

**"npm não encontrado"**
O instalador oficial falhou e o script não encontrou o Node.js para usar como alternativa. Instale o [Node.js](https://nodejs.org) versão 18 ou superior e execute o comando novamente.

**Erros de conexão em redes corporativas**
Proxies e firewalls podem bloquear `claude.ai` ou `raw.githubusercontent.com`. Verifique com a equipe responsável pela rede se esses endereços estão liberados.

## Observações importantes

- A instalação é feita **por usuário**. Cada conta do sistema precisa executar o comando separadamente.
- No Windows, evite executar o terminal "como administrador" com uma conta diferente da sua, pois o Claude Code será instalado no perfil dessa outra conta.
- No Linux, evite executar como `root` se outro usuário for utilizar o Claude Code, pois a instalação ficará apenas em `/root`.

## Segurança

Executar scripts direto da internet (`irm | iex` ou `curl | bash`) significa rodar o código que estiver no repositório naquele momento. Recomendamos ler os scripts [`install.ps1`](install.ps1) e [`install.sh`](install.sh) antes de usar, principalmente em ambientes de produção. Ambos são curtos e não coletam nem enviam nenhuma informação.

## Contribuindo

Sugestões e correções são bem-vindas. Abra uma [issue](https://github.com/gabs-art/claude-code-installer/issues) descrevendo o problema (incluindo o sistema operacional e a saída completa do terminal) ou envie um pull request.

## Estrutura do repositório

```
claude-code-installer/
├── install.ps1      # Instalador para Windows (PowerShell e CMD)
├── install.sh       # Instalador para Linux
├── .gitattributes   # Garante as quebras de linha corretas em cada script
└── README.md
```

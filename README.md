# claude-code-installer

Instalação do Claude Code em um único comando para PowerShell, CMD e Linux, com o PATH configurado de forma permanente.

> **Aviso:** este é um projeto **não oficial** e não tem nenhuma ligação com a Anthropic. Ele apenas executa o [instalador oficial](https://claude.ai/install.ps1) do Claude Code e, em seguida, ajusta o PATH do usuário para que o comando `claude` fique disponível em qualquer terminal.

## Sobre o projeto

O objetivo é facilitar a instalação do Claude Code em várias máquinas (estações Windows e VMs Linux) usando apenas uma URL, sem precisar instalar nada antes. Os scripts usam somente ferramentas nativas de cada sistema (`irm` no PowerShell e `curl` ou `wget` no Linux).

O que os scripts fazem:

1. Baixam e executam o instalador oficial do Claude Code.
2. Adicionam `~/.local/bin` ao PATH do usuário de forma permanente, sem duplicar a entrada caso o script seja executado novamente.
3. Verificam se o comando `claude` ficou disponível.

## Instalação

Substitua `SEU_USUARIO` pelo seu usuário do GitHub.

### PowerShell

```powershell
irm https://raw.githubusercontent.com/SEU_USUARIO/claude-code-installer/main/install.ps1 | iex
```

### CMD

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/SEU_USUARIO/claude-code-installer/main/install.ps1 | iex"
```

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/SEU_USUARIO/claude-code-installer/main/install.sh | bash
```

Se a máquina não tiver `curl`:

```bash
wget -qO- https://raw.githubusercontent.com/SEU_USUARIO/claude-code-installer/main/install.sh | bash
```

## Após a instalação

No PowerShell, o comando `claude` já fica disponível na mesma janela. No CMD e no Linux, abra um terminal novo (ou, no Linux, execute `source ~/.bashrc`) e depois rode:

```bash
claude
```

## Observações

- A instalação é feita **por usuário**. Cada conta da máquina precisa executar o comando uma vez.
- No Linux, evite rodar como `root` se outro usuário for utilizar o Claude Code, pois a instalação ficará apenas em `/root`.
- Executar o script mais de uma vez é seguro: ele reinstala ou atualiza o Claude Code sem duplicar o PATH.

## Estrutura

```
claude-code-installer/
├── install.ps1      # Windows (PowerShell e CMD)
├── install.sh       # Linux
├── .gitattributes   # Garante quebras de linha corretas em cada script
└── README.md
```

## Documentação oficial

Para mais informações sobre o Claude Code, consulte a [documentação oficial](https://docs.claude.com/en/docs/claude-code/overview).

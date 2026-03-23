# Manager Linux

> Painel de controle pessoal para pós-instalação e manutenção do Linux Mint 22.x

Este é um projeto **pessoal**, criado para atender às minhas próprias necessidades depois de formatar e reinstalar o sistema. Com o tempo foi crescendo e ganhando mais funcionalidades. Se você tiver um fluxo de trabalho parecido e quiser usar ou contribuir, seja bem-vindo.

---

## O que faz

O `manager.sh` é o ponto de entrada: um menu interativo que organiza todas as tarefas em scripts especializados.

| Opção | Script | Função |
|-------|--------|--------|
| 1 | `pos-instalacao/pos-install.sh` | Pós-instalação completa (APT, Flatpak, drivers) |
| 2 | `pos-instalacao/modelos.sh` | Cria modelos de arquivo no Nemo (Office, PHP, HTML, Shell) |
| 3 | `apps-install/apps-manager.sh` | Gestão de apps, limpeza profunda, sync de temas GTK |
| 4 | `apps-install/apps-install.sh` | Loja customizada de Flatpaks |
| 5 | `manager.sh` | Instala `update-system` como comando global |

---

## Estrutura do projeto

```
manager-linux/
├── manager.sh              # Hub central — menu principal
├── utils.sh                # Biblioteca compartilhada (cores, funções, limpeza)
├── update-system.sh        # Manutenção completa do sistema (instalável globalmente)
├── pos-instalacao/
│   ├── pos-install.sh      # Pós-instalação (APT + Flatpak + drivers)
│   └── modelos.sh          # Templates de arquivo para o Nemo
└── apps-install/
    ├── apps-manager.sh     # Gerenciador de apps e limpeza
    └── apps-install.sh     # Loja interativa de Flatpaks
```

---

## Como usar

**Clone o repositório:**

```bash
git clone https://github.com/kaduvelasco/my-mint.git
cd my-mint
bash manager.sh
```

**Para instalar o comando `update-system` globalmente** (e poder apagar o repositório depois):

```
Escolha a opção 6 no menu principal.
```

A partir daí, `update-system` funciona em qualquer terminal, independentemente do repositório.

**Para executar a manutenção do sistema:**

```bash
update-system
```

---

## Requisitos

- Linux Mint 22.x (base Ubuntu 24.04 / Noble)
- Bash 5+
- Conexão com a internet (para instalações)
- `sudo` disponível para o usuário

Dependências opcionais (detectadas automaticamente): `flatpak`, `journalctl`, `updatedb`, `python3`.

---

## O que o `update-system` faz

Em ordem de execução:

1. `apt update` + `upgrade` + `full-upgrade`
2. `flatpak update` + remoção de runtimes não utilizados
3. `apt autoremove` + `autoclean` + `clean`
4. Vacuum do journald (remove logs com mais de 7 dias)
5. Limpeza do cache de thumbnails
6. `updatedb` (atualiza índice do plocate)
7. Dica de Vulkan se GPU AMD for detectada

Tudo registrado em `~/manutencao_sistema.log`.

---

## Aplicativos disponíveis na loja (Flatpak)

| Categoria | Apps |
|-----------|------|
| Navegadores | Firefox, Chromium, Zen Browser |
| Design | Inkscape, Krita, Lunacy, Penpot, MyPaint, Vara, Eyedropper |
| Produtividade | LibreOffice, ONLYOFFICE, Planify, Web Apps, Gear Lever |
| Dev / Rede | FileZilla, Meld |
| Utilidades | Parabolic (yt-dlp GUI), AnyDesk |
| Educação | Tux Paint, GCompris |
| Script externo | Linux Toys |

---

## Contribuindo

Este é um projeto pessoal e reflete minhas escolhas e necessidades específicas — hardware AMD, Linux Mint com Cinnamon, fluxo de trabalho focado em desenvolvimento e gaming. Dito isso, se você quiser adaptar, melhorar ou adicionar algo, fique à vontade.

**Formas de contribuir:**

- Abra uma *issue* descrevendo um problema ou sugestão
- Envie um *pull request* com sua melhoria
- Adapte o projeto para o seu próprio uso

Só peço que qualquer contribuição siga o estilo já estabelecido: funções centralizadas no `utils.sh`, paleta de cores padronizada via `COR_*`, e cabeçalhos de comentário completos em cada script.

---

## Licença

MIT — use, modifique e distribua à vontade.

---

*Feito por Kadu Velasco*

# LuminaStack — Guia de Estilo

Referência de cores, formatos e padrões adotados em todos os scripts do projeto.

---

## Paleta de Cores ANSI

Definida centralmente em `lib/colors.sh` e redefinida localmente nos scripts instalados em `/usr/local/bin` (que rodam fora do projeto).

| Variável    | Código ANSI      | Cor          | Uso                                              |
| ----------- | ---------------- | ------------ | ------------------------------------------------ |
| `$AZUL`     | `\033[0;34m`     | Azul         | Cabeçalhos, bordas de menu, mensagens informativas, separadores |
| `$VERDE`    | `\033[0;32m`     | Verde        | Opções numeradas do menu, confirmações de sucesso |
| `$AMARELO`  | `\033[1;33m`     | Amarelo bold | Avisos, valores destacados, dados do usuário     |
| `$VERMELHO` | `\033[0;31m`     | Vermelho     | Erros, opção de saída (`0`), ações destrutivas   |
| `$RESET`    | `\033[0m`        | —            | Reseta a cor após qualquer trecho colorido       |

### Declaração nos scripts da `lib/`

```bash
# lib/colors.sh carregado via install.sh — usar export
export VERDE='\033[0;32m'
export AMARELO='\033[1;33m'
export VERMELHO='\033[0;31m'
export AZUL='\033[0;34m'
export RESET='\033[0m'
```

### Declaração nos scripts instalados globalmente

```bash
# Cores definidas localmente — scripts rodam fora do projeto
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
RESET='\033[0m'
```

---

## Tipos de Mensagem

### Sucesso

```bash
echo -e "${VERDE}✅ Operação concluída com sucesso!${RESET}"
```

### Erro

```bash
echo -e "${VERMELHO}❌ Mensagem de erro.${RESET}"
```

### Aviso

```bash
echo -e "${AMARELO}⚠️  Mensagem de aviso.${RESET}"
```

### Informação / Ação em progresso

```bash
echo -e "${AZUL}⚙️  Executando operação...${RESET}"
echo -e "${AZUL}🔍 Verificando estado...${RESET}"
echo -e "${AZUL}🚀 Iniciando ambiente...${RESET}"
```

### Valor destacado dentro de uma mensagem

O texto de contexto fica na cor da mensagem; o valor relevante para o usuário fica em `$AMARELO`.

```bash
echo -e "   📁 Destino: ${AMARELO}$FULL_PATH${RESET}"
echo -e "   Acesse: ${AMARELO}http://localhost${RESET} para o dashboard"
echo -e "   💾 Último backup: ${AMARELO}$DATA${AZUL} — $(basename "$ULTIMO")${RESET}"
```

---

## Padrão de Menu Interativo

### Estrutura

```
====================================
      TÍTULO DA SEÇÃO
====================================
   1. Opção de ação
   2. Outra opção
   0. Sair
====================================
```

### Implementação

```bash
show_menu() {
    echo -e "\n${AZUL}====================================${RESET}"
    echo -e "${AZUL}      LUMINA STACK MANAGER${RESET}"
    echo -e "${AZUL}====================================${RESET}"
    echo -e "   ${VERDE}1.${RESET} Iniciar ambiente"
    echo -e "   ${VERDE}2.${RESET} Visualizar logs"
    echo -e "   ${AMARELO}5.${RESET} Corrigir permissões"   # Amarelo: ação especial/de manutenção
    echo -e "   ${AZUL}6.${RESET} Status e recursos"        # Azul: ação informativa
    echo -e "   ${VERMELHO}0.${RESET} Sair"                 # Vermelho: saída/destructiva
    echo -e "${AZUL}====================================${RESET}"
}
```

### Regras de cor nas opções

| Cor        | Quando usar                                          |
| ---------- | ---------------------------------------------------- |
| `$VERDE`   | Opções de ação padrão (a maioria das opções)         |
| `$AMARELO` | Opções de manutenção, reparo ou ajuste de sistema    |
| `$AZUL`    | Opções de visualização ou consulta                   |
| `$VERMELHO`| Opção `0` (sair) e ações destrutivas ou irreversíveis|

### Separadores de seção

Borda de menu (cabeçalho/rodapé):
```
====================================
```

Separador interno (divisão de blocos dentro de uma tela):
```bash
echo -e "${AZUL}──────────────────────────────────${RESET}"
```

---

## Submenu de Contexto (Instalador)

O menu do instalador (`lib/menu.sh`) usa descrição contextual em cada opção com recuo `↳`:

```bash
echo -e " ${VERDE}1.${RESET} Instalar pré-requisitos"
echo -e "    ${AZUL}↳ curl, git, openssl, lsof${RESET}"
```

---

## Prompts de Entrada

```bash
# Padrão: read -r -p para evitar interpretação de backslash
read -r -p "Selecione uma opção: " opt

# Leitura de senha (sem eco)
read -r -s -p "   🔑 Senha MariaDB: " DB_PASS
echo ""  # quebra de linha após senha oculta

# Confirmação s/N (padrão não)
read -r -p "Confirmar? (s/N): " resp
[[ "$resp" =~ ^[sS]$ ]] && executar_acao

# Confirmação S/n (padrão sim)
echo -ne "   💾 Fazer backup antes de parar? (${VERDE}S${RESET}/n): "
read -r DO_BACKUP
[[ -z "$DO_BACKUP" || "$DO_BACKUP" =~ ^[sS]$ ]] && executar_backup
```

---

## Cabeçalho de Script

Todo arquivo `.sh` do projeto abre com o seguinte bloco de documentação:

```bash
#!/usr/bin/env bash

# ==============================================================================
# LuminaStack - Nome do Script
# ==============================================================================
# Descrição   : O que este script faz, em uma ou duas linhas.
# Dependências: lib/colors.sh (carregado via install.sh)
# Uso         : source lib/nome.sh  ou  ./scripts/nome.sh
# Versão      : X.X.X
# ==============================================================================
```

### Separador de seção interna

```bash
# ==============================================================================
# NOME DA SEÇÃO (ex: FUNÇÕES AUXILIARES, MENU PRINCIPAL)
# ==============================================================================
```

---

## Emojis por Contexto

| Emoji | Contexto                                              |
| ----- | ----------------------------------------------------- |
| ✅    | Sucesso, conclusão de operação                        |
| ❌    | Erro, falha, opção inválida                           |
| ⚠️    | Aviso não-fatal, situação que requer atenção          |
| 🚀    | Início de operação principal (subir ambiente)         |
| 🛑    | Parada de serviço                                     |
| 🔌    | Desligamento de containers                            |
| 🔍    | Verificação, busca, diagnóstico                       |
| ⚙️    | Operação em andamento (configuração, execução)        |
| 📁    | Caminho de diretório ou arquivo                       |
| 📄    | Nome de arquivo gerado                                |
| 💾    | Backup, persistência de dados                         |
| 🗄️    | Banco de dados                                        |
| 📍    | Localização (host, endereço)                          |
| 🔌    | Porta de rede                                         |
| 👤    | Usuário                                               |
| 🔑    | Senha, credencial                                     |
| 🧹    | Limpeza de arquivos antigos                           |
| 🛠️    | Manutenção, reparo, otimização                        |
| 📊    | Métricas, uso de recursos                             |
| 📜    | Logs                                                  |
| 🔧    | Ajuste de configuração ou permissões                  |
| ⚡    | Otimização de performance                             |
| 📦    | Instalação de pacote                                  |
| 🐳    | Docker                                                |
| ⏳    | Operação demorada em andamento                        |

---

## Mensagens de Opção Inválida

```bash
echo -e "${VERMELHO}❌ Opção inválida. Digite um número de 0 a N.${RESET}"
sleep 1
```

> Sempre indicar o intervalo válido (`de 0 a N`). Nunca dizer apenas "opção inválida".

---

## Mensagem de Saída

```bash
echo -e "\n${VERDE}Até logo!${RESET}\n"
exit 0
```

---

## Mensagem de Conclusão (Instalador)

Após cada operação no instalador, exibir confirmação e aguardar o usuário antes de voltar ao menu:

```bash
concluir_acao() {
    local LABEL="$1"
    echo -e "\n${VERDE}✅ $LABEL concluída com sucesso!${RESET}"
    echo -e "${AZUL}──────────────────────────────────${RESET}"
    read -r -p "   Pressione Enter para voltar ao menu..."
}
```

---

## Pausa Entre Ações

```bash
read -r -p "Pressione Enter para continuar..."
```

Usada ao final de operações longas (backup, restore, verificação) antes de retornar ao menu.

---

## Formatação de Blocos Informativos

```bash
echo -e "\n${AZUL}🗄️  Banco de Dados (MariaDB)${RESET}"
echo -e "${AZUL}──────────────────────────────────${RESET}"
echo -e "   📍 Host  : ${AMARELO}localhost${RESET}"
echo -e "   🔌 Porta : ${AMARELO}3306${RESET}"
echo -e "   👤 Usuário: ${AMARELO}$DB_USER${RESET}"
echo -e "${AZUL}──────────────────────────────────${RESET}\n"
```

Padrão: título em `$AZUL` com emoji → separador `──...──` em `$AZUL` → linhas com recuo de 3 espaços → rótulo em `$RESET`, valor em `$AMARELO` → separador de fechamento.

---

## Flags de Linha de Comando

Todo comando global (`lumina`, `lumina-db`) deve suportar:

```bash
[[ "$1" == "-h" || "$1" == "--help" ]]    && show_help && exit 0
[[ "$1" == "-v" || "$1" == "--version" ]] && echo "LuminaStack X vX.X.X" && exit 0
```

O `show_help` usa heredoc sem cores (compatível com redirecionamento para `less`/`man`):

```bash
show_help() {
    cat << EOF
nome-do-comando — Descrição curta

USO:
  comando               Comportamento padrão
  comando -h, --help    Exibe esta ajuda
  comando -v, --version Exibe a versão

OPÇÕES DO MENU:
  1  Nome da opção   Descrição do que faz

EXEMPLOS:
  comando              # Comentário
EOF
}
```

---

## Convenções de Nomeação

| Elemento             | Convenção                  | Exemplo                      |
| -------------------- | -------------------------- | ---------------------------- |
| Variáveis de cor     | MAIÚSCULAS, sem prefixo    | `VERDE`, `AZUL`, `RESET`     |
| Variáveis locais     | MAIÚSCULAS dentro de funções | `BACKUP_DIR`, `FILE_NAME`  |
| Funções              | snake_case em português    | `executar_backup`, `show_menu` |
| Funções de menu      | `show_*` ou `exibir_*`     | `show_menu`, `exibir_menu`   |
| Funções auxiliares   | verbo + substantivo        | `verificar_docker`, `ler_credenciais` |
| Arquivos de script   | kebab-case                 | `lumina-db.sh`, `clean-docker.sh` |
| Arquivos da lib      | snake_case                 | `colors.sh`, `scripts-installer.sh` |

---

## Estrutura do Loop Principal

```bash
while true; do
    show_menu
    read -r -p "Escolha uma opção: " OPTION

    case $OPTION in
        1) acao_um ;;
        2) acao_dois ;;
        0)
            echo -e "\n${VERDE}Até logo!${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "${VERMELHO}❌ Opção inválida. Digite um número de 0 a N.${RESET}"
            sleep 1
            ;;
    esac
done
```

---

## Referência Rápida de Cores por Situação

```bash
# ✅ Sucesso
echo -e "${VERDE}✅ Operação realizada.${RESET}"

# ❌ Erro fatal
echo -e "${VERMELHO}❌ Falha ao executar. Verifique os logs.${RESET}"

# ⚠️ Aviso não-fatal
echo -e "${AMARELO}⚠️  Atenção: disco com ${USO}% de uso.${RESET}"

# ℹ️ Ação em andamento
echo -e "${AZUL}⚙️  Configurando ambiente...${RESET}"

# 📍 Valor de destaque dentro de contexto azul
echo -e "${AZUL}   Host: ${AMARELO}localhost${RESET}"

# 🔗 Link / URL
echo -e "   Acesse: ${AMARELO}http://localhost${RESET}"

# 📁 Caminho de arquivo
echo -e "   📁 Destino: ${AMARELO}$CAMINHO${RESET}"
```

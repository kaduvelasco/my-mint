#!/usr/bin/env bash

# ==============================================================================
# utils.sh — Biblioteca Compartilhada | Manager Linux
# ==============================================================================
# Descrição   : Funções e constantes compartilhadas por todos os scripts do
#               projeto. ATENÇÃO: NÃO executar diretamente.
# Uso         : source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
# Versão      : 2.0.0
# ==============================================================================
# FUNÇÕES DISPONÍVEIS:
#   print_header  <título>          — Cabeçalho de seção colorido
#   print_ok      <mensagem>        — Mensagem de sucesso
#   print_warn    <mensagem>        — Mensagem de aviso
#   print_err     <mensagem>        — Mensagem de erro
#   print_info    <mensagem>        — Mensagem informativa
#   require_root                    — Aborta se não for root
#   require_internet                — Aborta se não houver conexão
#   wait_enter                      — Pausa até Enter
#   apt_install   <pkg...>          — Instala pacote(s) APT silenciosamente
#   flatpak_ok                      — Retorna 0 se flatpak estiver disponível
#   cleanup_apt                     — autoremove + autoclean + clean
#   cleanup_flatpak                 — Remove runtimes não utilizados
#   cleanup_logs  [dias]            — Vacuum do journald (padrão: 7 dias)
#   cleanup_thumbnails              — Remove cache de thumbnails
# ==============================================================================

# Evita carregamento duplo
[[ -n "${_UTILS_LOADED:-}" ]] && return 0
_UTILS_LOADED=1

# ==============================================================================
# PALETA DE CORES
# ==============================================================================

export AZUL='\033[0;34m'
export VERDE='\033[0;32m'
export AMARELO='\033[1;33m'
export VERMELHO='\033[0;31m'
export RESET='\033[0m'

# Símbolos de status
readonly SIM_OK="✅"
readonly SIM_ERRO="❌"
readonly SIM_AVISO="⚠️ "
readonly SIM_INFO="ℹ️ "
readonly SIM_SETA="🚀"

# ==============================================================================
# FUNÇÕES DE EXIBIÇÃO
# ==============================================================================

# Cabeçalho de seção
# Uso: print_header "Título da seção"
print_header() {
    echo -e "\n${AZUL}====================================${RESET}"
    echo -e " ${VERDE}${1}${RESET}"
    echo -e "${AZUL}====================================${RESET}\n"
}

# Mensagem de sucesso
# Uso: print_ok "Operação concluída com sucesso"
print_ok() {
    echo -e "${VERDE}${SIM_OK} ${1}${RESET}"
}

# Mensagem de aviso (não interrompe)
# Uso: print_warn "Verifique a configuração"
print_warn() {
    echo -e "${AMARELO}${SIM_AVISO} ${1}${RESET}"
}

# Mensagem de erro (não interrompe; para abortar use: print_err "..." && exit 1)
# Uso: print_err "Arquivo não encontrado"
print_err() {
    echo -e "${VERMELHO}${SIM_ERRO} ${1}${RESET}" >&2
}

# Mensagem informativa
# Uso: print_info "Dica: use sudo para operações de sistema"
print_info() {
    echo -e "${AZUL}${SIM_INFO} ${1}${RESET}"
}

# Pausa aguardando Enter
# Uso: wait_enter
wait_enter() {
    echo -e "\n${AZUL}──────────────────────────────────${RESET}"
    read -r -p "   Pressione Enter para continuar..."
}

# ==============================================================================
# FUNÇÕES DE VERIFICAÇÃO
# ==============================================================================

# Aborta o script se não for executado como root
# Uso: require_root
require_root() {
    if [[ $EUID -ne 0 ]]; then
        print_err "Execute com sudo: sudo $0"
        exit 1
    fi
}

# Aborta o script se não houver conexão com a internet
# Uso: require_internet
require_internet() {
    if ! ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        print_err "Sem conexão com a internet. Verifique a rede e tente novamente."
        exit 1
    fi
}

# Retorna 0 (verdadeiro) se o flatpak estiver disponível no sistema
# Uso: if flatpak_ok; then ...; fi
flatpak_ok() {
    command -v flatpak &>/dev/null
}

# ==============================================================================
# FUNÇÕES DE INSTALAÇÃO
# ==============================================================================

# Instala um ou mais pacotes APT com DEBIAN_FRONTEND=noninteractive
# Uso: apt_install curl wget git
apt_install() {
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

# ==============================================================================
# FUNÇÕES DE LIMPEZA
# ==============================================================================

# Remove pacotes órfãos e limpa cache APT
# Uso: cleanup_apt
cleanup_apt() {
    print_info "Limpando pacotes órfãos e cache APT..."
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
    sudo apt-get clean
    print_ok "Cache APT limpo."
}

# Remove runtimes Flatpak não utilizados (apenas se flatpak estiver instalado)
# Uso: cleanup_flatpak
cleanup_flatpak() {
    if flatpak_ok; then
        print_info "Removendo runtimes Flatpak não utilizados..."
        flatpak uninstall --unused -y
        print_ok "Flatpak limpo."
    fi
}

# Remove logs antigos do journald
# Uso: cleanup_logs       → padrão de 7 dias
# Uso: cleanup_logs 14    → mantém 14 dias
cleanup_logs() {
    local dias="${1:-7}"
    if command -v journalctl &>/dev/null; then
        print_info "Removendo logs com mais de ${dias} dias..."
        sudo journalctl --vacuum-time="${dias}d"
        print_ok "Logs antigos removidos."
    fi
}

# Remove cache de thumbnails do usuário
# Uso: cleanup_thumbnails
cleanup_thumbnails() {
    print_info "Limpando cache de thumbnails..."
    rm -rf ~/.cache/thumbnails/*
    print_ok "Thumbnails limpos."
}

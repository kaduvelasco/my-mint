#!/bin/bash

# ===================================================================================
# apps-manager.sh — Gestão de Aplicativos e Limpeza | Manager Linux
# ===================================================================================
# Autor      : Kadu Velasco
# Projeto    : Manager Linux — Painel de Controle para Linux Mint 22.x
# Versão     : 2.0.0
# Atualizado : 2025
# Licença    : MIT
# -----------------------------------------------------------------------------------
# DESCRIÇÃO:
#   Gerencia aplicativos instalados, sincroniza temas e realiza limpeza profunda.
#   Opções disponíveis:
#     1) Remover bloatware nativo (LibreOffice, Hexchat, Thunderbird, etc.)
#     2) Desinstalar Flatpaks (lista interativa numerada)
#     3) Sincronizar temas e ícones GTK3/GTK4 com Flatpak
#     4) Limpeza profunda (APT, Flatpak, caches, logs, thumbnails)
#
# USO:
#   bash apps-manager.sh   (opções 2-4 não requerem root)
#   sudo bash apps-manager.sh  (opção 1 requer root)
#
# DEPENDÊNCIAS:
#   bash 5+, utils.sh (../../utils.sh ou diretório pai), flatpak, gsettings
# ===================================================================================

set -euo pipefail

# Carrega a biblioteca compartilhada
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# -----------------------------------------------------------------------------------
# FUNÇÕES
# -----------------------------------------------------------------------------------

show_header() {
    clear
    echo -e "${COR_AZUL}======================================================${COR_RESET}"
    echo -e "${COR_AZUL}         APP MANAGER — GESTÃO E LIMPEZA              ${COR_RESET}"
    echo -e "${COR_AZUL}======================================================${COR_RESET}"
}

# Opção 1: Remove programas nativos desnecessários (bloatware do Mint)
remove_native_bloat() {
    print_header "🗑️  Removendo bloatware nativo..."

    require_root

    # Lista de pacotes a remover — ajuste conforme sua preferência
    # VLC foi mantido via Flatpak (instalado pelo pos-install.sh)
    sudo apt-get purge -y \
        libreoffice* \
        hexchat* \
        thunderbird* \
        celluloid* \
        hypnotix* \
        sticky* \
        2>/dev/null || print_warn "Alguns pacotes não estavam instalados."

    sudo apt-get autoremove -y
    print_ok "Remoção concluída!"
}

# Opção 2: Desinstala Flatpaks de forma interativa
remove_flatpaks() {
    if ! flatpak_ok; then
        print_err "Flatpak não está instalado no sistema."
        return 1
    fi

    show_header
    print_header "📦 Flatpaks instalados:"

    mapfile -t FP_NAMES < <(flatpak list --app --columns=name)
    mapfile -t FP_IDS   < <(flatpak list --app --columns=application)

    if [[ ${#FP_IDS[@]} -eq 0 ]]; then
        print_warn "Nenhum Flatpak encontrado."
        sleep 2
        return
    fi

    for i in "${!FP_NAMES[@]}"; do
        echo -e "  [$((i+1))] ${FP_NAMES[$i]} ${COR_CIANO}(${FP_IDS[$i]})${COR_RESET}"
    done

    echo -e "\n  [0] Voltar"
    echo -e "${COR_AZUL}------------------------------------------------------${COR_RESET}"
    read -rp "Número para desinstalar: " FP_CHOICE

    if [[ "${FP_CHOICE}" == "0" ]]; then
        return
    fi

    if [[ "${FP_CHOICE}" =~ ^[0-9]+$ ]] \
        && (( FP_CHOICE >= 1 )) \
        && (( FP_CHOICE <= ${#FP_IDS[@]} )); then

        local SELECTED_ID="${FP_IDS[$((FP_CHOICE-1))]}"
        local SELECTED_NAME="${FP_NAMES[$((FP_CHOICE-1))]}"

        print_warn "Removendo: ${SELECTED_NAME} (${SELECTED_ID})..."
        flatpak uninstall -y "${SELECTED_ID}"
        cleanup_flatpak
        print_ok "${SELECTED_NAME} desinstalado com sucesso!"
    else
        print_err "Opção inválida."
    fi

    sleep 2
}

# Opção 3: Sincroniza temas e ícones GTK3/GTK4 com aplicativos Flatpak
# CORREÇÃO: busca o tema GTK do Cinnamon antes (correto), e não do Xed (incorreto)
sync_flatpak_themes() {
    print_header "🎨 Sincronizando temas e ícones com Flatpak..."

    if ! flatpak_ok; then
        print_err "Flatpak não está instalado."
        return 1
    fi

    # Permissões de acesso às pastas de temas e ícones
    sudo flatpak override --filesystem="${HOME}/.themes:ro"
    sudo flatpak override --filesystem=/usr/share/themes:ro
    sudo flatpak override --filesystem="${HOME}/.icons:ro"
    sudo flatpak override --filesystem=/usr/share/icons:ro

    # Detecta o tema GTK ativo — ordem de prioridade correta:
    # 1. Tema do ambiente Cinnamon (fonte primária e correta)
    # 2. Tema do GNOME/interface genérica (fallback)
    local current_theme=""

    if current_theme=$(gsettings get org.cinnamon.desktop.interface gtk-theme 2>/dev/null | tr -d "'"); then
        : # sucesso
    elif current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'"); then
        : # fallback GNOME
    fi

    if [[ -z "${current_theme}" ]]; then
        print_warn "Não foi possível detectar o tema GTK. Sincronização de tema ignorada."
    else
        sudo flatpak override --env="GTK_THEME=${current_theme}"
        sudo flatpak override --env="ICON_THEME=${current_theme}"
        print_ok "Temas sincronizados! Tema detectado: ${current_theme}"
        print_info "Apps GTK4 seguirão melhor a estética do sistema."
    fi
}

# Opção 4: Limpeza profunda do sistema
system_cleanup() {
    print_header "🛠️  Iniciando limpeza profunda do sistema..."

    # Corrige eventuais dependências quebradas
    sudo apt-get install -f -y

    # Limpeza APT
    cleanup_apt

    # Limpeza Flatpak
    cleanup_flatpak

    # Logs antigos (mantém apenas os últimos 7 dias)
    cleanup_logs 7

    # Thumbnails
    cleanup_thumbnails

    print_ok "Limpeza profunda concluída!"
}

# -----------------------------------------------------------------------------------
# MENU PRINCIPAL
# -----------------------------------------------------------------------------------

while true; do
    show_header
    echo -e "  1) Remover bloatware nativo (Office, Thunderbird, Hexchat...)"
    echo -e "  2) Desinstalar Flatpaks (lista interativa)"
    echo -e "  3) Sincronizar temas e ícones (GTK3 / GTK4 / Libadwaita)"
    echo -e "  4) Limpeza profunda (APT, Flatpak, caches, logs)"
    echo -e "  0) Sair"
    echo -e "${COR_AZUL}------------------------------------------------------${COR_RESET}"
    read -rp "Escolha uma opção: " OPTION

    case "${OPTION}" in
        1) remove_native_bloat ;;
        2) remove_flatpaks ;;
        3) sync_flatpak_themes ;;
        4) system_cleanup ;;
        0) exit 0 ;;
        *) print_warn "Opção inválida! Escolha entre 0 e 4."; sleep 1 ;;
    esac

    wait_enter
done

#!/usr/bin/env bash

# ==============================================================================
# apps-manager.sh — Gestão de Aplicativos e Limpeza | Manager Linux
# ==============================================================================
# Descrição   : Gerencia aplicativos instalados, sincroniza temas e realiza
#               limpeza profunda. Opções:
#                 1. Remover bloatware nativo (LibreOffice, Hexchat, Thunderbird…)
#                 2. Desinstalar Flatpaks (lista interativa numerada)
#                 3. Sincronizar temas e ícones GTK3/GTK4 com Flatpak
#                 4. Limpeza profunda (APT, Flatpak, caches, logs, thumbnails)
# Uso         : bash apps-manager.sh
# Versão      : 2.0.0
# ==============================================================================

set -euo pipefail

# Carrega a biblioteca compartilhada
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# ==============================================================================
# FUNÇÕES
# ==============================================================================

show_menu() {
    clear
    echo -e "\n${AZUL}====================================${RESET}"
    echo -e "${AZUL}   APP MANAGER — GESTÃO E LIMPEZA${RESET}"
    echo -e "${AZUL}====================================${RESET}"
    echo -e "   ${VERDE}1.${RESET} Remover bloatware nativo (Office, Thunderbird, Hexchat…)"
    echo -e "   ${VERDE}2.${RESET} Desinstalar Flatpaks (lista interativa)"
    echo -e "   ${VERDE}3.${RESET} Sincronizar temas e ícones (GTK3 / GTK4 / Libadwaita)"
    echo -e "   ${AMARELO}4.${RESET} Limpeza profunda (APT, Flatpak, caches, logs)"
    echo -e "   ${VERMELHO}0.${RESET} Sair"
    echo -e "${AZUL}====================================${RESET}"
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

    show_menu
    print_header "📦 Flatpaks instalados:"

    mapfile -t FP_NAMES < <(flatpak list --app --columns=name)
    mapfile -t FP_IDS   < <(flatpak list --app --columns=application)

    if [[ ${#FP_IDS[@]} -eq 0 ]]; then
        print_warn "Nenhum Flatpak encontrado."
        sleep 2
        return
    fi

    for i in "${!FP_NAMES[@]}"; do
        echo -e "   ${VERDE}$((i+1)).${RESET} ${FP_NAMES[$i]} ${AZUL}(${FP_IDS[$i]})${RESET}"
    done

    echo -e "\n   ${VERMELHO}0.${RESET} Voltar"
    echo -e "${AZUL}──────────────────────────────────${RESET}"
    read -r -p "Número para desinstalar: " FP_CHOICE

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
        echo -e "${VERMELHO}❌ Opção inválida. Digite um número de 0 a ${#FP_IDS[@]}.${RESET}"
    fi

    sleep 2
}

# Opção 3: Sincroniza temas e ícones GTK3/GTK4 com aplicativos Flatpak
# Busca o tema GTK do Cinnamon (correto) antes do GNOME (fallback)
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

    # Detecta o tema GTK ativo — ordem de prioridade:
    # 1. Cinnamon (fonte primária e correta)
    # 2. GNOME/interface genérica (fallback)
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
        print_ok "Temas sincronizados! Tema detectado: ${AMARELO}${current_theme}${RESET}"
        print_info "Apps GTK4 seguirão melhor a estética do sistema."
    fi
}

# Opção 4: Limpeza profunda do sistema
system_cleanup() {
    print_header "🧹 Iniciando limpeza profunda do sistema..."

    # Corrige eventuais dependências quebradas
    sudo apt-get install -f -y

    cleanup_apt
    cleanup_flatpak
    cleanup_logs 7
    cleanup_thumbnails

    print_ok "Limpeza profunda concluída!"
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================

while true; do
    show_menu
    read -r -p "Escolha uma opção: " OPTION

    case "${OPTION}" in
        1) remove_native_bloat ;;
        2) remove_flatpaks ;;
        3) sync_flatpak_themes ;;
        4) system_cleanup ;;
        0)
            echo -e "\n${VERDE}Até logo!${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "${VERMELHO}❌ Opção inválida. Digite um número de 0 a 4.${RESET}"
            sleep 1
            ;;
    esac

    wait_enter
done

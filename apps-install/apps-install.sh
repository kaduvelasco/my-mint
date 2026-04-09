#!/usr/bin/env bash

# ==============================================================================
# apps-install.sh — Loja Customizada de Aplicativos | Manager Linux
# ==============================================================================
# Descrição   : Loja interativa de aplicativos Flatpak.
#               Funcionalidades:
#                 - Lista apps disponíveis com indicação de instalados (✅)
#                 - Seleção individual por número ou instalação de todos ('all')
#                 - Instalação em lote (mais eficiente que um por vez)
#
#   APPS DISPONÍVEIS (Flatpak via Flathub):
#     Navegadores  : Firefox, Chromium, Zen Browser
#     Dev / Rede   : FileZilla, Meld
#     Design       : Inkscape, Krita, Eyedropper, Lunacy, Penpot, MyPaint, Vara
#     Produtividade: LibreOffice, ONLYOFFICE, Planify, Web Apps, Gear Lever,
#                    Apostrophe
#     Utilidades   : Parabolic (yt-dlp GUI), AnyDesk
#     Educação     : Tux Paint, GCompris
#
# Uso         : bash apps-install.sh   (não requer root)
# Dependências: bash 5+, utils.sh (diretório pai), flatpak
# Versão      : 2.0.0
# ==============================================================================

set -euo pipefail

# Carrega a biblioteca compartilhada
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# -----------------------------------------------------------------------------------
# CATÁLOGO DE APLICATIVOS
# -----------------------------------------------------------------------------------

# Flatpaks: "Nome amigável" → "ID Flatpak no Flathub"
declare -A FLATPAKS=(
    ["AnyDesk"]="com.anydesk.Anydesk"
    ["Apostrophe"]="org.gnome.gitlab.somas.Apostrophe"
    ["Chromium"]="org.chromium.Chromium"
    ["Eyedropper"]="com.github.finefindus.eyedropper"
    ["FileZilla"]="org.filezillaproject.Filezilla"
    ["Firefox"]="org.mozilla.firefox"
    ["GCompris"]="org.kde.gcompris"
    ["Gear Lever"]="it.mijorus.gearlever"
    ["Inkscape"]="org.inkscape.Inkscape"
    ["Krita"]="org.kde.krita"
    ["LibreOffice"]="org.libreoffice.LibreOffice"
    ["Lunacy"]="com.icons8.Lunacy"
    ["Meld"]="org.gnome.meld"
    ["MyPaint"]="org.mypaint.MyPaint"
    ["ONLYOFFICE"]="org.onlyoffice.desktopeditors"
    ["Parabolic"]="org.nickvision.tubeconverter"
    ["Penpot"]="com.authormore.penpotdesktop"
    ["Planify"]="io.github.alainm23.planify"
    ["Tux Paint"]="org.tuxpaint.Tuxpaint"
    ["Vara"]="in.co.nandakumar.vara"
    ["Web Apps"]="net.codelogistics.webapps"
    ["Zen Browser"]="app.zen_browser.zen"
)

# Scripts externos: "Nome amigável" → "comando a executar"
declare -A SCRIPTS=()

# -----------------------------------------------------------------------------------
# FUNÇÕES AUXILIARES
# -----------------------------------------------------------------------------------

# Bootstrap: garante que flatpak e flathub estejam disponíveis
bootstrap_flatpak() {
    print_header "🔍 Verificando ambiente Flatpak..."

    if ! flatpak_ok; then
        print_warn "Flatpak não encontrado. Instalando..."
        sudo apt-get update -y
        apt_install flatpak
    fi

    if ! flatpak remotes | grep -q flathub; then
        print_info "Adicionando repositório Flathub..."
        flatpak remote-add --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo
        print_ok "Flathub adicionado."
    else
        print_ok "Ambiente Flatpak pronto."
    fi
}

# Verifica se um Flatpak está instalado pelo ID
# Uso: is_flatpak_installed "org.mozilla.firefox" && echo "instalado"
is_flatpak_installed() {
    flatpak list --app --columns=application | grep -qx "$1"
}

# -----------------------------------------------------------------------------------
# EXECUÇÃO
# -----------------------------------------------------------------------------------

bootstrap_flatpak

print_header "📋 Selecione os aplicativos para instalar"

# Gera lista ordenada alfabeticamente combinando Flatpaks e Scripts
mapfile -t sorted_names < <(printf '%s\n' "${!FLATPAKS[@]}" "${!SCRIPTS[@]}" | sort)

# Exibe o menu com indicação de instalados
MENU=()
for i in "${!sorted_names[@]}"; do
    local_name="${sorted_names[$i]}"
    index=$((i+1))

    if [[ -n "${FLATPAKS[${local_name}]:-}" ]]; then
        local_id="${FLATPAKS[${local_name}]}"
        if is_flatpak_installed "${local_id}"; then
            echo -e "  [${index}] ${VERDE}${SIM_OK} ${local_name} (instalado)${RESET}"
        else
            echo -e "  [${index}] ${local_name}"
        fi
    else
        echo -e "  [${index}] ${local_name} ${AZUL}(script externo)${RESET}"
    fi
    MENU+=("${local_name}")
done

echo ""
echo -e "  [all] Instalar todos os Flatpaks"
echo -e "${AZUL}──────────────────────────────────${RESET}"
read -r -p "Digite os números (ex: 1 3 7) ou 'all': " -a SELECTIONS

# -----------------------------------------------------------------------------------
# PROCESSAMENTO DA SELEÇÃO
# -----------------------------------------------------------------------------------

APPS_TO_INSTALL=()   # IDs de Flatpaks a instalar
SCRIPTS_TO_RUN=()    # Comandos de scripts externos a executar

for choice in "${SELECTIONS[@]}"; do

    # Opção 'all': coleta todos os IDs do catálogo
    if [[ "${choice}" == "all" ]]; then
        # Itera sobre as chaves do array para coletar apenas os IDs (valores)
        for name in "${!FLATPAKS[@]}"; do
            APPS_TO_INSTALL+=("${FLATPAKS[${name}]}")
        done
        SCRIPTS_TO_RUN=()   # Scripts externos não são instalados com 'all' por segurança
        print_info "Modo 'all': ${#APPS_TO_INSTALL[@]} Flatpaks selecionados."
        break
    fi

    # Valida se é um número dentro do intervalo do menu
    if ! [[ "${choice}" =~ ^[0-9]+$ ]] \
        || (( choice < 1 )) \
        || (( choice > ${#MENU[@]} )); then
        print_warn "Opção inválida ignorada: '${choice}'"
        continue
    fi

    local_name="${MENU[$((choice-1))]}"

    if [[ -n "${FLATPAKS[${local_name}]:-}" ]]; then
        APPS_TO_INSTALL+=("${FLATPAKS[${local_name}]}")
    elif [[ -n "${SCRIPTS[${local_name}]:-}" ]]; then
        SCRIPTS_TO_RUN+=("${SCRIPTS[${local_name}]}")
    fi
done

# -----------------------------------------------------------------------------------
# INSTALAÇÃO
# -----------------------------------------------------------------------------------

# Instala todos os Flatpaks em lote (muito mais eficiente que um por vez)
if [[ ${#APPS_TO_INSTALL[@]} -gt 0 ]]; then
    print_header "📦 Instalando ${#APPS_TO_INSTALL[@]} Flatpak(s) em lote..."
    flatpak install -y flathub "${APPS_TO_INSTALL[@]}"
    print_ok "Instalação Flatpak concluída!"
else
    print_info "Nenhum Flatpak selecionado para instalação."
fi

# Executa scripts externos com confirmação obrigatória
for cmd in "${SCRIPTS_TO_RUN[@]}"; do
    print_header "⚡ Script Externo"
    print_warn "Comando: ${cmd}"
    read -rp "Confirmar execução? (s/N): " confirm
    if [[ "${confirm,,}" == "s" ]]; then
        eval "${cmd}"
        print_ok "Script executado com sucesso!"
    else
        print_info "Execução cancelada pelo usuário."
    fi
done

print_header "${SIM_OK} Processo concluído!"

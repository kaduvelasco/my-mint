#!/bin/bash

# ===================================================================================
# mint-pro.sh — Otimizador de Performance e Gaming | Manager Linux
# ===================================================================================
# Autor      : Kadu Velasco
# Projeto    : Manager Linux — Painel de Controle para Linux Mint 22.x
# Versão     : 2.0.0
# Atualizado : 2025
# Licença    : MIT
# -----------------------------------------------------------------------------------
# DESCRIÇÃO:
#   Painel de otimização avançada para Linux Mint 22.x com foco em performance
#   geral e gaming (AMD/Vulkan). Opções disponíveis:
#     1) Atualizar sistema (apt update + full-upgrade)
#     2) Otimizar performance (Swappiness=10, ZRAM, inotify)
#     3) Substituir Neofetch por Fastfetch
#     4) Forçar driver AMDGPU com suporte Vulkan/DXVK
#     5) Instalar ferramentas gaming (GameMode, MangoHud, Goverlay, Piper)
#     6) Instalar Steam via Flatpak
#     7) Instalar Heroic Games Launcher via Flatpak
#     8) Instalar/Atualizar Proton GE (via ProtonUp-NG)
#     9) Instalar Minecraft Bedrock Launcher via Flatpak
#
# USO:
#   sudo bash mint-pro.sh
#
# DEPENDÊNCIAS:
#   bash 5+, utils.sh (../../utils.sh ou diretório pai), acesso root
# ===================================================================================

set -euo pipefail

# Carrega a biblioteca compartilhada
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# Verificação de root obrigatória para este script
require_root

# -----------------------------------------------------------------------------------
# FUNÇÕES DE OTIMIZAÇÃO
# -----------------------------------------------------------------------------------

# Cabecalho do menu
show_header() {
    clear
    echo -e "${COR_AZUL}======================================================${COR_RESET}"
    echo -e "${COR_VERDE}         MINT PRO — OTIMIZAÇÃO E GAMING              ${COR_RESET}"
    echo -e "${COR_AZUL}======================================================${COR_RESET}"
}

# Opção 1: Atualiza o sistema via APT
opt_update() {
    print_header "🔄 Atualizando repositórios e pacotes..."
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
    print_ok "Sistema atualizado!"
}

# Opção 2: Otimiza parâmetros de performance
opt_performance() {
    print_header "⚙️  Ajustando Swappiness, ZRAM e Inotify..."

    apt_install zram-config

    # Swappiness: reduz uso de swap em favor da RAM (padrão=60, gaming ideal=10)
    if ! grep -q "vm.swappiness=10" /etc/sysctl.conf; then
        echo 'vm.swappiness=10' >> /etc/sysctl.conf
        print_ok "Swappiness definido para 10."
    else
        print_info "Swappiness já configurado."
    fi

    # Inotify: aumenta limite de watches (VS Code, JetBrains, Next.js, etc.)
    if ! grep -q "fs.inotify.max_user_watches" /etc/sysctl.conf; then
        echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
        print_ok "Limite de inotify aumentado para 524288."
    else
        print_info "Inotify já configurado."
    fi

    sysctl -p
    print_ok "Performance otimizada! ZRAM ativo após reinicialização."
}

# Opção 3: Substitui Neofetch pelo Fastfetch (mais rápido e mantido)
opt_fastfetch() {
    print_header "🚀 Trocando Neofetch por Fastfetch..."

    apt-get purge -y neofetch 2>/dev/null || print_info "Neofetch não estava instalado."
    apt_install fastfetch

    # Adiciona alias para o usuário que chamou o sudo (não para o root)
    local user_home
    user_home=$(eval echo "~${SUDO_USER:-$USER}")
    local bashrc="${user_home}/.bashrc"

    if [[ -f "${bashrc}" ]] && ! grep -q "alias neofetch='fastfetch'" "${bashrc}"; then
        echo "alias neofetch='fastfetch'" >> "${bashrc}"
        print_ok "Alias 'neofetch → fastfetch' adicionado em ${bashrc}."
    else
        print_info "Alias já existente ou .bashrc não encontrado."
    fi

    print_ok "Fastfetch configurado! Execute: fastfetch"
}

# Opção 4: Força driver AMDGPU com suporte Vulkan (GCN 1.0+ / SI e CIK)
opt_amdgpu() {
    print_header "🛠️  Configurando driver AMDGPU + Vulkan..."

    dpkg --add-architecture i386
    apt-get update -y
    apt_install \
        mesa-vulkan-drivers \
        mesa-vulkan-drivers:i386 \
        libvulkan1 \
        libvulkan1:i386 \
        firmware-amd-graphics

    # Força amdgpu mesmo em GPUs antigas (Southern Islands / Sea Islands)
    cat > /etc/modprobe.d/amdgpu.conf << 'EOF'
# Força o driver amdgpu (suporte Vulkan) em GPUs SI e CIK
# Desativa o driver radeon legado para essas arquiteturas
options amdgpu si_support=1 cik_support=1
options radeon si_support=0 cik_support=0
EOF

    update-initramfs -u
    print_ok "Driver AMDGPU configurado. REINICIE para ativar o Vulkan."
    print_info "Teste após reiniciar: vulkaninfo | grep deviceName"
}

# Opção 5: Instala ferramentas de gaming (GameMode, MangoHud, Goverlay, Piper)
opt_gm_tools() {
    print_header "🎮 Instalando ferramentas gaming..."
    apt_install gamemode mangohud goverlay piper
    print_ok "GameMode, MangoHud, Goverlay e Piper instalados!"
    print_info "Use 'gamemoderun %command%' no Steam para ativar o GameMode."
}

# Opção 6: Instala Steam via Flatpak
opt_steam() {
    print_header "🎮 Instalando Steam via Flatpak..."
    flatpak install -y flathub com.valvesoftware.Steam com.github.tchx84.Flatseal
    print_ok "Steam e Flatseal instalados!"
}

# Opção 7: Instala Heroic Games Launcher via Flatpak
opt_heroic() {
    print_header "🎮 Instalando Heroic Games Launcher via Flatpak..."
    flatpak install -y flathub com.heroicgameslauncher.hgl
    print_ok "Heroic Games Launcher instalado!"
}

# Opção 8: Instala/Atualiza Proton GE via ProtonUp-NG
# CORREÇÃO: usa o home do usuário que chamou o sudo, não o home do root
opt_proton() {
    print_header "📦 Instalando ProtonUp-NG e Proton GE..."

    # Garante que o usuário real (não root) seja identificado corretamente
    local real_user="${SUDO_USER:-$USER}"
    local real_home
    real_home=$(getent passwd "${real_user}" | cut -d: -f6)

    apt_install pipx
    sudo -u "${real_user}" pipx install protonup-ng --force

    # Caminho correto da Steam Flatpak no diretório do usuário real
    local steam_compat="${real_home}/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/"
    mkdir -p "${steam_compat}"

    sudo -u "${real_user}" \
        "${real_home}/.local/bin/protonup" \
        -d "${steam_compat}"

    print_ok "Proton GE instalado em: ${steam_compat}"
    print_info "Reinicie o Steam para que o Proton GE apareça nas opções."
}

# Opção 9: Instala Minecraft Bedrock Launcher via Flatpak
opt_minecraft() {
    print_header "🟩 Instalando Minecraft Bedrock Launcher via Flatpak..."
    flatpak install -y flathub io.mrarm.mcpelauncher
    print_ok "Minecraft Bedrock Launcher instalado!"
}

# -----------------------------------------------------------------------------------
# MENU PRINCIPAL
# -----------------------------------------------------------------------------------

while true; do
    show_header
    echo -e "  1) Atualizar sistema"
    echo -e "  2) Otimizar performance (Swappiness + ZRAM + Inotify)"
    echo -e "  3) Substituir Neofetch por Fastfetch"
    echo -e "  4) Forçar driver AMDGPU (Vulkan / DXVK)"
    echo -e "  5) [GM] Instalar ferramentas (GameMode, MangoHud, Goverlay)"
    echo -e "  6) [GM] Instalar Steam (Flatpak)"
    echo -e "  7) [GM] Instalar Heroic Games Launcher (Flatpak)"
    echo -e "  8) [GM] Instalar/Atualizar Proton GE (via ProtonUp)"
    echo -e "  9) Instalar Minecraft Bedrock Launcher"
    echo -e "  0) Sair"
    echo -e "${COR_AZUL}------------------------------------------------------${COR_RESET}"
    read -rp "Escolha uma opção: " OPTION

    case "${OPTION}" in
        1) opt_update ;;
        2) opt_performance ;;
        3) opt_fastfetch ;;
        4) opt_amdgpu ;;
        5) opt_gm_tools ;;
        6) opt_steam ;;
        7) opt_heroic ;;
        8) opt_proton ;;
        9) opt_minecraft ;;
        0) echo -e "\n${COR_VERDE}Saindo...${COR_RESET}"; exit 0 ;;
        *) print_warn "Opção inválida! Escolha entre 0 e 9."; sleep 1 ;;
    esac

    wait_enter
done

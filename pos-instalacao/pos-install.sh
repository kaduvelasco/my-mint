#!/bin/bash

# ===================================================================================
# pos-install.sh — Pós-Instalação | Manager Linux
# ===================================================================================
# Autor      : Kadu Velasco
# Projeto    : Manager Linux — Painel de Controle para Linux Mint 22.x
# Versão     : 2.0.0
# Atualizado : 2025
# Licença    : MIT
# -----------------------------------------------------------------------------------
# DESCRIÇÃO:
#   Configura o sistema recém-instalado aplicando as seguintes etapas em ordem:
#     1. Adiciona PPA do Fastfetch (versão mais recente)
#     2. Atualiza todos os pacotes do sistema
#     3. Instala pacotes essenciais via APT (codecs, drivers, ferramentas CLI/Dev)
#     4. Configura drivers proprietários automaticamente (ubuntu-drivers)
#     5. Adiciona o repositório Flathub e instala VLC via Flatpak
#     6. Executa limpeza final (autoremove, autoclean, updatedb)
#     7. Aplica tweak de inotify (útil para VS Code e ambientes de desenvolvimento)
#
# USO:
#   sudo bash pos-install.sh
#
# LOG:
#   Gerado automaticamente em: ~/pos-install-YYYYMMDD_HHMM.log
#
# DEPENDÊNCIAS:
#   bash 5+, utils.sh (../../utils.sh ou diretório pai)
#   Acesso root (sudo), conexão com a internet
# ===================================================================================

set -euo pipefail

# Carrega a biblioteca compartilhada (sobe dois níveis: pos-instalacao/ → raiz)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# Verificações iniciais obrigatórias
require_root
require_internet

# Log da sessão atual
LOG_FILE="${HOME}/pos-install-$(date +%Y%m%d_%H%M).log"
exec > >(tee -i "${LOG_FILE}") 2>&1

# -----------------------------------------------------------------------------------
# PACOTES A INSTALAR
# -----------------------------------------------------------------------------------

# Pacotes APT essenciais para pós-instalação
APT_PACKAGES=(
    # Codecs e multimídia
    mint-meta-codecs
    ubuntu-drivers-common
    libavcodec-extra
    ffmpeg

    # Sistema e gerenciamento de arquivos
    build-essential
    gparted
    gdebi
    libfuse2t64
    unrar
    unzip
    ntfs-3g
    p7zip-full

    # Ferramentas de linha de comando e desenvolvimento
    curl
    wget
    git
    htop
    make
    tree
    jq
    plocate
    net-tools
    python3-pip
)

# Pacotes Flatpak — VLC via Flatpak (remove duplicidade com APT nativo)
FLATPAK_PACKAGES=(
    org.videolan.VLC
    net.codelogistics.webapps
)

# -----------------------------------------------------------------------------------
# EXECUÇÃO
# -----------------------------------------------------------------------------------

print_header "${SIM_SETA} Iniciando Pós-Instalação — Log: ${LOG_FILE}"

# Etapa 1: Repositórios
print_header "🌐 Configurando repositórios..."
sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock
# PPA do Fastfetch (bleeding-edge); no Mint 22.x está disponível nos repos oficiais
# mas o PPA garante versão mais recente
add-apt-repository ppa:zhangsongcui3371/fastfetch -y

# Etapa 2: Atualização do sistema
print_header "🔄 Atualizando sistema..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y

# Etapa 3: Pacotes APT
print_header "📦 Instalando pacotes essenciais via APT..."
apt_install "${APT_PACKAGES[@]}" fastfetch

# Etapa 4: Drivers
print_header "🔧 Configurando drivers..."
ubuntu-drivers autoinstall || print_warn "Nenhum driver adicional detectado ou necessário."

# Etapa 5: Flatpak
print_header "📦 Configurando Flatpak e instalando aplicativos..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y --noninteractive flathub "${FLATPAK_PACKAGES[@]}"
print_ok "VLC e WebApps instalados via Flatpak."

# Etapa 6: Limpeza
print_header "🧹 Limpeza e otimização final..."
cleanup_apt
updatedb

# Etapa 7: Tweak de inotify (aumenta limite de watches — útil para VS Code e IDEs)
if ! grep -q "fs.inotify.max_user_watches" /etc/sysctl.conf; then
    echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    print_ok "Limite de inotify aumentado para 524288."
else
    print_info "Limite de inotify já configurado. Nenhuma alteração necessária."
fi

# -----------------------------------------------------------------------------------
# CONCLUSÃO
# -----------------------------------------------------------------------------------

print_header "${SIM_OK} Pós-instalação concluída com sucesso!"
print_info "Log salvo em: ${LOG_FILE}"
print_warn "Recomendado reiniciar o sistema para aplicar todos os drivers."

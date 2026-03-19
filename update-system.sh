#!/bin/bash

# ===================================================================================
# update-system.sh — Manutenção Inteligente do Sistema | Manager Linux
# ===================================================================================
# Autor      : Kadu Velasco
# Projeto    : Manager Linux — Painel de Controle para Linux Mint 22.x
# Versão     : 2.0.0
# Atualizado : 2025
# Licença    : MIT
# -----------------------------------------------------------------------------------
# DESCRIÇÃO:
#   Realiza a manutenção completa do sistema em uma única execução:
#     1. Atualiza repositórios e pacotes APT (update + upgrade + full-upgrade)
#     2. Atualiza aplicativos Flatpak e remove runtimes não utilizados
#     3. Limpa cache APT, logs antigos (>7 dias) e thumbnails
#     4. Atualiza o índice de busca do plocate (updatedb)
#     5. Exibe dica de Vulkan se GPU AMD for detectada
#
#   AUTOSSUFICIENTE: Este script não depende de utils.sh pois é instalado
#   globalmente via symlink em /usr/local/bin/update-system. Todas as funções
#   auxiliares estão embutidas diretamente aqui.
#
# USO:
#   update-system            (após instalação global via manager.sh opção 6)
#   bash update-system.sh    (execução direta)
#   sudo update-system       (necessário para atualização de pacotes do sistema)
#
# LOG:
#   Gerado automaticamente em: ~/manutencao_sistema.log
#
# DEPENDÊNCIAS:
#   apt, bash 5+
#   Opcionais: flatpak, journalctl, updatedb (plocate)
# ===================================================================================

set -euo pipefail

# -----------------------------------------------------------------------------------
# PALETA DE CORES (embutida — não depende de utils.sh)
# -----------------------------------------------------------------------------------
readonly COR_AZUL='\033[0;34m'
readonly COR_VERDE='\033[0;32m'
readonly COR_AMARELO='\033[1;33m'
readonly COR_CIANO='\033[0;36m'
readonly COR_RESET='\033[0m'

readonly SIM_OK="✅"
readonly SIM_AVISO="⚠️ "
readonly SIM_INFO="ℹ️ "
readonly SIM_SETA="🚀"

# -----------------------------------------------------------------------------------
# FUNÇÕES AUXILIARES (embutidas — não depende de utils.sh)
# -----------------------------------------------------------------------------------

print_header() {
    echo -e "\n${COR_AZUL}======================================================${COR_RESET}"
    echo -e " ${COR_VERDE}${1}${COR_RESET}"
    echo -e "${COR_AZUL}======================================================${COR_RESET}\n"
}

print_ok()   { echo -e "${COR_VERDE}${SIM_OK} ${1}${COR_RESET}"; }
print_warn() { echo -e "${COR_AMARELO}${SIM_AVISO}${1}${COR_RESET}"; }
print_info() { echo -e "${COR_CIANO}${SIM_INFO} ${1}${COR_RESET}"; }

# -----------------------------------------------------------------------------------
# INICIALIZAÇÃO
# -----------------------------------------------------------------------------------

LOG_FILE="${HOME}/manutencao_sistema.log"
START_TIME=$(date +%s)

print_header "${SIM_SETA} Manutenção Completa — $(date '+%d/%m/%Y %H:%M:%S')" | tee "${LOG_FILE}"

# -----------------------------------------------------------------------------------
# ETAPA 1 — Atualização APT
# -----------------------------------------------------------------------------------

print_header "🔄 Atualizando repositórios e pacotes APT..."

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y          | tee -a "${LOG_FILE}"
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y         | tee -a "${LOG_FILE}"
sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y    | tee -a "${LOG_FILE}"

print_ok "Pacotes APT atualizados." | tee -a "${LOG_FILE}"

# -----------------------------------------------------------------------------------
# ETAPA 2 — Atualização Flatpak
# -----------------------------------------------------------------------------------

if command -v flatpak &>/dev/null; then
    print_header "📦 Atualizando aplicativos Flatpak..."
    flatpak update -y | tee -a "${LOG_FILE}"

    print_info "Removendo runtimes Flatpak não utilizados..."
    flatpak uninstall --unused -y | tee -a "${LOG_FILE}"

    print_ok "Flatpak atualizado e limpo." | tee -a "${LOG_FILE}"
else
    print_warn "Flatpak não encontrado. Etapa ignorada." | tee -a "${LOG_FILE}"
fi

# -----------------------------------------------------------------------------------
# ETAPA 3 — Limpeza de cache, logs e thumbnails
# -----------------------------------------------------------------------------------

print_header "🧹 Limpeza profunda de cache e logs..."

# Cache APT
sudo apt-get autoremove -y  | tee -a "${LOG_FILE}"
sudo apt-get autoclean -y   | tee -a "${LOG_FILE}"
sudo apt-get clean          | tee -a "${LOG_FILE}"
print_ok "Cache APT limpo." | tee -a "${LOG_FILE}"

# Logs do sistema (mantém apenas os últimos 7 dias)
if command -v journalctl &>/dev/null; then
    print_info "Removendo logs com mais de 7 dias..."
    sudo journalctl --vacuum-time=7d | tee -a "${LOG_FILE}"
    print_ok "Logs antigos removidos." | tee -a "${LOG_FILE}"
fi

# Cache de thumbnails
print_info "Limpando cache de thumbnails..."
rm -rf ~/.cache/thumbnails/*
print_ok "Thumbnails limpos." | tee -a "${LOG_FILE}"

# -----------------------------------------------------------------------------------
# ETAPA 4 — Atualização do índice de busca (plocate)
# -----------------------------------------------------------------------------------

if command -v updatedb &>/dev/null; then
    print_header "🔍 Atualizando índice de busca (plocate)..."
    sudo updatedb | tee -a "${LOG_FILE}"
    print_ok "Índice de busca atualizado." | tee -a "${LOG_FILE}"
fi

# -----------------------------------------------------------------------------------
# ETAPA 5 — Dicas específicas de hardware
# -----------------------------------------------------------------------------------

if lspci 2>/dev/null | grep -qi "amd"; then
    print_info "GPU AMD detectada. Verifique se o Vulkan está ativo com:" \
    | tee -a "${LOG_FILE}"
    echo -e "    ${COR_CIANO}vulkaninfo | grep deviceName${COR_RESET}" \
    | tee -a "${LOG_FILE}"
fi

# -----------------------------------------------------------------------------------
# CONCLUSÃO
# -----------------------------------------------------------------------------------

END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))

print_header "${SIM_OK} Manutenção concluída em ${DURATION} segundo(s)!" | tee -a "${LOG_FILE}"
print_info "Log completo salvo em: ${LOG_FILE}" | tee -a "${LOG_FILE}"

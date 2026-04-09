#!/usr/bin/env bash

# ==============================================================================
# update-system.sh — Manutenção Inteligente do Sistema | Manager Linux
# ==============================================================================
# Descrição   : Realiza a manutenção completa do sistema em uma única execução:
#                 1. Atualiza repositórios e pacotes APT (update + upgrade + full-upgrade)
#                 2. Atualiza aplicativos Flatpak e remove runtimes não utilizados
#                 3. Limpa cache APT, logs antigos (>7 dias) e thumbnails
#                 4. Atualiza o índice de busca do plocate (updatedb)
#                 5. Exibe dica de Vulkan se GPU AMD for detectada
# Uso         : update-system  (após instalação global via manager.sh opção 5)
#               bash update-system.sh  (execução direta)
# Versão      : 2.0.0
# ==============================================================================
# AUTOSSUFICIENTE: não depende de utils.sh (instalado globalmente).
# LOG: gerado automaticamente em ~/manutencao_sistema.log
# ==============================================================================

set -euo pipefail

# ==============================================================================
# PALETA DE CORES (embutida — não depende de utils.sh)
# ==============================================================================

AZUL='\033[0;34m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
RESET='\033[0m'

SIM_OK="✅"
SIM_AVISO="⚠️ "
SIM_INFO="ℹ️ "
SIM_SETA="🚀"

# ==============================================================================
# FUNÇÕES AUXILIARES (embutidas — não depende de utils.sh)
# ==============================================================================

print_header() {
    echo -e "\n${AZUL}====================================${RESET}"
    echo -e " ${VERDE}${1}${RESET}"
    echo -e "${AZUL}====================================${RESET}\n"
}

print_ok()   { echo -e "${VERDE}${SIM_OK} ${1}${RESET}"; }
print_warn() { echo -e "${AMARELO}${SIM_AVISO} ${1}${RESET}"; }
print_info() { echo -e "${AZUL}${SIM_INFO} ${1}${RESET}"; }

# ==============================================================================
# INICIALIZAÇÃO
# ==============================================================================

LOG_FILE="${HOME}/manutencao_sistema.log"
START_TIME=$(date +%s)

print_header "${SIM_SETA} Manutenção Completa — $(date '+%d/%m/%Y %H:%M:%S')" | tee "${LOG_FILE}"

# ==============================================================================
# ETAPA 1 — Atualização APT
# ==============================================================================

print_header "🔄 Atualizando repositórios e pacotes APT..."

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y          | tee -a "${LOG_FILE}"
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y         | tee -a "${LOG_FILE}"
sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y    | tee -a "${LOG_FILE}"

print_ok "Pacotes APT atualizados." | tee -a "${LOG_FILE}"

# ==============================================================================
# ETAPA 2 — Atualização Flatpak
# ==============================================================================

if command -v flatpak &>/dev/null; then
    print_header "📦 Atualizando aplicativos Flatpak..."
    flatpak update -y | tee -a "${LOG_FILE}"

    print_info "Removendo runtimes Flatpak não utilizados..."
    flatpak uninstall --unused -y | tee -a "${LOG_FILE}"

    print_ok "Flatpak atualizado e limpo." | tee -a "${LOG_FILE}"
else
    print_warn "Flatpak não encontrado. Etapa ignorada." | tee -a "${LOG_FILE}"
fi

# ==============================================================================
# ETAPA 3 — Limpeza de cache, logs e thumbnails
# ==============================================================================

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

# ==============================================================================
# ETAPA 4 — Atualização do índice de busca (plocate)
# ==============================================================================

if command -v updatedb &>/dev/null; then
    print_header "🔍 Atualizando índice de busca (plocate)..."
    sudo updatedb | tee -a "${LOG_FILE}"
    print_ok "Índice de busca atualizado." | tee -a "${LOG_FILE}"
fi

# ==============================================================================
# ETAPA 5 — Dicas específicas de hardware
# ==============================================================================

if lspci 2>/dev/null | grep -qi "amd"; then
    print_info "GPU AMD detectada. Verifique se o Vulkan está ativo com:" \
    | tee -a "${LOG_FILE}"
    echo -e "    ${AMARELO}vulkaninfo | grep deviceName${RESET}" \
    | tee -a "${LOG_FILE}"
fi

# ==============================================================================
# CONCLUSÃO
# ==============================================================================

END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))

print_header "${SIM_OK} Manutenção concluída em ${DURATION} segundo(s)!" | tee -a "${LOG_FILE}"
print_info "Log completo salvo em: ${AMARELO}${LOG_FILE}${RESET}" | tee -a "${LOG_FILE}"

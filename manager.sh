#!/usr/bin/env bash

# ==============================================================================
# manager.sh — Central de Gestão do Sistema | Manager Linux
# ==============================================================================
# Descrição   : Script principal do projeto. Exibe o menu central e delega a
#               execução para os demais scripts especializados.
# Uso         : bash manager.sh
# Versão      : 2.0.0
# ==============================================================================
# ESTRUTURA ESPERADA DO PROJETO:
#   manager-linux/
#   ├── manager.sh          ← este arquivo
#   ├── utils.sh            ← biblioteca compartilhada
#   ├── update-system.sh    ← manutenção do sistema (instalável globalmente)
#   ├── pos-instalacao/
#   │   ├── pos-install.sh
#   │   └── modelos.sh
#   └── apps-install/
#       ├── apps-manager.sh
#       └── apps-install.sh
# ==============================================================================

set -euo pipefail

# Carrega a biblioteca compartilhada
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${BASE_DIR}/utils.sh"

# ==============================================================================
# FUNÇÕES INTERNAS
# ==============================================================================

show_menu() {
    clear
    echo -e "\n${AZUL}====================================${RESET}"
    echo -e "${AZUL}   LINUX MINT 22.x — PAINEL DE CONTROLE${RESET}"
    echo -e "${AZUL}====================================${RESET}"
    echo -e "   ${VERDE}1.${RESET} Executar Pós-Instalação (Mint 22.x)"
    echo -e "   ${VERDE}2.${RESET} Instalar Modelos de Arquivos (Office / PHP / Texto)"
    echo -e "   ${VERDE}3.${RESET} Gerenciar Aplicativos (Limpeza / Temas / Flatpaks)"
    echo -e "   ${VERDE}4.${RESET} Instalar Aplicativos (Loja Customizada Flatpak)"
    echo -e "   ${AMARELO}5.${RESET} Instalar Comando 'update-system' Global"
    echo -e "   ${VERMELHO}0.${RESET} Sair"
    echo -e "${AZUL}====================================${RESET}"
}

# Executa um sub-script com verificação de existência
# Uso: run_sub "pos-instalacao/pos-install.sh"
run_sub() {
    local script_path="${BASE_DIR}/$1"
    if [[ -f "${script_path}" ]]; then
        echo -e "\n${AZUL}⚙️  Iniciando: $1...${RESET}"
        bash "${script_path}"
    else
        print_err "Arquivo não encontrado: $1"
        print_info "Caminho esperado: ${script_path}"
        sleep 2
    fi
}

# Instala o update-system como comando global via cópia
# A cópia garante que o comando funcione mesmo se o repositório for apagado
install_update_global() {
    print_header "${SIM_SETA} Tornando 'update-system' um comando global"

    local source_script="${BASE_DIR}/update-system.sh"
    local dest="/usr/local/bin/update-system"

    if [[ ! -f "${source_script}" ]]; then
        print_err "update-system.sh não encontrado em: ${source_script}"
        return 1
    fi

    sudo cp "${source_script}" "${dest}"
    sudo chmod +x "${dest}"

    print_ok "Comando 'update-system' instalado com sucesso!"
    print_info "Instalado em: ${AMARELO}${dest}${RESET}"
    print_info "Agora você pode usar 'update-system' em qualquer terminal."
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================

while true; do
    show_menu
    read -r -p "Escolha uma opção: " OPTION

    case "${OPTION}" in
        1) run_sub "pos-instalacao/pos-install.sh" ;;
        2) run_sub "pos-instalacao/modelos.sh" ;;
        3) run_sub "apps-install/apps-manager.sh" ;;
        4) run_sub "apps-install/apps-install.sh" ;;
        5) install_update_global ;;
        0)
            echo -e "\n${VERDE}Até logo!${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "${VERMELHO}❌ Opção inválida. Digite um número de 0 a 5.${RESET}"
            sleep 1
            ;;
    esac

    wait_enter
done

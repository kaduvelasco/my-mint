#!/bin/bash

# ===================================================================================
# manager.sh — Central de Gestão do Sistema | Manager Linux
# ===================================================================================
# Autor      : Kadu Velasco
# Projeto    : Manager Linux — Painel de Controle para Linux Mint 22.x
# Versão     : 2.0.0
# Atualizado : 2025
# Licença    : MIT
# -----------------------------------------------------------------------------------
# DESCRIÇÃO:
#   Script principal do projeto. Exibe o menu central e delega a execução para
#   os demais scripts especializados. Deve ser chamado a partir da raiz do projeto.
#
# USO:
#   bash manager.sh
#
# ESTRUTURA ESPERADA DO PROJETO:
#   manager-linux/
#   ├── manager.sh          ← este arquivo
#   ├── utils.sh            ← biblioteca compartilhada
#   ├── update-system.sh    ← manutenção do sistema (instalável globalmente)
#   ├── pos-instalacao/
#   │   ├── pos-install.sh
#   │   └── modelos.sh
#   └── apps-install/
#       ├── mint-pro.sh
#       ├── apps-manager.sh
#       └── apps-install.sh
#
# DEPENDÊNCIAS:
#   bash 5+, utils.sh (mesmo diretório)
# ===================================================================================

set -euo pipefail

# Carrega a biblioteca compartilhada
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${BASE_DIR}/utils.sh"

# -----------------------------------------------------------------------------------
# FUNÇÕES INTERNAS
# -----------------------------------------------------------------------------------

show_header() {
    clear
    echo -e "${COR_AZUL}======================================================${COR_RESET}"
    echo -e "${COR_VERDE}         LINUX MINT 22.x — PAINEL DE CONTROLE        ${COR_RESET}"
    echo -e "${COR_AZUL}======================================================${COR_RESET}"
}

# Executa um sub-script com verificação de existência
# Uso: run_sub "pos-instalacao/pos-install.sh"
run_sub() {
    local script_path="${BASE_DIR}/$1"
    if [[ -f "${script_path}" ]]; then
        echo -e "\n${COR_AMARELO}${SIM_SETA} Iniciando: $1...${COR_RESET}"
        bash "${script_path}"
    else
        print_err "Arquivo não encontrado: $1"
        print_info "Caminho esperado: ${script_path}"
        sleep 2
    fi
}

# Instala o update-system como comando global usando symlink
# O symlink garante que atualizações no arquivo original reflitam automaticamente
install_update_global() {
    print_header "${SIM_SETA} Tornando 'update-system' um comando global"

    local source_script="${BASE_DIR}/update-system.sh"
    local dest="/usr/local/bin/update-system"

    if [[ ! -f "${source_script}" ]]; then
        print_err "update-system.sh não encontrado em: ${source_script}"
        return 1
    fi

    # Usa cp para que o comando funcione mesmo se o repositório for apagado
    sudo cp "${source_script}" "${dest}"
    sudo chmod +x "${dest}"

    print_ok "Comando 'update-system' instalado com sucesso!"
    print_info "Instalado em: ${dest}"
    print_info "Agora você pode usar 'update-system' em qualquer terminal."
}

# -----------------------------------------------------------------------------------
# MENU PRINCIPAL
# -----------------------------------------------------------------------------------

while true; do
    show_header
    echo -e "  1) Executar Pós-Instalação (Mint 22.x)"
    echo -e "  2) Instalar Modelos de Arquivos (Office / PHP / Texto)"
    echo -e "  3) Gerenciar Aplicativos (Limpeza / Temas / Flatpaks)"
    echo -e "  4) Instalar Aplicativos (Loja Customizada Flatpak)"
    echo -e "  5) Instalar Comando 'update-system' Global"
    echo -e "  0) Sair"
    echo -e "${COR_AZUL}------------------------------------------------------${COR_RESET}"
    read -rp "Escolha uma opção: " OPTION

    case "${OPTION}" in
        1) run_sub "pos-instalacao/pos-install.sh" ;;
        2) run_sub "pos-instalacao/modelos.sh" ;;
        3) run_sub "apps-install/apps-manager.sh" ;;
        4) run_sub "apps-install/apps-install.sh" ;;
        5) install_update_global ;;
        0) echo -e "\n${COR_VERDE}Até logo!${COR_RESET}"; exit 0 ;;
        *) print_warn "Opção inválida! Escolha entre 0 e 5."; sleep 1 ;;
    esac

    wait_enter
done

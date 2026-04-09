#!/usr/bin/env bash

# ===================================================================================
# modelos.sh — Instalador de Modelos de Arquivos | Manager Linux
# ===================================================================================
# Autor      : Kadu Velasco
# Projeto    : Manager Linux — Painel de Controle para Linux Mint 22.x
# Versão     : 2.0.0
# Atualizado : 2025
# Licença    : MIT
# -----------------------------------------------------------------------------------
# DESCRIÇÃO:
#   Cria modelos de arquivo na pasta ~/Modelos para uso no gerenciador de arquivos
#   Nemo (clique direito → "Novo documento"). Inclui:
#     - Documento Word (.docx) — estrutura ZIP mínima válida
#     - Planilha Excel (.xlsx) — estrutura ZIP mínima válida
#     - Apresentação PowerPoint (.pptx) — estrutura ZIP mínima válida
#     - Arquivo de Texto (.txt)
#     - Script PHP (.php)
#     - Script Shell (.sh)
#     - Arquivo HTML (.html)
#
#   Os arquivos Office são criados com estrutura ZIP válida (não apenas touch),
#   garantindo compatibilidade com LibreOffice, OnlyOffice e similares.
#
# USO:
#   bash modelos.sh   (não requer root)
#
# DEPENDÊNCIAS:
#   bash 5+, utils.sh (../../utils.sh ou diretório pai), python3 (para criar Office)
# ===================================================================================

set -euo pipefail

# Carrega a biblioteca compartilhada
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"

# -----------------------------------------------------------------------------------
# CONFIGURAÇÃO
# -----------------------------------------------------------------------------------

readonly MODELOS_DIR="${HOME}/Modelos"

# -----------------------------------------------------------------------------------
# FUNÇÕES
# -----------------------------------------------------------------------------------

# Cria um arquivo .docx com estrutura ZIP mínima válida
# Uso: criar_docx_minimo "Documento_Word.docx"
criar_docx_minimo() {
    local destino="$1"
    python3 - "${destino}" <<'PYEOF' 2>/dev/null || touch "${destino}"
import zipfile, sys
dest = sys.argv[1]
content_types = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>'''
rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>'''
document = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body><w:p/></w:body>
</w:document>'''
with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', content_types)
    z.writestr('_rels/.rels', rels)
    z.writestr('word/document.xml', document)
PYEOF
}

criar_xlsx_minimo() {
    local destino="$1"
    python3 - "${destino}" <<'PYEOF' 2>/dev/null || touch "${destino}"
import zipfile, sys
dest = sys.argv[1]
content_types = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>'''
rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>'''
workbook = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
          xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets><sheet name="Plan1" sheetId="1" r:id="rId1"/></sheets>
</workbook>'''
wb_rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>'''
sheet = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData/>
</worksheet>'''
with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', content_types)
    z.writestr('_rels/.rels', rels)
    z.writestr('xl/workbook.xml', workbook)
    z.writestr('xl/_rels/workbook.xml.rels', wb_rels)
    z.writestr('xl/worksheets/sheet1.xml', sheet)
PYEOF
}

criar_pptx_minimo() {
    local destino="$1"
    python3 - "${destino}" <<'PYEOF' 2>/dev/null || touch "${destino}"
import zipfile, sys
dest = sys.argv[1]
content_types = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
</Types>'''
rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>'''
presentation = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
                xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <p:sldMasterIdLst/><p:sldSz cx="9144000" cy="6858000"/><p:notesSz cx="6858000" cy="9144000"/>
</p:presentation>'''
with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', content_types)
    z.writestr('_rels/.rels', rels)
    z.writestr('ppt/presentation.xml', presentation)
PYEOF
}

# -----------------------------------------------------------------------------------
# EXECUÇÃO
# -----------------------------------------------------------------------------------

print_header "${SIM_SETA} Criando modelos de arquivo em: ${MODELOS_DIR}"

# Cria a pasta se não existir
mkdir -p "${MODELOS_DIR}"
print_ok "Pasta ${MODELOS_DIR} pronta."

# Arquivos Office (estrutura ZIP válida)
print_info "Criando modelos Office..."
criar_docx_minimo "${MODELOS_DIR}/Documento_Word.docx"
criar_xlsx_minimo "${MODELOS_DIR}/Planilha_Excel.xlsx"
criar_pptx_minimo "${MODELOS_DIR}/Apresentacao_PowerPoint.pptx"

# Arquivo de texto simples
cat > "${MODELOS_DIR}/Arquivo_de_Texto.txt" << EOF
Criado em: $(date '+%d/%m/%Y %H:%M')
EOF

# Script PHP
cat > "${MODELOS_DIR}/Script_PHP.php" << 'EOF'
<?php

// Inicie seu código aqui

?>
EOF

# Script Shell
cat > "${MODELOS_DIR}/Script_Shell.sh" << 'EOF'
#!/usr/bin/env bash

# Descrição: 
# Uso: bash script.sh

set -euo pipefail

EOF
chmod +x "${MODELOS_DIR}/Script_Shell.sh"

# Arquivo HTML
cat > "${MODELOS_DIR}/Pagina_HTML.html" << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Documento</title>
</head>
<body>

</body>
</html>
EOF

# Ajusta permissões
chmod 644 "${MODELOS_DIR}"/*
chmod +x "${MODELOS_DIR}/Script_Shell.sh"

# -----------------------------------------------------------------------------------
# CONCLUSÃO
# -----------------------------------------------------------------------------------

print_header "${SIM_OK} Modelos criados com sucesso!"
print_info "Local: ${MODELOS_DIR}"
print_info "Clique com o botão direito no Nemo → 'Novo documento' para usá-los."

echo ""
ls -lh "${MODELOS_DIR}"

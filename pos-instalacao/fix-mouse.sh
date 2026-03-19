#!/bin/bash

echo "🔍 Procurando dispositivos de mouse..."

# Lista mouses e guarda em array
mapfile -t MICE < <(xinput list --name-only | grep -i "mouse")

if [ ${#MICE[@]} -eq 0 ]; then
    echo "❌ Nenhum mouse encontrado."
    exit 1
fi

echo
echo "🖱️ Mouses encontrados:"
echo

# Exibe opções numeradas
for i in "${!MICE[@]}"; do
    printf "  [%d] %s\n" "$((i+1))" "${MICE[$i]}"
done

echo
read -p "👉 Selecione o número do mouse: " CHOICE

# Validação
if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#MICE[@]}" ]; then
    echo "❌ Opção inválida."
    exit 1
fi

SELECTED_MOUSE="${MICE[$((CHOICE-1))]}"

echo
echo "✅ Aplicando perfil PLANO ao mouse:"
echo "   $SELECTED_MOUSE"
echo

# Aguarda X estabilizar
sleep 1

xinput set-prop "$SELECTED_MOUSE" "libinput Accel Profile Enabled" 0, 1

echo "🎯 Pronto! Perfil plano aplicado com sucesso."


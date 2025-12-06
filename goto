function goto() {
    if [ -z "$1" ]; then
        echo "Uso: goto <nombre_archivo/directorio>" # Muestra el uso si NO se pasa argumento.
        return 1
    fi
    
    local COINCIDENCIAS
    COINCIDENCIAS=$(find ~ \( -name "$1" -o -iname "$1" \) -print) 
    
    IFS=$'\n' read -r -d '' -a RESULTADOS <<< "$COINCIDENCIAS"
    
    local NUM_RESULTADOS=${#RESULTADOS[@]}

    if [ "$NUM_RESULTADOS" -eq 0 ]; then
        echo "No se encontraron coincidencias para '$1'." # Mensaje corregido: búsqueda fallida.
        return 1
    fi

    local RUTA_FINAL=""

    if [ "$NUM_RESULTADOS" -eq 1 ]; then
        RUTA_FINAL="${RESULTADOS[0]}"
    
    else
        echo -e "Se encontraron $NUM_RESULTADOS coincidencias para '$1'. Selecciona un número:"

        echo ""
        
        for i in "${!RESULTADOS[@]}"; do
            local RUTA="${RESULTADOS[i]}"
            local NOMBRE_ITEM=$(basename "$RUTA")
            local RUTA_DIRECTORIO=$(dirname "$RUTA")
            
            echo -e "$((i+1)). \e[34m$NOMBRE_ITEM ($RUTA_DIRECTORIO)\e[0m"
        
        done
        
        echo ""

        read -r -p "$(echo -e "Introduce (1-$NUM_RESULTADOS): ")" SELECCION
        
        if [[ "$SELECCION" =~ ^[0-9]+$ ]] && [ "$SELECCION" -ge 1 ] && [ "$SELECCION" -le "$NUM_RESULTADOS" ]; then
            RUTA_FINAL="${RESULTADOS[$((SELECCION-1))]}"
        else
            echo -e "Error. Selección invalida. Cancelando."
            return 1
        fi
    fi

    if [ -d "$RUTA_FINAL" ]; then
        cd "$RUTA_FINAL" && ls
    elif [ -f "$RUTA_FINAL" ]; then
        local DIRECTORIO_CONTENEDOR
        DIRECTORIO_CONTENEDOR=$(dirname "$RUTA_FINAL")
        
        cd "$DIRECTORIO_CONTENEDOR"
        ls
    else
        echo -e "El objetivo no es válido."
        return 1
    fi
}

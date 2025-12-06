function fuck() {
            if [ -z "$1" ]; then
                echo -e "Para usar 'fuck' debes especificar el nombre de la aplicación que deseas eliminar."
                return 1
            fi

            local APP_NAME="$1"
            local APP_LOWER=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
            local FILES_TO_CHECK=()

            local LOCATIONS=(
                "$HOME/.config/$APP_NAME"
                "$HOME/.config/$APP_LOWER"
                "$HOME/.local/share/$APP_NAME"
                "$HOME/.local/share/$APP_LOWER"
                "$HOME/.cache/$APP_NAME"
                "$HOME/.cache/$APP_LOWER"
                "$HOME/.$APP_LOWER"
            )
            
            for dir in "${LOCATIONS[@]}"; do
                if [ -d "$dir" ] || [ -f "$dir" ]; then
                    FILES_TO_CHECK+=("$dir")
                fi
            done
            
            local PACKAGES_LIST=()
            local IFS=$'\n' 

            if command -v dpkg &> /dev/null; then
                PACKAGES_LIST+=( $(dpkg -l | grep -i "$APP_NAME" | awk '{print "PAQUETE (SUDO): "$2}') )
            elif command -v dnf &> /dev/null; then
                PACKAGES_LIST+=( $(dnf list installed | grep -i "$APP_NAME" | awk '{print "PAQUETE (SUDO): "$1}') )
            elif command -v pacman &> /dev/null; then
                PACKAGES_LIST+=( $(pacman -Qq | grep -i "$APP_NAME" | awk '{print "PAQUETE (SUDO): "$1}') )
            fi

            if command -v snap &> /dev/null; then
                local SNAP_PKGS
                SNAP_PKGS=$(snap list --all | grep -i "$APP_NAME" | awk '{print "SNAP (SUDO): "$1}')
                if [ ! -z "$SNAP_PKGS" ]; then
                    PACKAGES_LIST+=( $SNAP_PKGS )
                fi
            fi

            if command -v flatpak &> /dev/null; then
                local FLATPAK_PKGS
                FLATPAK_PKGS=$(flatpak list --app | grep -i "$APP_NAME" | awk '{print "FLATPAK (USUARIO): "$1}')
                if [ ! -z "$FLATPAK_PKGS" ]; then
                    PACKAGES_LIST+=( $FLATPAK_PKGS )
                fi
            fi
            
            unset IFS 

            for item in "${PACKAGES_LIST[@]}"; do
                FILES_TO_CHECK+=("$item")
            done

            local NUM_RESULTS=${#FILES_TO_CHECK[@]}

            if [ "$NUM_RESULTS" -eq 0 ]; then
                echo -e "No se encontraron archivos o paquetes relacionados con '$APP_NAME' en ubicaciones comunes."
                return 0
            fi

            echo -e "Se encontraron $NUM_RESULTS elementos relacionados con '\e[1m$APP_NAME\e[0m'."
            
            echo "" 
            for i in "${!FILES_TO_CHECK[@]}"; do
                echo -e "$((i+1)). \e[34m${FILES_TO_CHECK[i]}\e[0m"
            done
            echo "" 
            
            read -r -p "$(echo -e "Selecciona los números con comas (o 'all' / 'exit'): ")" SELECCION

            if [[ "$SELECCION" == "exit" ]]; then
                echo -e "Operación cancelada. El sistema no ha sido modificado."
                return 0
            fi
            
            if [[ "$SELECCION" == "all" ]]; then
                SELECCION=$(seq -s, 1 "$NUM_RESULTS")
            fi

            local ITEMS_TO_DELETE=()
            local IFS=','
            read -ra SELECCION_ARRAY <<< "$SELECCION"

            for num_str in "${SELECCION_ARRAY[@]}"; do
                if [ -z "$num_str" ]; then
                    continue
                fi
                local num=$((num_str - 1))
                if [ "$num" -ge 0 ] && [ "$num" -lt "$NUM_RESULTS" ]; then
                    ITEMS_TO_DELETE+=("${FILES_TO_CHECK[num]}")
                else
                    echo -e "Advertencia: Número '$num_str' fuera de rango. Ignorado."
                fi
            done

            if [ ${#ITEMS_TO_DELETE[@]} -eq 0 ]; then
                echo -e "No se seleccionó ningún elemento válido. Cancelando."
                return 0
            fi
            
            echo -e "Elementos seleccionados para ELIMINAR:"
            echo
            for item in "${ITEMS_TO_DELETE[@]}"; do
                if [[ "$item" == *PAQUETE* ]]; then
                    echo -e "\e[31m[PAQUETE]\e[0m $item"
                elif [[ "$item" == *SNAP* ]]; then
                    echo -e "\e[31m[SNAP]\e[0m $item"
                elif [[ "$item" == *FLATPAK* ]]; then
                    echo -e "\e[31m[FLATPAK]\e[0m $item"
                else
                    echo -e "\e[33m[ARCHIVO/DIR]\e[0m $item"
                fi
            done
            echo
            
            echo -e "Se eliminarán ${#ITEMS_TO_DELETE[@]} elementos (incluyendo paquetes con sudo)."
            read -r -p "$(echo -e "Escribe las palabras 'fuck it' sin el espacio para confirmar la eliminación: ")" FINAL_CONFIRM    
            if [[ "$FINAL_CONFIRM" != "fuckit" ]]; then
                echo -e "Operación cancelada por el usuario. No se ha eliminado nada."
                return 0
            fi
            
            echo -e "Iniciando eliminación... (Se puede requerir contraseña de SUDO)"
            
            for item in "${ITEMS_TO_DELETE[@]}"; do
                
                if [[ "$item" == PAQUETE* ]]; then
                    local PKG_NAME=$(echo "$item" | sed 's/PAQUETE (SUDO): //')
                    echo -e "Desinstalando paquete: $PKG_NAME"
                    if command -v apt-get &> /dev/null; then
                        sudo apt-get purge "$PKG_NAME" -y
                    elif command -v dnf &> /dev/null; then
                        sudo dnf remove "$PKG_NAME" -y
                    elif command -v pacman &> /dev/null; then
                        sudo pacman -Rsn "$PKG_NAME" --noconfirm
                    fi
                    
                elif [[ "$item" == SNAP* ]]; then
                    local PKG_NAME=$(echo "$item" | sed 's/SNAP (SUDO): //')
                    echo -e "Desinstalando Snap: $PKG_NAME"
                    sudo snap remove "$PKG_NAME"
                    
                elif [[ "$item" == FLATPAK* ]]; then
                    local PKG_NAME=$(echo "$item" | sed 's/FLATPAK (USUARIO): //')
                    echo -e "Desinstalando Flatpak: $PKG_NAME"
                    flatpak uninstall "$PKG_NAME" --delete-data -y
                    
                else
                    echo -e "Eliminando residual: $item"
                    rm -rf "$item"
                fi
            done

            if [ $(echo "${ITEMS_TO_DELETE[@]}" | grep -c PAQUETE) -gt 0 ]; then
                echo -e "Limpiando dependencias no utilizadas (autoremove)..."
                if command -v apt-get &> /dev/null; then
                    sudo apt-get autoremove -y
                elif command -v dnf &> /dev/null; then
                    sudo dnf autoremove -y
                fi
            fi
            
            echo -e "Limpieza profunda y selectiva de '$APP_NAME' completada."
        }

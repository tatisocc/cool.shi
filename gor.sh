# Requisitos para gor:

# sudo apt update
# sudo apt install macchanger iw

# Si se tiene instalado Tor, este comando como alias facilitará el uso y cambio de MAC antes de navegar. 

# alias tor='gor && ( torbrowser-launcher & disown )'
 

gor() {
    command -v iw >/dev/null || { echo "ERROR: iw no está instalado."; return 1; }
    command -v macchanger >/dev/null || { echo "ERROR: macchanger no está instalado."; return 1; }

    IFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -n1)

    if [ -z "$IFACE" ]; then
        echo "No se detectó ninguna interfaz inalámbrica."
        return 1
    fi

    SSID=$(iw dev "$IFACE" link | grep "SSID" | awk '{print $2}')

    if [ -n "$SSID" ]; then
        echo "Red actual: $SSID"
    else
        echo "Interfaz detectada pero no conectada a un SSID."
    fi

    echo "Usando interfaz: $IFACE"
    echo "Bajando interfaz..."
    sudo ip link set "$IFACE" down
    
    echo "Cambiando MAC Address (Random y Burned-in simulado)..."
    # CAMBIO 1: Se añade -b para simular BIA/Burned-in Address
    sudo macchanger -r -b "$IFACE"
    
    echo "Levantando interfaz..."
    sudo ip link set "$IFACE" up
    
    # CAMBIO 2: Se eliminan 'ip addr flush' y 'dhclient' para evitar la filtración del hostname vía DHCP.
    echo "La red ha sido reestablecida, pero la solicitud de IP (DHCP) se omite por seguridad."
    echo "Conéctese/solicite IP con una herramienta que oculte el Hostname (ej. Tor)."
    
    echo "Nueva MAC:"
    sudo macchanger -s "$IFACE" | grep Current
}

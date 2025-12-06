# Requisitos para gor:

    # sudo apt update
    # sudo apt install macchanger iw

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
    echo "Cambiando MAC Address..."
    sudo macchanger -r "$IFACE"
    echo "Levantando interfaz..."
    sudo ip link set "$IFACE" up
    echo "Limpiando direcciones IP..."
    sudo ip addr flush dev "$IFACE"
    echo "Renovando DHCP..."
    sudo dhclient -r "$IFACE" 2>/dev/null
    sudo dhclient "$IFACE" 2>/dev/null
    echo "Nueva MAC:"
    sudo macchanger -s "$IFACE" | grep Current
}

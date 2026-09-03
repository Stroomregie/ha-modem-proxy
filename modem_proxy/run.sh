#!/bin/sh
set -e

CONFIG_DIR=/etc/nginx/http.d
mkdir -p "$CONFIG_DIR"
rm -f "$CONFIG_DIR"/target-*.conf

COUNT=$(jq '.targets | length' /data/options.json)
if [ "$COUNT" -eq 0 ]; then
    echo "Modem Proxy: geen targets geconfigureerd (options.targets is leeg) - niets om te proxyen."
fi

USED_PORTS=""
i=0
while [ "$i" -lt "$COUNT" ]; do
    NAME=$(jq -r ".targets[$i].name // \"target-$i\"" /data/options.json)
    TARGET_IP=$(jq -r ".targets[$i].target_ip" /data/options.json)
    TARGET_HOST=$(jq -r ".targets[$i].target_host" /data/options.json)
    LISTEN_PORT=$(jq -r ".targets[$i].listen_port" /data/options.json)

    case " $USED_PORTS " in
        *" $LISTEN_PORT "*)
            echo "Modem Proxy: WAARSCHUWING - poort $LISTEN_PORT is al in gebruik door een eerdere target in deze app, '$NAME' ($TARGET_IP) wordt overgeslagen."
            i=$((i + 1))
            continue
            ;;
    esac

    # host_network:true betekent dat deze container het netwerk van het HA-systeem zelf deelt,
    # dus een poort die hier al beantwoordt, is een echte botsing met iets anders op die machine
    # (HA zelf, MQTT, SSH, een andere host_network-app, ...) - niet alleen met een andere regel
    # hieronder. nc geeft bij twijfel/fout geen duidelijk resultaat; behandel dat dan als "vrij"
    # zodat een tooling-hik nooit stilzwijgend een correct geconfigureerd target laat verdwijnen.
    if nc -z -w 1 127.0.0.1 "$LISTEN_PORT" 2>/dev/null; then
        echo "Modem Proxy: WAARSCHUWING - poort $LISTEN_PORT is al in gebruik door iets anders op dit systeem (niet deze app), '$NAME' ($TARGET_IP) wordt overgeslagen. Kies een andere listen_port."
        i=$((i + 1))
        continue
    fi

    USED_PORTS="$USED_PORTS $LISTEN_PORT"

    cat > "$CONFIG_DIR/target-$i.conf" <<EOF
server {
    listen ${LISTEN_PORT};
    location / {
        proxy_pass http://${TARGET_IP};
        proxy_set_header Host ${TARGET_HOST};
    }
}
EOF
    echo "Modem Proxy: '$NAME' -> http://${TARGET_IP} (Host: ${TARGET_HOST}) beschikbaar op poort ${LISTEN_PORT}"
    i=$((i + 1))
done

nginx -g "daemon off;"

# Modem Proxy — poorten

Deze app draait met `host_network: true`: hij deelt het netwerk van je Home Assistant-systeem
rechtstreeks. Dat is nodig om apparaten op elk intern IP-adres te kunnen bereiken, maar betekent
ook dat elke `listen_port` die je hier instelt een **echte poort op dat systeem** claimt — dezelfde
poortruimte als Home Assistant zelf, MQTT, SSH, en alle andere apps die ook `host_network` gebruiken.

## Wat is hier al bezet (op een standaard HA-installatie)?

| Poort | In gebruik door |
|---|---|
| 8123 | Home Assistant zelf (web-interface) |
| 22 of 22222 | De SSH-app (Advanced SSH & Web Terminal) |
| 1883 / 8883 | Mosquitto (MQTT), indien geïnstalleerd |
| 80 / 443 | Vermijd — vaak gereserveerd voor een andere reverse proxy of Ingress |
| < 1024 | Vermijd in het algemeen — "bekende" poorten, ook als ze nu vrij lijken |

Dit is geen volledige lijst — elke andere app die ook `host_network: true` gebruikt, claimt zijn
eigen poort. Twijfel je? Kies gewoon een poort in de **8080–8199**-range; die is op de meeste
installaties vrij en houdt al je proxy-poorten overzichtelijk bij elkaar.

## Wat controleert de app zelf?

Bij het opstarten (en bij elke herstart na een configuratiewijziging):

1. **Dubbele poort binnen je eigen `targets`-lijst** → de tweede (en volgende) rij met diezelfde
   poort wordt overgeslagen, met een duidelijke waarschuwing in de logs. De rest blijft gewoon werken.
2. **Poort al bezet door iets anders op het systeem** (Home Assistant, MQTT, een andere app, ...) →
   ook die rij wordt overgeslagen met een waarschuwing, in plaats van dat de hele proxy niet opstart.

Dit kan de app **niet** vooraf checken terwijl je een poortnummer typt — dat wordt pas duidelijk
zodra de app (opnieuw) opstart. Kijk daarom na elke wijziging even in het **Log**-tabblad van deze
app: daar staat per apparaat op welke poort het daadwerkelijk beschikbaar is gekomen, en welke
rijen (met reden) zijn overgeslagen.

## Waarom geen keuzelijst (dropdown) voor de poort?

Een dropdown zou moeten kiezen uit een vaste, vooraf bekende lijst — maar welke poorten vrij zijn
verschilt per installatie en verandert continu (andere apps, andere apparaten, andere momenten).
Een vrij in te vullen nummer met de controles hierboven, plus deze tabel als startpunt, is
betrouwbaarder dan een kunstmatig beperkte lijst die toch niet klopt voor jouw specifieke systeem.

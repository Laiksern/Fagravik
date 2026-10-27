# Saltbrygga – bakgrunn v0.1

Pikselkunst for rom **S1 Saltbrygga**, tegnet i spillets interne oppløsning 640 × 360 etter stilguiden v0.2.
Filene i `lag/` er klare til å legges inn som `Sprite2D`-noder (eller `ParallaxLayer`) i prototypen.

## Lagene

| Fil | Bredde | Parallakse | Innhold |
| --- | --- | --- | --- |
| `saltbrygga_himmel_<fase>.png` | 640 px | 0 (fast) | Himmel, sol/måne, stjerner, skyer |
| `saltbrygga_fjell_<fase>.png` | 900 px | 0,25 | Fjerne fjell med snø og dis, fjordvegg med granskog |
| `saltbrygga_bakken_<fase>.png` | 1140 px | 0,55 | Kirkebakken med stavkirken, Storbrua over elva, bjørker, takene i Kaupgata |
| `saltbrygga_brygga_<fase>.png` | 1568 px | 1 | Alt Ingrid går forbi: bygninger, dekke, påler, vann, rekvisitter |
| `saltbrygga_forgrunn_<fase>.png` | 1720 px | 1,2 | Robåt, fortøyningspåler, nett til tørk (gjennomsiktig ellers) |

`<fase>` er `morgen`, `dag` (= formiddag), `ettermiddag`, `kveld` eller `natt`. Alle lag er 360 px høye.

## Slik passer det med prototypen

- Hovedlaget er 1568 px bredt = rommets 2400 verdensenheter × 0,653 (`ZOOM` i `main.gd`). 1 px i bildet = 1,531 verdensenheter.
- **Gulvlinjen ligger på y = 312** i bildet, som `FLOOR_ON_SCREEN` i prototypen. Ingrid (64 px) står med føttene der.
- Plassering av rommets objekter i bildet (px, målt fra venstre): planker over gangen ≈ 170, kloppen over elvemunningen ≈ 307, tauverket ≈ 457, sjøbodene ≈ 686, fiskeboden ≈ 882, fiskehjellen ≈ 990, vertshusets dør **1143** (verden 1750), trappa der Toras båt står ≈ 1208.
- Lyset i vinduer og lykter er tegnet inn i kvelds- og nattbildene. Når spillet får ekte `PointLight2D`, kan de erstattes av lyskilder på samme punkter.
- Mennesker, Toras båt, røyk fra ljoren på vertshuset og vannmerket som stiger tegnes av spillet oppå hovedlaget.
- Den løse planken ved x ≈ 1460 er med vilje litt lysere enn de andre.

Anbefalt oppsett i Godot: en `Parallax2D`-node per lag med `scroll_scale` lik parallaksefaktoren, teksturfilter `Nearest`, og kameraet låst til hele piksler.

## Kilde

`kilde/gen.js` tegner alle lagene prosedyremessig (ren JavaScript, Canvas). `kilde/preview.html` viser dem med parallakse og døgnskifte i nettleseren. Bildene i `lag/` er eksportert derfra; endre koden og eksporter på nytt heller enn å redigere PNG-ene for hånd i denne fasen.

# Garmin Aggressive Inline Skating Tracker

Aplikacja Garmin Connect IQ do śledzenia jazdy na rolkach agresywnych w skateparkach i na ulicy. Automatycznie wykrywa skoki, grindy, slajdy i inne elementy charakterystyczne dla tego sportu.

## Wersja: 2.0.0

### Funkcje aplikacji

#### 🎯 Automatyczne wykrywanie elementów
- **Wykrywanie skoków** - automatyczna detekcja na podstawie danych z akcelerometru i wysokościomierza
- **Wykrywanie grindów** - rozpoznawanie slajdów na rurach i murkach (takeoff → grind phase → landing)
- **Analiza czasu grindowania** - pomiar czasu trwania każdego grinda
- **Statystyki sesji** - łączna liczba skoków, grindów, najdłuższy grind

#### 📊 Monitoring podstawowych danych
- **GPS tracking** - śledzenie trasy i dystansu
- **Tętno** - monitoring częstości akcji serca
- **Prędkość** - aktualna i średnia prędkość
- **Czas sesji** - łączny czas treningu
- **Kalorie** - spalane kalorie podczas sesji

#### 🎮 Interfejs użytkownika
- **Ekran główny** - wyświetlanie kluczowych danych na żywo
- **Menu nawigacyjne** - dostęp do ustawień i statystyk
- **Alerty** - powiadomienia o wykrytych elementach
- **Zapis sesji** - automatyczny zapis treningu do Garmin Connect

### Sposób działania

#### Algorytm wykrywania grindów
1. **Faza takeoff** - wykrywanie skoku przez analizę:
   - Nagłego wzrostu przyspieszenia w osi Z > 2g
   - Wzrostu wysokości > 0.3m w ciągu 0.5s
   
2. **Faza grind** - rozpoznawanie grindowania przez:
   - Względnie stabilną wysokość (±0.2m) przez minimum 0.5s
   - Charakterystyczne wibracje w osiach X/Y
   
3. **Faza landing** - detekcja lądowania:
   - Spadek wysokości > 0.3m
   - Charakterystyczne przyspieszenie uderzenia > 1.5g

#### Kalibracja i dostrajanie
- Algorytm dostosowuje się do stylu jazdy użytkownika
- Filtrowanie fałszywych alarmów (np. jazda po nierównościach)
- Konfiguracja czułości przez ustawienia menu

### Kompatybilność
- **Garmin Forerunner 965** (główne urządzenie testowe)
- **Fenix 6 Pro** (wsparcie dla starszych modeli)
- **Minimalne SDK**: 4.0.0
- **Języki**: Angielski, Czeski

### Wymagane sensory
- GPS
- Akcelerometr
- Wysokościomierz/Barometr
- Sensor tętna (opcjonalny)

### Instalacja
1. Skopiuj plik .prg na urządzenie Garmin
2. Zainstaluj przez Garmin Connect Mobile lub Garmin Express
3. Znajdź aplikację w menu "Apps" na zegarku

### Użytkowanie
1. Uruchom aplikację z menu Apps
2. Poczekaj na połączenie GPS (ikona satelity)
3. Naciśnij START aby rozpocząć sesję
4. Trenuj normalnie - aplikacja automatycznie wykryje elementy
5. Naciśnij STOP aby zakończyć sesję
6. Sesja zostanie automatycznie zapisana do Garmin Connect

### Historia zmian

#### v2.0.0 (2025-06-03)
- ✨ **NOWA FUNKCJA**: Automatyczne wykrywanie grindów i skoków
- ✨ **NOWA FUNKCJA**: Statystyki elementów w czasie rzeczywistym
- ✨ **NOWA FUNKCJA**: Algorytm analizy danych sensorowych
- 🔧 Zaktualizowano do SDK 4.0.0
- 🔧 Dodano wsparcie dla Garmin Forerunner 965
- 🔧 Przepisano architekturę aplikacji
- 🔧 Dodano nowe klasy: SensorManager, TrickDetector, SessionStats
- 🔧 Ulepszona obsługa GPS i sensorów
- 🔧 Nowy interfejs użytkownika z dodatkowymi danymi

#### v0.1.0 (2020)
- 🎯 Pierwsza wersja aplikacji
- 📊 Podstawowe tracking: tętno, dystans, prędkość, czas
- 🎮 Prosty interfejs użytkownika
- 📱 Wsparcie dla Fenix 6 Pro

### Autor
Vít Kotačka

### Licencja
BSD 3-Clause License

### Wsparcie techniczne
To jest projekt edukacyjny/hobbystyczny. Nie jest to profesjonalna aplikacja komercyjna.
Testowana głównie na Garmin Forerunner 965.

### Planowane funkcje (roadmap)
- [ ] Rozpoznawanie różnych typów grindów (frontside, backside, etc.)
- [ ] Analiza wysokości skoków
- [ ] Mapa skateparku z zaznaczonymi elementami
- [ ] Współdzielenie sesji ze znajomymi
- [ ] Progres i osiągnięcia
- [ ] Integracja z mediami społecznościowymi


# Sprawdź co jest w folderze SDK
dir "C:\Users\krawc\AppData\Roaming\Garmin\ConnectIQ\Sdks\"

# sdks pathcs
C:\Users\krawc\AppData\Roaming\Garmin\ConnectIQ\Sdks

### CTRL+SHIFT + P  in vscode

Monkey C: Ru


### powershell
# Sprawdź gdzie jest zainstalowany Connect IQ SDK
dir $env:USERPROFILE\.Garmin\ConnectIQ\Sdks\


# set env
in settings VSCode find "monkeyC.sdkPath" and unhash proper version
$env:PATH += ";C:\Users\krawc\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-4.1.5-2022-08-03-6e17bf167\bin"
$env:PATH += ";C:\Users\krawc\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-7.3.1-2024-09-23-df7b5816a\bin"
$env:PATH += ";C:\Users\krawc\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.1.1-2025-03-27-66dae750f\bin"

shell
monkeyc --version

c+s+p
Monkey C: Verify Installation
Monkey C: Build Current Project


# sprawdź kompilacje
monkeyc --jungles monkey.jungle --device fr965 --output bin/app.prg --private-key developer_key

# Uruchom symulator
monkeydo bin/app.prg fr965




### ekran know how
Współrzędne na ekranie 454x454:
┌─────────────────────────────────┐ y=0
│           Tytuł (centerX, 15)   │
│  ● Status (25,45)               │ y=45
│                                 │
│ Label: (20, y)    Value: (434,y)│ y=70-200
│ Label: (20, y)    Value: (434,y)│
│ Label: (20, y)    Value: (434,y)│
│                                 │
│          Distance               │ y=400
│         (centerX, 420)          │
└─────────────────────────────────┘ y=454
Kluczowe zmiennie:

centerX = 227 (środek poziomo)
centerY = 227 (środek pionowo)
screenWidth = 454
screenHeight = 454
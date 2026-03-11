# Garmin Aggressive Inline Skating Tracker

## Disclaimer

This app is mainly a learning and fun project especially learning how to build or support coding with AI.
It is a very open, fluid, experimental codebase where many things are unfinished, unstable, or may work incorrectly.

Please do not treat this repository as a production-ready or fully working solution.
It should be considered hobby work and a playground for ideas, testing, and future improvements like it was for me.

Development is currently in a "future development" state and has been paused for some time due to Garmin-side limitations/blockers or leack of spare time.

The starting point for experimenting with this project was a clone of Vít's app used only as a basic reference for a simple Garmin Connect IQ application structure. Since then, the project has been heavily rebuilt and expanded, and the current codebase no longer reflects that original app beyond a few historical repository artifacts.

--

Aplikacja Garmin Connect IQ do śledzenia jazdy na rolkach agresywnych w skateparkach i na ulicy. Automatycznie wykrywa skoki, grindy, slajdy i inne elementy charakterystyczne dla tego sportu.

## Wersja: 2.0.0

### Funkcje aplikacji

#### 🎯 Automatyczne wykrywanie elementów
- **Wykrywanie skoków** - automatyczna detekcja na podstawie danych z akcelerometru i wysokościomierza
- **Wykrywanie grindów** - rozpoznawanie slajdów na rurach i murkach (takeoff → grind phase → landing)
- **Analiza czasu grindowania** - pomiar czasu trwania każdego grinda
- **Liczenie obrotów** - liczenie skoków z obrotami i skoków do grindów, liczenie ich w lewą i prawą stronę w celu wyliczenia preferencji obrotu
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

#### Kalibracja i dostrajanie - (w planach)
- Algorytm dostosowuje się do stylu jazdy użytkownika
- Filtrowanie fałszywych alarmów (np. jazda po nierównościach)
- Konfiguracja czułości przez ustawienia menu

### Kompatybilność
- **Garmin Forerunner 965** (główne urządzenie testowe)
- **Fenix 6 Pro** (wsparcie dla starszych modeli)
- **Minimalne SDK**: 5.0.0
- **Języki**: Angielski, Czeski

### Wymagane sensory
- GPS
- Akcelerometr
- Wysokościomierz/Barometr
- Sensor tętna (opcjonalny)

### Instalacja
1. Skopiuj plik .prg na urządzenie Garmin. Wklej w folder GARMIN/APPS, odłącz zegarek i sprawdź aplikację
2. Zainstaluj przez Garmin Connect Mobile lub Garmin Express
3. Znajdź aplikację w menu "Apps" na zegarku

### Użytkowanie
1. Uruchom aplikację z menu Apps
2. Poczekaj na połączenie GPS (ikona satelity)
3. Naciśnij START aby rozpocząć sesję
4. Trenuj normalnie - aplikacja automatycznie wykryje elementy
5. Naciśnij STOP aby zakończyć sesję
6. Sesja zostanie automatycznie zapisana do Garmin Connect lub nie jesli zostanie kliknięte odrzuć sesję

### Historia zmian
#### v3.0.0
- ✨ **NOWE**: Kompletna przebudowa, widoki w osobnych plikach, sensory w osobnych plikach. Dużo zmian.


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
Adrian Krawczyk

### Licencja
BSD 3-Clause License

### Wsparcie techniczne
To jest projekt edukacyjny/hobbystyczny. Nie jest to profesjonalna aplikacja komercyjna.
Testowana głównie na Garmin Forerunner 965.

### Planowane funkcje (roadmap)
- [ ] Analiza wysokości skoków
- [ ] Mapa skateparku z zaznaczonymi elementami
- [ ] Współdzielenie sesji ze znajomymi
- [ ] Progres i osiągnięcia
- [ ] Integracja z mediami społecznościowymi



##### my help stuff to use and maintain enviroment because i forgot about some stuff after few days ;))

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
//$env:PATH += ";C:\Users\krawc\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-4.1.5-2022-08-03-6e17bf167\bin"
//$env:PATH += ";C:\Users\krawc\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-7.3.1-2024-09-23-df7b5816a\bin"
active - usa always after VSCode restart and verify installation, even after closing terminal use the same action again
$env:PATH += ";C:\Users\krawc\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.1.1-2025-03-27-66dae750f\bin"

shell
monkeyc --version

ctl+shift+P
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




// założenia projektu detekcji tricku 
 File Modification Summary

  I have successfully completed the Enhanced Rotation Detection with Better Calibration phase. Here's what was
  accomplished:

  Files Modified:

  1. C:\Users\krawc\source\repos\adekkpl\garmin-agv-skating\source\sensors\RotationDetector.mc | ITERATION: 2
    - Major architectural enhancements:
        - Multi-axis detection: Added support for X (pitch), Y (roll), and Z (yaw) axis rotation detection
      - Advanced calibration: Replaced single-axis baseline with multi-axis baseline + variance analysis
      - Adaptive thresholds: Dynamic threshold adjustment based on gyroscope noise characteristics
      - Pattern analysis: Added analyzeRotationPattern() for complex rotation classification
      - Enhanced state machine: New functions for multi-axis rotation start, progress, and completion detection

  Key Technical Improvements:

  1. Advanced Calibration System:
  // Enhanced multi-axis gyroscope calibration with variance analysis
  function calibrateMultiAxisGyro(gyroX, gyroY, gyroZ, timestamp) {
      // Calculate mean baseline for each axis
      gyroBaseline.put("x", gyroBaseline.get("x") / CALIBRATION_SAMPLES);
      gyroBaseline.put("y", gyroBaseline.get("y") / CALIBRATION_SAMPLES);
      gyroBaseline.put("z", gyroBaseline.get("z") / CALIBRATION_SAMPLES);

      // Calculate adaptive thresholds based on noise levels
      calculateAdaptiveThresholds();
  2. Multi-Axis Pattern Recognition:
  // Advanced rotation pattern analysis for multi-axis detection
  function analyzeRotationPattern(smoothedRates) {
      // Determine dominant rotation axis and type
      if (abs(rateX) > adaptiveThreshold.get("x")) {
          dominantAxis = rateX > 0 ? "pitch_forward" : "pitch_backward";
      } else if (abs(rateY) > adaptiveThreshold.get("y")) {
          dominantAxis = rateY > 0 ? "roll_right" : "roll_left";
      }
  3. Enhanced Detection Thresholds:
    - Pitch (X-axis): 60°/s for forward/backward flips
    - Roll (Y-axis): 60°/s for side-to-side rolls
    - Yaw (Z-axis): 75°/s for spinning rotations (reduced from 90°/s)
    - Adaptive adjustment: Thresholds automatically adjust based on device noise characteristics

  Architectural Insights

  Why Multi-Axis Detection Matters for Skating:

  1. Real-World Skating Physics: Aggressive inline skating involves complex 3D rotations:
    - Spin tricks: Pure Z-axis rotation (traditional approach worked here)
    - Flip tricks: X-axis rotation (completely missed by old system)
    - Roll tricks: Y-axis rotation (also missed)
    - Complex tricks: Multi-axis combinations (impossible to detect before)
  2. Improved Detection Accuracy: The enhanced calibration addresses core issues:
    - Device variability: Each Garmin watch has slightly different gyroscope characteristics
    - Environmental factors: Temperature, wear position, and user movement affect baseline readings
    - Adaptive thresholds: System automatically adjusts sensitivity based on actual device performance

  Sensor Fusion Architecture Pattern:

  This enhancement implements a layered detection architecture:

  1. Raw Sensor Layer: SensorManager provides 25Hz multi-axis gyroscope data
  2. Processing Layer: RotationDetector applies calibration, filtering, and pattern analysis
  3. Detection Layer: Enhanced state machine classifies rotation types with confidence scoring
  4. Integration Layer: Results feed back to TrickDetector for jump-rotation correlation

  Next Steps & Considerations

  The next critical step is integrating the AccelerometerJumpDetector with the TrickDetector system. This will
  create the comprehensive sensor fusion that addresses your original question about the technical foundation for
  jump detection.

  The enhanced RotationDetector now provides:
  - Immediate detection response (25Hz vs 1Hz barometric)
  - Multi-axis rotation classification (pitch, roll, yaw)
  - Adaptive calibration (personalizes to each device/user)
  - Pattern confidence scoring (reduces false positives)

  This solid foundation will allow the AccelerometerJumpDetector to correlate with rotation events for
  jump-with-rotation detection - exactly what your original question was seeking to understand and implement.

# Changelog

Wszystkie istotne zmiany w projekcie Garmin Aggressive Inline Skating Tracker są dokumentowane w tym pliku.

Format bazuje na [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
a projekt używa [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planowane funkcje
- Rozpoznawanie różnych typów grindów (frontside, backside, etc.)
- Analiza wysokości skoków
- Mapa skateparku z zaznaczonymi elementami
- Współdzielenie sesji ze znajomymi
- Progres i osiągnięcia rozszerzone
- Integracja z mediami społecznościowymi

## [2.0.0] - 2025-06-03

### ✨ Dodane
- **NOWA FUNKCJA**: Automatyczne wykrywanie grindów i skoków
  - Algorytm analizy danych z akcelerometru i wysokościomierza
  - Wykrywanie faz: takeoff → grind/airborne → landing
  - Konfigurowalna czułość wykrywania
- **NOWA FUNKCJA**: Statystyki elementów w czasie rzeczywistym
  - Licznik total tricks, grinds, jumps
  - Pomiar czasu najdłuższego grinda
  - Średni czas grindów
- **NOWA FUNKCJA**: System osiągnięć
  - Pierwsze triki, milestone'y, rekordy czasu
  - Powiadomienia o osiągnięciach
  - Progress tracking dla celów sesji
- **NOWA FUNKCJA**: Rozbudowany interfejs użytkownika
  - 4 tryby wyświetlania (Main, Tricks, Performance, Session)
  - Animacje wykrywania trików
  - Paski postępu dla celów
  - Status sensorów i GPS
- **NOWA FUNKCJA**: Zaawansowany system sensorów
  - Integracja akcelerometru, barometru, GPS, HR
  - Bufory historii danych do analizy
  - Automatyczna kalibracja
  - Filtrowanie szumów

### 🔧 Zmienione
- Zaktualizowano minimalną wersję SDK do 4.0.0
- Przepisano całą architekturę aplikacji z modularnym podejściem
- Dodano wsparcie dla nowszych urządzeń Garmin (FR965, Fenix 7, etc.)
- Ulepszona obsługa przycisków i gestów
- Nowy system menu z kategoriami

### 🐛 Naprawione
- Problemy z kompatybilnością starszych wersji SDK
- Optymalizacja wydajności rysowania UI
- Lepsze zarządzanie pamięcią

### 📚 Dokumentacja
- Kompletnie przepisany README.md z instrukcjami
- Dodany CHANGELOG.md do śledzenia wersji
- Szczegółowy opis algorytmów wykrywania
- Instrukcje instalacji i użytkowania

### 🏗️ Architektura
- **SensorManager**: Zarządzanie wszystkimi sensorami
- **TrickDetector**: Silnik wykrywania trików z maszyną stanów
- **SessionStats**: Kompleksowe statystyki sesji
- **InlineSkatingView**: Zaawansowany interfejs z trybami
- **InlineSkatingDelegate**: Obsługa wszystkich inputów

## [1.0.0] - [Nigdy nie wydane]
*Wersja 1.x została pominięta aby oznaczyć znaczący skok funkcjonalności*

## [0.1.0] - 2020

### ✨ Dodane
- Podstawowa aplikacja Garmin Connect IQ
- Wyświetlanie podstawowych metryk fitness:
  - Tętno (Heart Rate)  
  - Dystans (Distance)
  - Prędkość (Speed)
  - Czas (Timer)
- Prosty interfejs użytkownika z layoutem XML
- Podstawowe menu z dwoma opcjami
- Wsparcie dla Garmin Fenix 6 Pro
- Wielojęzyczność: angielski, czeski
- Podstawowe uprawnienia dla GPS i sensorów

### 🔧 Techniczne
- Bazowanie na SDK 3.1.0
- Struktura plików: App, View, Delegate
- Podstawowe zarządzanie stanem aplikacji
- Licencja BSD 3-Clause

---

## Legenda

- `✨ Dodane` - nowe funkcje
- `🔧 Zmienione` - zmiany w istniejących funkcjach  
- `🐛 Naprawione` - poprawki błędów
- `🗑️ Usunięte` - usunięte funkcje
- `📚 Dokumentacja` - zmiany w dokumentacji
- `🏗️ Architektura` - zmiany w architekturze/strukturze
- `⚠️ Przestarzałe` - funkcje oznaczone jako przestarzałe
- `🔒 Bezpieczeństwo` - poprawki bezpieczeństwa
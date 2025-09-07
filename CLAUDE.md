# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Instructions for Claude Code Sessions

**CRITICAL:** Always update this CLAUDE.md file with important technical discoveries during development:
- API limitations and workarounds discovered
- Compilation errors and their solutions  
- Component architecture insights
- Performance optimizations found
- Device-specific behaviors noted
- Integration patterns that work/don't work

This prevents rediscovering the same issues in every session and builds institutional knowledge.

## Essential Command Line Workflow for Claude Code Sessions

**REQUIRED STEPS** for every session working with monkeyc commands:

### Step 1: Set SDK Path (EVERY TIME)
```powershell
# MUST run this first in every new session
$env:PATH += ";C:\Users\krawc\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.1.1-2025-03-27-66dae750f\bin"
```

### Step 2: Verify SDK Works
```powershell
# Always verify before building
monkeyc -v
# Expected output: Connect IQ Compiler version: 8.1.1
```

### Step 3: Build with Correct Parameters
```powershell
# Navigate to project directory
cd "C:\Users\krawc\source\repos\adekkpl\garmin-agv-skating"

# Build command with ALL required parameters:
monkeyc --jungles monkey.jungle --device fr965 --output bin/garminagvskating.prg --private-key "C:\Users\krawc\OneDrive\Hobby\Programowanie Garmin\Garmin Projects\developer_key"
```

**CRITICAL PARAMETERS:**
- `--output bin/garminagvskating.prg` - Use project-consistent filename (matches VSCode config)
- `--private-key "C:\Users\krawc\OneDrive\Hobby\Programowanie Garmin\Garmin Projects\developer_key"` - Full path to developer key
- `--device fr965` - Primary target device
- `--jungles monkey.jungle` - Project configuration file

### Step 4: Run in Simulator (if needed)
```powershell
monkeydo bin/garminagvskating.prg fr965
```

**COMMON MISTAKES TO AVOID:**
- ❌ Forgetting to set SDK path first
- ❌ Using `--output bin/app.prg` instead of `garminagvskating.prg`  
- ❌ Omitting private key parameter
- ❌ Wrong path to private key file

## Project Overview

This is a Garmin Connect IQ application for tracking aggressive inline skating in skateparks and streets. The app automatically detects jumps, grinds, slides, and rotations using sensor data from accelerometer, barometer, and GPS.

**Current version:** 3.0.0  
**Target device:** Garmin Forerunner 965 (primary testing device)  
**SDK version:** 5.0.0+  
**Languages:** English, Polish

## Build and Development Commands

### Environment Setup (Windows)

**How to setup CMD line commands**: https://developer.garmin.com/connect-iq/reference-guides/monkey-c-command-line-setup/

for /f usebackq %i in (%APPDATA%\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.1.1-2025-03-27-66dae750f\bin) do set CIQ_HOME=%~pi

```powershell
# Set SDK path in PowerShell (required after each VSCode restart)
$env:PATH += ";C:\Users\krawc\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.1.1-2025-03-27-66dae750f\bin"

# Verify installation
monkeyc --version
```

### VSCode Commands
- **Ctrl+Shift+P** → `Monkey C: Verify Installation` - Check SDK setup
- **Ctrl+Shift+P** → `Monkey C: Build Current Project` - Build the app
- **Ctrl+Shift+P** → `Monkey C: Run` - Launch in simulator

### Manual Build Commands
```bash
# Build for FR965 (use consistent filename with VSCode config)
monkeyc --jungles monkey.jungle --device fr965 --output bin/garminagvskating.prg --private-key "C:\Users\krawc\OneDrive\Hobby\Programowanie Garmin\Garmin Projects\developer_key"

# Run in simulator
monkeydo bin/garminagvskating.prg fr965
```

**Build Filename Convention:**
- VSCode configuration expects: `${workspaceFolderBasename}.prg` = `garminagvskating.prg`
- Always use `--output bin/garminagvskating.prg` for consistency with IDE setup

### Project Configuration
- **manifest.xml** - App metadata, permissions, supported devices
- **monkey.jungle** - Simple build configuration pointing to manifest
- **.vscode/launch.json** - Debug configurations for FR965 and FR955

## Architecture Overview

The application follows a modular architecture with clear separation of concerns:

### Core Application (`source/AggressiveSkatingApp.mc`)
- Main entry point extending `Application.AppBase`
- Initializes and manages all components
- Handles component lifecycle and connections
- Provides callback methods for cross-component communication

### Component Structure

**Session Management:**
- `SessionManager.mc` - Controls session state (start/pause/stop), GPS, statistics, activity recording
- `session/SessionStats.mc` - Tracks statistics (jumps, grinds, rotations, time, distance)
- `session/ActivityRecorder.mc` - Records FIT data for Garmin Connect

**Sensor Processing:**
- `sensors/SensorManager.mc` - Coordinates all sensor inputs and processing
- `sensors/TrickDetector.mc` - Detects grinds and jumps from accelerometer/barometer data
- `sensors/RotationDetector.mc` - Analyzes gyroscope data to count rotations and direction
- `sensors/GPSTracker.mc` - Handles GPS positioning and distance calculations

**User Interface:**
- `ViewManager.mc` - Manages view transitions and delegates
- `views/MainView.mc` - Primary session view with live statistics
- `views/StatsView.mc` - Detailed session statistics
- `views/TricksView.mc` - Trick history and counts
- `views/RotationView.mc` - Rotation analysis and preferences
- `views/ProgressView.mc` - Session progress tracking
- `views/SettingsView.mc` - App configuration

**Utilities:**
- `Utils.mc` - Helper functions and constants
- `delegates/` - Input handling and navigation

### Key Detection Algorithms

**Grind Detection (3-phase):**
1. **Takeoff:** Acceleration > 2g in Z-axis + height increase > 0.3m in 0.5s
2. **Grind Phase:** Stable height (±0.2m) for minimum 0.5s + characteristic X/Y vibrations
3. **Landing:** Height drop > 0.3m + impact acceleration > 1.5g

**Rotation Detection:**
- Gyroscope threshold analysis for left/right rotation counting
- Preference tracking for rotation statistics

### Component Communication

The app uses a callback-based system for component communication:
- `onTrickDetected()` - Trick detection notifications
- `onRotationDetected()` - Rotation counting updates  
- `onPositionUpdate()` - GPS position changes
- `onSessionStateChange()` - Session state transitions

### Screen Layout Constants (454x454 display)
```
centerX = 227 (horizontal center)
centerY = 227 (vertical center)
Title position: (centerX, 15)
Status indicator: (25, 45)
Data rows: Labels at (20, y), Values at (434, y)
Distance display: (centerX, 420)
```

## Development Notes

### File Organization
- **Main app logic:** `source/AggressiveSkatingApp.mc`
- **Session management:** `source/SessionManager.mc` + `source/session/`
- **Sensor processing:** `source/sensors/`
- **UI components:** `source/views/` + `source/ViewManager.mc`
- **Resources:** `resources/` (strings, drawables, layouts)

### Testing Device Priority
1. Garmin Forerunner 965 (primary target)
2. Garmin Forerunner 955 (backup testing)
3. Other API 5.0+ devices (limited testing)

### Important Implementation Details
- All components are initialized with null checks and error handling
- Component connections use `has :methodName` checks for method availability
- Sensor data processing runs on background threads
- Session state persists across app restarts
- FIT file recording requires proper session lifecycle management

### Language Support
- English (eng) - primary
- Polish (pol) - secondary

The codebase uses Polish comments and variable names in some areas, particularly in algorithm documentation and debug messages.

## Critical Technical Discoveries & Best Practices

### API Limitations (ConnectIQ SDK 5.0.0+)
**Math Library Restrictions:**
- ❌ `Math.min()` and `Math.max()` are NOT available in API 5.0
- ❌ `Math.abs()` is NOT available in API 5.0  
- ✅ `Math.PI` and `Math.sqrt()` ARE available
- ✅ Use custom functions from `Utils.mc` instead:
  - `abs(value)` - absolute value function
  - `min(a, b)` - minimum value function
  - `max(a, b)` - maximum value function (if implemented)

### File Import System
**No Explicit Imports Needed:**
- All `.mc` files in the project are automatically visible to each other after compilation
- No need for `import`, `using`, or `require` statements
- Components can directly call functions from other files (e.g., `abs()` from `Utils.mc`)

### Common Compilation Errors to Watch For
1. **Orphaned Code Blocks:** Code outside function boundaries causes `extraneous input` errors
2. **Math Function Usage:** Always use Utils.mc equivalents for missing Math functions
3. **Function Scope:** Ensure all code is properly contained within function or class boundaries

### Memory Management
- Garmin devices have strict memory constraints
- Avoid creating large arrays or complex data structures
- Use efficient algorithms and data structures for sensor processing

### Sensor Data Processing
**Multi-Axis Gyroscope Enhancement:**
- Enhanced RotationDetector now supports X (pitch), Y (roll), Z (yaw) axis detection
- Adaptive thresholds based on device-specific gyroscope noise characteristics
- Pattern analysis for complex multi-axis rotations
- 25Hz processing rate for immediate detection response

**Detection Thresholds (Post-Calibration):**
- Pitch (X-axis): 60°/s for forward/backward flips
- Roll (Y-axis): 60°/s for side-to-side rolls  
- Yaw (Z-axis): 75°/s for spinning rotations
- Adaptive adjustment based on noise analysis

### Debugging Best Practices
- Always test compilation after major changes
- Use `System.println()` for debug output in simulator
- Check function availability with `has :methodName` before calling
- Validate all sensor data inputs for null/invalid values

### Command Line Compilation Setup
**Essential Knowledge for Every Session:**
- SDK path MUST be set before any monkeyc commands: `$env:PATH += ";...\connectiq-sdk-win-8.1.1-2025-03-27-66dae750f\bin"`
- Always verify with `monkeyc -v` first
- Use project-consistent output filename: `--output bin/garminagvskating.prg` (matches VSCode configuration)
- Private key location: `"C:\Users\krawc\OneDrive\Hobby\Programowanie Garmin\Garmin Projects\developer_key"`
- Build template: `monkeyc --jungles monkey.jungle --device fr965 --output bin/garminagvskating.prg --private-key "[path]"`

### Session Management Notes
- Session state should persist across app lifecycle
- GPS accuracy is critical for distance calculations
- FIT file recording requires proper start/stop sequence
- Statistics tracking must handle edge cases (division by zero, etc.)

## Development Session Memory

### Recent Technical Solutions
- **Multi-axis rotation detection** implemented in RotationDetector.mc
- **Enhanced calibration system** with variance analysis and adaptive thresholds
- **Math function compatibility** issues resolved using Utils.mc alternatives
- **Compilation error patterns** identified and documented
- **Command line workflow** standardized with proper SDK path and output naming
- **Build consistency** established with garminagvskating.prg filename convention

### Component Integration Progress
- RotationDetector enhanced for multi-axis detection ✅
- AccelerometerJumpDetector created for immediate jump detection
- TrickDetector integration with enhanced rotation system (pending)
- AlertManager and DiagnosticLogger components added

### Next Development Priorities
1. Integrate AccelerometerJumpDetector with TrickDetector system
2. Test comprehensive sensor fusion (accelerometer + gyroscope + barometer)
3. Validate multi-axis rotation detection in simulator and real device
4. Optimize memory usage and processing efficiency
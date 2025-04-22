<!-- filepath: /Users/universinformatique/CascadeProjects/poze/plan.md -->
# Poze App — Unified Development Plan & Roadmap

This document merges the technical plan and feature roadmap for Poze, a modern macOS process manager built with Flutter. Use this as a reference for architecture, implementation, and future enhancements.

---

## Project Overview
Poze is a Flutter/macOS application for managing system processes. It provides real-time process listing, CPU usage stats, and controls to pause/resume applications, all with a modern, minimal UI.

---

## Core Features (Current)
- [x] List all running processes with name, PID, command, and CPU usage
- [x] Show system info (macOS version, total processes, CPU usage, last update)
- [x] Pause/resume processes (via `killall -STOP` / `killall -CONT`)
- [x] Manual and auto-refresh
- [x] Minimal, icon-only sidebar navigation
- [x] Modern, native macOS look and feel
- [x] System tray integration (show/hide, quit)
- [x] Settings view (dark mode, refresh interval, etc.)

---

## Project Structure
```
lib/
├── main.dart                  # App entry point
├── app.dart                   # App configuration
├── models/
│   ├── process_model.dart     # Data model for processes
│   └── system_stats.dart      # System statistics model
├── services/
│   ├── process_service.dart   # Process interaction service
│   └── system_service.dart    # System stats service
├── views/
│   ├── home_view.dart         # Main view
│   └── settings_view.dart     # Settings view
└── widgets/
    ├── process_list_item.dart # Process display widget
    ├── cpu_usage_chart.dart   # CPU usage chart widget
    └── control_buttons.dart   # Action buttons
```

---

## Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  macos_ui: ^2.0.0            # macOS-style UI
  process_run: ^0.14.0        # Shell command execution
  provider: ^6.1.1            # State management
  shared_preferences: ^2.5.3  # Settings persistence
  tray_manager: ^0.2.2        # System tray integration
  launch_at_startup: ^0.5.1   # Start at login (macOS)
  # charts_flutter: ^0.12.0   # (optional, for advanced charts)
```

---

## Implementation Phases

### Phase 1: Initial Setup
- [x] Configure project and dependencies
- [x] Create base app structure with macos_ui
- [x] Implement core UI per design

### Phase 2: Core Functionality
- [x] Service to list running processes (via `ps`/`top`)
- [x] Data models for processes and system stats
- [x] UI to display process list and system info

### Phase 3: Advanced Features
- [x] Show CPU usage per process
- [x] Pause/resume processes (`killall -STOP`/`-CONT`)
- [x] UI controls for actions

### Phase 4: Polish & Performance
- [~] UI refinement and animations (partially done)
- [~] Performance optimization (partially done)
- [~] Bug fixes and testing (ongoing)

---

## System Commands Used
- `ps aux` — List processes
- `top -l 1 -stats pid,command,cpu` — CPU usage
- `killall -STOP [processName]` — Pause process
- `killall -CONT [processName]` — Resume process

---

## User Interface
- [x] Minimal, icon-only sidebar for navigation
- [x] Main list: process icon, name, PID, command, CPU usage bar, control buttons
- [ ] Filtering, sorting, and search (planned)
- [x] Responsive, macOS-native look

---

## Planned Enhancements & Features
### Process Management
- [ ] Terminate (kill) processes with confirmation
- [ ] Batch actions (pause/kill multiple)
- [ ] Detailed process info (memory, threads, open files)
- [ ] Search/filter/sort processes

### System Monitoring
- [ ] Live CPU/memory/network/disk charts
- [ ] Per-process resource graphs
- [ ] Notifications for high resource usage
- [ ] Quick stats in tray menu

### UI/UX
- [~] List animations, hover/selection (basic animations present)
- [ ] More themes, accent color selection
- [ ] Compact/expanded views
- [ ] Keyboard shortcuts
- [ ] Accessibility improvements

### Sidebar & Navigation
- [ ] Sidebar reordering (if more sections)
- [ ] More sidebar items (logs, performance, favorites)
- [ ] Tooltips for sidebar icons

### Settings & Customization
- [x] Theme selection (light/dark/system)
- [x] Start at login (macOS, via `launch_at_startup`)
- [ ] Custom auto-refresh intervals
- [ ] Show/hide system processes
- [ ] Confirm before pausing/killing processes
- [ ] Enable/disable notifications
- [ ] Language/locale selection
- [ ] Compact/expanded view toggle
- [ ] Configurable columns
- [ ] Export process list (CSV, JSON)
- [ ] Localization

### Advanced & Power User
- [ ] AppleScript/Automator integration
- [ ] CLI companion
- [ ] Plugin/add-on system

### Stretch Goals
- [ ] Remote monitoring
- [ ] Mobile companion app
- [ ] Cloud sync of settings

---

## Technical & macOS Considerations
- [x] Request necessary permissions for system info
- [x] Ensure compatibility with macOS versions
- [x] Sandbox compliance
- [x] All destructive actions require confirmation dialogs

---

## Next Steps (Potential)
- Add search functionality
- Support notifications
- CPU usage history
- Custom process management profiles

---

## Notes
- Prioritize stability, security, and privacy
- Keep UI minimal, fast, and native

---

_Last updated: 2025-04-22_


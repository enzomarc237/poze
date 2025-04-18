# Poze

A modern, minimal, and native macOS application for managing system processes and monitoring system stats.

---

## Features

- **Live Process List**: View all running processes with name, PID, command, and CPU usage.
- **System Stats**: See macOS version, total active processes, CPU usage, and last update time.
- **Process Actions**: Pause/resume processes (with planned support for kill, batch actions, and more).
- **Modern UI**: Minimal, icon-only sidebar; macOS-inspired cards, toolbars, and animations.
- **System Tray Integration**: Quick access to show/hide or quit the app from the menu bar.
- **Settings**: Configure dark mode, auto-refresh interval, and more.
- **Auto & Manual Refresh**: Keep stats up-to-date automatically or on demand.

---

## Planned Enhancements
See [`ENHANCEMENT_PLAN.md`](ENHANCEMENT_PLAN.md) for a full roadmap, including:
- Process termination, detailed info, filtering, batch actions
- Live resource charts and notifications
- Customizable columns, export, localization
- Power-user features (CLI, plugins, remote monitoring)

---

## Getting Started

### Prerequisites
- [Flutter](https://flutter.dev/) 3.7+
- macOS 12+

### Install dependencies
```sh
flutter pub get
```

### Run the app
```sh
flutter run
```

### Assets
- Place your tray icon at `assets/app_icon.png` (see pubspec.yaml for asset registration)

---

## Project Structure
- `lib/` — Main app source code (views, widgets, models, services)
- `ENHANCEMENT_PLAN.md` — Feature roadmap and planning
- `pubspec.yaml` — Dependencies and assets

---

## Contributing
- See the enhancement plan for ideas.
- PRs, issues, and suggestions are welcome!

---

## License
MIT (or your choice)

---

_Last updated: 2025-04-18_

# Poze App Enhancement Roadmap

This document outlines planned enhancements and feature ideas for the Poze macOS system/process manager app. Use this as a living reference for development and prioritization.

---

## Core Features (Current)
- List all running processes with name, PID, command, and CPU usage
- Show system info (macOS version, total processes, CPU usage, last update)
- Pause/resume processes
- Manual and auto-refresh
- Minimal, icon-only sidebar navigation
- Modern, native macOS look and feel
- System tray integration (show/hide, quit)
- Settings view (dark mode, refresh interval, etc.)

---

## Planned Enhancements & Features

### 1. Process Management
- [ ] **Terminate (kill) processes** with confirmation dialog
- [ ] **Suspend/Resume** (already present, improve feedback/UX)
- [ ] **Detailed process info** (memory, threads, open files, etc.) via modal or side panel
- [ ] **Search/filter processes** by name, PID, or resource usage
- [ ] **Sort processes** by CPU, memory, name, PID, etc.
- [ ] **Batch actions** (pause/kill multiple selected processes)

### 2. System Monitoring
- [ ] **Live CPU/memory/network/disk usage charts**
- [ ] **Per-process resource graphs**
- [ ] **Notifications** for high CPU/memory usage or unresponsive apps
- [ ] **Quick system stats** in tray menu

### 3. UI/UX Improvements
- [ ] **Process list animations** (entry/exit, hover, selection)
- [ ] **Customizable themes** (more color schemes, accent color selection)
- [ ] **Compact/expanded view modes**
- [ ] **Keyboard shortcuts** for actions (refresh, search, kill, etc.)
- [ ] **Accessibility improvements** (screen reader, contrast, font scaling)

### 4. Sidebar & Navigation
- [ ] **Sidebar drag-and-drop reordering** (if more sections added)
- [ ] **More sidebar items** (e.g., logs, performance, favorites)
- [ ] **Sidebar tooltips** for icon-only navigation

### 5. Settings & Customization
- [ ] **Configurable columns** in process list
- [ ] **Custom auto-refresh intervals** (per user preference)
- [ ] **Export process list** (CSV, JSON)
- [ ] **Language/localization support**

### 6. Advanced & Power User Features
- [ ] **AppleScript/Automator integration**
- [ ] **Command-line interface (CLI) companion**
- [ ] **Plugin/add-on system** for extensibility

---

## Stretch Goals
- [ ] **Remote monitoring** (view/manage processes on other Macs via network)
- [ ] **Mobile companion app** (notifications, quick stats)
- [ ] **Cloud sync of settings/preferences**

---

## Notes
- Prioritize stability, security, and privacy (especially for process management features)
- All destructive actions (kill, batch kill) must have confirmation dialogs
- Keep UI minimal, fast, and macOS-native in spirit

---

_Last updated: 2025-04-18_

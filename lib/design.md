# 🎨 DESIGN.md: Smart School Bus Tracker 🚌✨

*Design spec provided by the product team. Keep this file in-sync with any visual changes.*

## 🟡 Color Palette

| Token | Hex | Usage |
|---|---|---|
| Primary | `#FFD700` | Buttons, active states, bus icon |
| Background | `#FAFAFA` | Screen backgrounds |
| Surface | `#FFFFFF` | Cards, dialogs |
| On surface | `#1E1E1E` | Text, icons |
| Success | `#4CAF50` | Paid, trip active |
| Error | `#FF5252` | Unpaid, trip stopped |

## 🎬 Animations

- **Squishy buttons:** scale 1.0 → 0.94 → 1.0 on tap (120ms easeOut)
- **Screen transitions:** 300ms fade transition between screens
- **Map marker:** pulsing yellow dot with ripple
- **Loading:** SVG bus bouncing on scrolling road (SVG assets TBD)

## 🪟 Glassmorphism

- Frosted glass cards use `BackdropFilter` with 10px blur
- Applied on map overlay cards and floating panels

## 📱 Screen Layouts

### Login / OTP
- Max white space, borderless text field with charcoal bottom line
- Pill-shaped yellow button at bottom

### Parent Map (live_map_screen.dart)
- Edge-to-edge map (flutter_map / OpenStreetMap)
- Yellow dot marker with liquid ripple animation
- Frosted glass card at bottom with child name + ETA

### Driver Dashboard (driver_shell.dart)
- Single wide pill button: yellow [START TRIP] → red [STOP TRIP]
- Squishy bounce on press
- Route dropdown selector above button

### Admin Dashboard (admin_shell.dart)
- Three bottom-nav tabs: Users, Payments, Routes
- White floating cards with soft shadows
- Liquid payment toggles (Switch.adaptive with green tint)

## 📦 SVG Assets (to be provided)

| Asset | Screen | Purpose |
|---|---|---|
| `assets/bus_loading.svg` | Loading | Bouncing bus on road |
| `assets/phone_unlock.svg` | Login/OTP | Success splash |
| `assets/gps_radar.svg` | Driver | Breathing radar ping |

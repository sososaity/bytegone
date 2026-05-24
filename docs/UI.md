# UI Design System

Bytegone uses a custom in-code design system built on SwiftUI. All visual decisions are expressed as constants, reusable modifiers, and component patterns.

---

## Tokens

### Corner radii

```swift
enum Theme {
    static let cardCorner: CGFloat = 14
    static let panelCorner: CGFloat = 18
}
```

### Animations

```swift
static let pop   = Animation.spring(response: 0.45, dampingFraction: 0.78)
static let smooth = Animation.smooth(duration: 0.35)
static let snap  = Animation.snappy(duration: 0.25)
```

These three curves are used consistently:
- `pop` — navigation transitions, large state changes.
- `smooth` — hover states, ambient background shifts.
- `snap` — toggles, quick UI feedback.

---

## Ambient background

The main window uses a live radial-gradient backdrop that shifts based on the current view's accent color:

```swift
struct AmbientBackground: View {
    let accent: Color
    @State private var phase: CGFloat = 0
}
```

Two overlapping radial gradients drift slowly (6-second ease-in-out loop) from opposing corners. The effect is subtle — it provides color identity without overwhelming the content.

Accent colors by view:

| View | Accent |
|---|---|
| Overview | Blue (#5C9EFF) |
| Category detail | Category's own accent |
| Developer Tools | Purple (#A673FF) |
| Schedule | Teal (#4DC9C9) |
| Permissions (granted) | Green (#5CD98C) |
| Permissions (denied) | Orange (#F38C4C) |

---

## Card system

### Category cards (Dashboard)

- Fixed height: 180 pt.
- Background: `.regularMaterial` with rounded rectangle (`cardCorner`).
- Stroke: gradient — accent-tinted on hover, subtle white on idle.
- Shadow: accent-colored on hover, neutral black otherwise.
- Scale: 1.015× on hover.
- Content: icon, title, hint, size (22 pt bold rounded), item count, mini progress bar.

### Detail panels (Category, DevTools, Schedule, Permissions)

- Background: `.regularMaterial` with `panelCorner`.
- Stroke: `white.opacity(0.06)` or accent-tinted when relevant.
- Padding: 20 pt.

### List rows (ItemRow)

- Horizontal padding: 16 pt, vertical: 10 pt.
- Background: `primary.opacity(0.04)` on hover.
- Content: checkbox toggle, filename, inline size bar, formatted size, reveal-in-Finder button.
- The entire row is tappable to toggle selection.

---

## Typography

All text uses San Francisco (system font) with specific sizing conventions:

| Role | Size | Weight | Design |
|---|---|---|---|
| Hero value | 36 pt | Bold | Rounded |
| Section title | 22 pt | Bold | — |
| Card title | 14–15 pt | Semibold | — |
| Body / hint | 12 pt | Regular | — |
| Caption / label | 9–11 pt | Medium/Semibold | Rounded for numbers |
| Monospace | 11–12 pt | — | Monospaced (command output) |

Numeric values (sizes, counts) use `.monospacedDigit()` and `.contentTransition(.numericText())` so they animate smoothly when values change.

---

## Color palette

Each category has a unique accent color defined as `Color(red:green:blue:)`:

| Category | Accent | Hex approx |
|---|---|---|
| User Caches | Blue | #5C9EFF |
| DerivedData | Orange | #FF9433 |
| Simulator Caches | Pink | #FF6BA6 |
| App Container Caches | Purple | #A873FF |
| Logs | Teal | #4DC9C9 |
| Trash | Red | #F35757 |
| Old Downloads | Green | #5CD98C |
| CocoaPods Cache | Coral | #F2614C |
| pip Cache | Sky | #4DA6F2 |
| Hugging Face Cache | Amber | #FFC733 |
| Ollama Models | Lime | #8CD973 |
| VS Code Storage | VS Code Blue | #339EF0 |
| JetBrains Caches | JetBrains Pink | #EE4D8C |

Developer tools use their own accent set (Docker blue, Brew amber, npm red, Rust orange).

---

## Iconography

All icons are SF Symbols:

- Category icons: 16 pt, semibold, in accent color.
- Sidebar icons: 12 pt, semibold, in accent or white (when selected).
- Header icons: 24 pt, semibold, white on gradient background.
- Action icons: 11–14 pt, weight matched to adjacent text.

Dynamic symbol effects are used throughout:
- `.pulse` for scanning / running states.
- `.bounce` for completion / support prompts.

---

## Interaction patterns

### Hover

- Cards: scale up slightly, shadow intensifies, stroke shifts to accent.
- Rows: subtle background fill appears.
- Buttons: shadow glows in accent color.

### Selection

- Sidebar: rounded rectangle background (`matchedGeometryEffect` for the selection indicator).
- Items: checkbox toggle with immediate animated feedback.
- Categories: tap navigates to detail with `.opacity + .move(edge: .trailing)` transition.

### Feedback

- **Action Bar:** Slides up from bottom when anything is selected. Spring animation.
- **Completion overlay:** Scale-in modal with backdrop dim. Green checkmark bounce.
- **Copy command:** Checkmark replaces copy icon for 1.5 seconds.

---

## Responsive layout

- Main window minimum: 880 × 600.
- Navigation split view with sidebar width: min 240, ideal 260, max 320.
- Dashboard grid: adaptive `LazyVGrid` with 220 pt minimum column width.
- Category detail list: capped at 200 visible items with overflow indicator.
- Menu bar: fixed 320 pt width, vertical stack.

---

## Accessibility notes

- `.help()` modifiers on icon buttons (reveal in Finder, copy output).
- Toggle labels hidden but functional for VoiceOver.
- `.contentShape(Rectangle())` on tappable rows ensures large hit areas.
- `.keyboardShortcut(.return)` on primary action buttons.
- Color is never the sole indicator — icons and labels accompany every accent use.

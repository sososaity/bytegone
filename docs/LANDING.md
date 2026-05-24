# Landing Page

`landing.html` is the single-file marketing page for Bytegone. It is self-contained — all CSS and JS are embedded. No build step required.

---

## File structure

```
clean-up/
  landing.html          # Single self-contained file
  screenshort/            # App screenshots (not referenced in HTML)
    Screenshot 2569-05-04 at 22.21.44.png
    Screenshot 2569-05-04 at 22.22.16.png
```

---

## Sections

| Section | ID | Purpose |
|---|---|---|
| Hero | — | Headline, stats, CTA, terminal mockup |
| Preview | `#preview` | Menu-bar popover mockup |
| Features | `#features` | 6 feature cards |
| Safety | `#safety` | Safety rules + gauge |
| Full App | `#app` | Full window mockup (split-pane) |
| Targets | `#targets` | Cleanup target list |
| Download | `#download` | Download card |
| Donate | — | Buy Me a Coffee link |

---

## Design system

### Colors

| Token | Value | Usage |
|---|---|---|
| `--bg-primary` | `#08080a` | Page background |
| `--bg-secondary` | `#0f0f12` | Alternate section bg |
| `--bg-card` | `#111114` | Cards, panels |
| `--text-primary` | `#f0f0f2` | Headings |
| `--text-secondary` | `#8a8a92` | Body text |
| `--text-muted` | `#5a5a62` | Captions, meta |
| `--accent` | `#00d9a3` | Primary CTA, highlights |
| `--accent-dim` | `rgba(0,217,163,0.1)` | Subtle accent bg |
| `--accent-glow` | `rgba(0,217,163,0.4)` | Shadows, glows |
| `--danger` | `#ff5f57` | Traffic light red |
| `--warning` | `#febc2e` | Traffic light yellow |
| `--info` | `#28c840` | Traffic light green |
| `--border` | `rgba(255,255,255,0.06)` | Dividers, strokes |

### Typography

| Font | Weight | Usage |
|---|---|---|
| Outfit | 300–800 | Headings, body, UI text |
| JetBrains Mono | 400–600 | Code, data values, stats |

### Background effects

- **Grid**: 60px CSS grid with `0.015` opacity white lines, radial mask fade at edges. Subtle mouse parallax (±10px).
- **Noise**: SVG feTurbulence overlay at `0.03` opacity.
- **Scanlines**: Repeating 4px lines at `0.03` opacity black.

---

## App UI mockups

The landing page includes two CSS-built mockups that mirror the SwiftUI app.

### 1. Menu-bar popover (`#preview`)

Maps to `MenuBarView.swift`:

| HTML Element | SwiftUI Component | Notes |
|---|---|---|
| `.menubar-popover` | `MenuBarView` body | 320px width, gradient backdrop |
| `.menubar-header` | `header` | Blue-purple gradient bg, "B" icon, subtitle |
| `.menubar-mini-gauge` | `MiniGauge` | 78px, 8px stroke, `#5C9EFF` accent |
| `.menubar-stats` | `StatLine` rows | RECLAIMABLE / FOUND / ITEMS |
| `.menubar-cat-row` | `TopCategoryRow` | Icon + name + bar + size |
| `.menubar-schedule` | `scheduleStrip` | Calendar icon + status text |
| `.menubar-btn.primary` | Scan button | Blue-purple gradient |
| `.menubar-btn.secondary` | Open window button | Subtle bg |
| `.menubar-quit` | Quit row | Power icon + ⌘Q shortcut |

### 2. Full window (`#app`)

Maps to `RootView.swift` + `DashboardView.swift` + `SidebarView.swift`:

| HTML Element | SwiftUI Component | Notes |
|---|---|---|
| `.app-full-window` | `NavigationSplitView` | 220px sidebar + detail pane |
| `.app-sidebar` | `SidebarView` | Ultra-thin material bg, section headers |
| `.app-sidebar-row` | `SidebarRow` | Icon (26px rounded) + title + size |
| `.app-sidebar-coffee` | `SupportSidebarRow` | Amber gradient icon |
| `.app-sidebar-scan-btn` | Footer scan button | Blue-purple gradient |
| `.app-detail` | `DashboardView` | `#151519` bg, ambient glow |
| `.app-gauge` | `HeroGauge` | 160px, 10px stroke, animated fill |
| `.app-card` | `CategoryCard` | 180px tall, `.regularMaterial` bg, hover lift |
| `.app-card-bar` | Mini progress bar | 3px, accent fill, proportional width |

---

## Color mapping

Category accent colors in the landing page must match `CleanupCategory.accent` in `Sources/Bytegone/Models.swift`:

| Category | SwiftUI `Color(...)` | Hex |
|---|---|---|
| User Caches | `0.36, 0.62, 1.00` | `#5C9EFF` |
| DerivedData | `1.00, 0.58, 0.20` | `#FF9433` |
| Simulator Caches | `1.00, 0.42, 0.65` | `#FF6BA6` |
| App Containers | `0.66, 0.45, 1.00` | `#A873FF` |
| Logs | `0.30, 0.79, 0.78` | `#4DC9C7` |
| Trash | `0.95, 0.34, 0.34` | `#F35757` |
| Old Downloads | `0.36, 0.85, 0.55` | `#5CD98C` |
| CocoaPods | `0.95, 0.38, 0.30` | `#F2614C` |
| pip Cache | `0.30, 0.65, 0.95` | `#4DA6F2` |
| Hugging Face | `1.00, 0.78, 0.20` | `#FFC733` |
| Ollama Models | `0.55, 0.85, 0.45` | `#8CD973` |
| VS Code | `0.20, 0.62, 0.94` | `#339EF0` |
| JetBrains | `0.93, 0.30, 0.55` | `#EE4D8C` |

---

## Donation link

The support section links to `SupportLink.url`:

```
https://buymeacoffee.com/pakortra
```

Defined in `Sources/Bytegone/SupportLink.swift`. Update both files together if the URL changes.

---

## Animations

| Animation | Target | Trigger |
|---|---|---|
| `fadeInUp` | Hero elements | Page load, staggered 0.2s delays |
| `fadeInDown` | Hero badge | Page load |
| `typeIn` | Terminal lines | Page load, staggered 0.2s delays |
| `gaugeFill` / `gaugeAppFill` | Gauge arcs | Page load / scroll reveal |
| `barGrow` | Progress bars | Scroll reveal, 0.8s delay |
| Counter scroll | `.stat-value[data-count]` | IntersectionObserver |
| Scroll reveal | `.reveal` | IntersectionObserver, `threshold: 0.1` |
| Parallax | `.bg-grid` | Mouse move |

---

## Responsive breakpoints

| Breakpoint | Changes |
|---|---|
| `max-width: 900px` | Safety section stacks vertically |
| `max-width: 768px` | Nav links hidden, hero stats stack, CTAs full-width, grids → 1 column |
| `max-width: 700px` | Full app mockup sidebar collapses |

---

## Maintenance notes

- Keep the landing page single-file. No external CSS/JS.
- When adding new categories, update both the mockup HTML and the color table above.
- The terminal mockup uses `&nbsp;` for spacing — preserve this for alignment.
- Emoji icons in the mockups are decorative; SF Symbols are used in the actual app.

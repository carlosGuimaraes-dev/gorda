---
trigger: always_on
---

# DESIGN SYSTEM — SEMANTIC TOKENS

## TASK

Create a complete Design System for my app in .md format, using exclusively the semantic tokens defined below.

## INSTRUCTIONS

* Analyze the context/screenshots of my app (if provided).
* Define the specific color palette mapped to each token.
* Document the main components with their states.
* Keep the document simple, practical, and implementable.

## DOCUMENT STRUCTURE

* App overview
* Color palette (real values → tokens)
* Documented components
* Usage examples

---

## Golden Rule

NEVER use arbitrary values (16px, #3B82F6, etc.) ALWAYS use the semantic tokens below. If you need a value that doesn't exist, ASK before inventing one.

---

## App Overview

This design system is for a clean, mobile-first Flutter application, inspired by SwiftUI's declarative and composable patterns but implemented in Dart/Flutter. It now incorporates elements reminiscent of the iOS UI Kit from Sketch (e.g., Liquid Glass UI with translucent, blurred, and refractive materials for components like buttons, alerts, and views), using new semantic tokens for glass effects to achieve dynamic, vibrant interfaces. The app features a minimalist interface with a primary accent color of #533afd (a vibrant purple-blue) for key actions and highlights, combined with light gray tones for neutrality, readability, and subtle hierarchy. It assumes a general-purpose app (e.g., productivity or social tool) without specific screenshots provided, emphasizing accessibility, consistency, and ease of implementation. Components are defined using semantic tokens for scalability across themes (e.g., light/dark modes). All styles are mobile-optimized, with desktop adaptations via responsive padding (e.g., increasing space-8 to space-12 on larger screens). Glass effects are applied selectively to interactive or overlay components for a modern, refractive feel, using BackdropFilter in Flutter for blur.

## Color Palette (Real Values → Tokens)

The palette maps concrete hex values to semantic tokens, focusing on the primary #533afd and light gray tones for a clean look. Contrasts ensure WCAG accessibility (e.g., text-primary on surface-page passes AA). New glass surfaces added for translucent effects.

### Text

* **text-primary**: #1f2937 (dark gray for titles and important text)
* **text-secondary**: #4b5563 (medium gray for captions and descriptions)
* **text-muted**: #9ca3af (light gray for placeholders and disabled text)
* **text-on-dark**: #ffffff (white for text on dark backgrounds)
* **text-on-brand**: #ffffff (white for text on primary brand color)

### Surfaces (Backgrounds)

* **surface-page**: #ffffff (white for main page background)
* **surface-section**: #f9fafb (very light gray for alternate sections)
* **surface-card**: #ffffff (white for cards)
* **surface-subtle**: #f3f4f6 (light gray for subtle emphasis areas)
* **surface-elevated**: #ffffff (white for elevated elements like modals)
* **surface-glass**: rgba(255, 255, 255, 0.8) (translucent glass for overlays and buttons)
* **surface-glass-prominent**: rgba(255, 255, 255, 0.9) (more opaque glass for prominent CTAs)
* **surface-glass-clear**: rgba(255, 255, 255, 0.6) (clearer glass for subtle backgrounds)

### Actions (Buttons, Links)

* **action-primary**: #533afd (primary accent for buttons and links)
* **action-primary-hover**: #4a34e3 (darker shade for hover)
* **action-primary-active**: #422eca (even darker for pressed)
* **action-secondary**: #e5e7eb (light gray for secondary buttons)
* **action-strong**: #1c1c1e (dark gray for high-conversion CTAs)
* **action-strong-hover**: #0e0e10 (darker for strong hover)

### Borders

* **border-default**: #d1d5db (medium gray for default borders)
* **border-subtle**: #e5e7eb (light gray for subtle borders)
* **border-focus**: #533afd (primary for focus rings)

### Status

* **status-success**: #22c55e (green for success states)
* **status-warning**: #f97316 (orange for warnings)
* **status-error**: #ef4444 (red for errors)

## Spacing

Spacing uses a consistent scale for gaps, paddings, and margins. Implement in Flutter as `const double space1 = 4.0;`, etc., or via a theme extension.

* **space-1**: 4px (minimum, e.g., inline icons)
* **space-2**: 8px (small gaps)
* **space-3**: 12px (medium internal gaps)
* **space-4**: 16px (default padding)
* **space-6**: 24px (card padding)
* **space-8**: 32px (gaps between sections)
* **space-12**: 48px (section padding)
* **space-16**: 64px (vertical padding for large sections)
* **space-20**: 80px (hero sections)

## Typography

Typography scales for readability, with mobile-first sizes (adapt +2-4px on desktop). Use Google Fonts like 'Inter' for a clean look. Implement as `TextStyle(fontSize: textBase, fontWeight: fontNormal)`.

### Sizes

* **text-xs**: 12px (badges, small labels)
* **text-sm**: 14px (secondary text, captions)
* **text-base**: 16px (body text)
* **text-lg**: 18px (highlighted text)
* **text-xl**: 20px (subtitles)
* **text-2xl**: 24px (card titles)
* **text-3xl**: 30px (section titles)
* **text-4xl**: 36px (main titles)
* **text-5xl**: 48px (hero headlines)

### Weights

* **font-normal**: 400 (body text)
* **font-medium**: 500 (slight emphasis)
* **font-semibold**: 600 (titles, buttons)
* **font-bold**: 700 (headlines)

## Borders and Shadows

### Border Radius

* **radius-sm**: 6px (inputs, badges)
* **radius-md**: 8px (buttons)
* **radius-lg**: 12px (small cards)
* **radius-xl**: 16px (large cards)
* **radius-2xl**: 24px (hero cards)
* **radius-full**: 9999px (avatars, pills)

### Shadows

Shadows use elevation in Flutter (e.g., `BoxShadow` or `Material(elevation)`). Values are CSS-like for reference, translatable to Flutter's `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: Offset(0,1))`.

* **shadow-sm**: 0 1px 2px 0 rgba(0,0,0,0.05) (subtle, for inputs/hovers)
* **shadow-md**: 0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -2px rgba(0,0,0,0.1) (medium, for cards/dropdowns)
* **shadow-lg**: 0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -4px rgba(0,0,0,0.1) (strong, for modals)
* **shadow-card**: shadow-md (for cards)
* **shadow-card-hover**: shadow-lg (for card hovers)
* **shadow-button-primary**: shadow-sm (for primary buttons)
* **shadow-glass**: 0 1px 3px rgba(0,0,0,0.05) (softer shadow for glass elements)

## Blur and Opacity (for Glass Effects)

New tokens for Liquid Glass UI effects, applied via Flutter's BackdropFilter (e.g., `ImageFilter.blur(sigmaX: blurSigmaMd, sigmaY: blurSigmaMd)` ) on translucent surfaces.

* **blur-sigma-sm**: 5 (subtle blur for light glass)
* **blur-sigma-md**: 10 (medium blur for standard glass)
* **blur-sigma-lg**: 20 (strong blur for prominent overlays)
* **opacity-glass**: 0.8 (default opacity for glass translucency)

## Documented Components

Components are defined with semantic tokens for consistency. Each interactive component includes mandatory states: default, hover, active/pressed, focus, disabled. Implement in Flutter using custom widgets (e.g., `class PrimaryButton extends StatelessWidget`) mimicking SwiftUI's modifier chain (e.g., `.background(actionPrimary).cornerRadius(radiusMd).shadow(shadowButtonPrimary)`). For glass effects, wrap components in ClipRRect with BackdropFilter and semi-transparent Container to simulate refractive, blurred materials similar to iOS Liquid Glass.

### Accordion

* Background: surface-glass
* Blur: blur-sigma-md
* Opacity: opacity-glass
* Header Text: text-primary, font-semibold, text-base
* Content Text: text-secondary, font-normal, text-base
* Border: border-default (bottom for headers)
* Radius: radius-sm
* Padding: space-4 for header, space-3 for content
* Icon: text-muted (chevron or similar)
* Shadow: shadow-glass
* States:
  * Default: as above
  * Hover: background surface-glass-prominent
  * Active/Pressed: background surface-glass-clear
  * Focus: border border-focus with 2px ring
  * Disabled: opacity 0.5, text text-muted

### Alert

* Background: surface-glass-clear
* Blur: blur-sigma-sm
* Opacity: opacity-glass
* Text: text-primary, font-normal, text-base
* Border: border-default (left accent with status-error/status-warning/status-success)
* Radius: radius-md
* Padding: space-4
* Icon: status-error/status-warning/status-success
* Shadow: shadow-glass
* No interactive states (static component)

### Alert Dialog

* Background: surface-glass
* Blur: blur-sigma-lg
* Opacity: opacity-glass
* Title Text: text-primary, font-semibold, text-xl
* Content Text: text-secondary, font-normal, text-base
* Border: none
* Radius: radius-lg
* Shadow: shadow-lg
* Padding: space-6
* Buttons: Use Primary/Secondary Button styles with glass variants
* States (for dialog overlay):
  * Default: opacity 1
  * Focus: border border-focus on focused elements
  * Disabled: opacity 0.5 for content

### Aspect Ratio

* No background or text (layout component)
* Use for images/videos to maintain ratios (e.g., 16:9)
* Padding: space-0 (none)
* No states (non-interactive)

### Avatar

* Background: surface-glass-clear
* Blur: blur-sigma-sm
* Text: text-primary, font-medium, text-base (initials)
* Border: border-subtle
* Radius: radius-full
* Size: space-8 (default diameter)
* Shadow: shadow-glass
* No states (static, but can hover for tooltips)

### Badge

* Background: surface-glass-prominent (tinted with action-secondary)
* Blur: blur-sigma-sm
* Text: text-primary, font-medium, text-xs
* Border: none
* Radius: radius-full
* Padding: space-2 horizontal, space-1 vertical
* Variants: Use status-success/warning/error for colored badges
* No interactive states

### Breadcrumb

* Text: text-secondary, font-normal, text-sm
* Separator: text-muted ("/" or chevron)
* Active: text-primary, font-medium
* Padding: space-2 between items
* No states (navigation component, optional glass wrapper if elevated)

### Button

* **Primary**:
  * Background: surface-glass tinted with action-primary
  * Blur: blur-sigma-md
  * Opacity: opacity-glass
  * Text: text-on-brand, font-semibold, text-base
  * Radius: radius-md
  * Shadow: shadow-glass
  * Padding: space-4 horizontal, space-3 vertical
  * States:
    * Default: as above
    * Hover: background surface-glass-prominent tinted with action-primary-hover, shadow-md
    * Active/Pressed: background surface-glass-clear tinted with action-primary-active, shadow-none
    * Focus: border border-focus with 2px ring
    * Disabled: opacity 0.5, text text-muted

* **Secondary**:
  * Background: surface-glass-clear
  * Blur: blur-sigma-sm
  * Opacity: opacity-glass
  * Text: text-primary, font-semibold, text-base
  * Border: border-default (1px)
  * Radius: radius-md
  * Shadow: shadow-glass
  * Padding: space-4 horizontal, space-3 vertical
  * States:
    * Default: as above
    * Hover: background surface-glass
    * Active/Pressed: background surface-glass-clear, border border-subtle
    * Focus: border border-focus with 2px ring
    * Disabled: opacity 0.5, border border-subtle, text text-muted

* **Strong (CTA)**:
  * Background: surface-glass-prominent tinted with action-strong
  * Blur: blur-sigma-md
  * Opacity: opacity-glass
  * Text: text-on-dark, font-bold, text-base
  * Radius: radius-md
  * Shadow: shadow-md
  * Padding: space-4 horizontal, space-3 vertical
  * States:
    * Default: as above
    * Hover: background surface-glass tinted with action-strong-hover, shadow-lg
    * Active/Pressed: background surface-glass-clear tinted with action-strong-hover, shadow-none
    * Focus: border border-focus with 2px ring
    * Disabled: opacity 0.5, text text-muted

### Button Group

* Background: surface-glass
* Blur: blur-sigma-sm
* Border: border-default
* Radius: radius-md (outer), radius-0 for inner buttons
* Padding: space-0 between buttons
* Buttons: Use Button styles, with shared borders
* States: Inherit from individual buttons

### Calendar

* Background: surface-glass
* Blur: blur-sigma-md
* Text: text-primary, font-normal, text-base (days)
* Border: border-subtle
* Radius: radius-md
* Padding: space-4
* Selected: background action-primary, text text-on-brand
* Today: border border-focus
* Shadow: shadow-glass
* States:
  * Default: as above
  * Hover: background surface-glass-prominent
  * Active/Pressed: background action-primary-active
  * Focus: border border-focus with 2px ring
  * Disabled: opacity 0.5, text text-muted

### Card

* Background: surface-glass
* Blur: blur-sigma-md
* Opacity: opacity-glass
* Radius: radius-xl
* Shadow: shadow-glass
* Padding: space-6
* Border: none
* States (for interactive cards):
  * Default: as above
  * Hover: shadow-card-hover
  * Active/Pressed: scale 0.98, shadow-md
  * Focus: border border-focus with 2px ring
  * Disabled: opacity 0.7, shadow-none

### Carousel

* Background: surface-glass-clear
* Blur: blur-sigma-lg
* Indicators: action-primary (active), text-muted (inactive)
* Radius: radius-lg
* Padding: space-4
* Items: Use Card or Image styles with glass
* States:
  * Default: opacity 1
  * Hover: indicators action-primary-hover
  * Focus: border border-focus on controls

### Chart

* Background: surface-glass
* Blur: blur-sigma-sm
* Lines/Bars: action-primary (primary data), status-success/warning/error for variants
* Text: text-secondary, text-xs
* Border: border-subtle
* Radius: radius-sm
* Padding: space-6
* No interactive states (static visualization)

### Checkbox

* Background: surface-glass-clear (unchecked), surface-glass tinted with action-primary (checked)
* Blur: blur-sigma-sm
* Border: border-default
* Radius: radius-sm
* Size: space-4
* Checkmark: text-on-brand
* States:
  * Default: as above
  * Hover: border border-focus
  * Active/Pressed: background action-primary-active
  * Focus: border border-focus with 2px ring
  * Disabled: opacity 0.5, border border-subtle

### Collapsible

* Background: surface-glass
* Blur: blur-sigma-md
* Header Text: text-primary, font-semibold, text-base
* Content: text-secondary, font-normal, text-base
* Border: border-subtle (bottom)
* Padding: space-4
* States: Similar to Accordion

### Combobox

* Background: surface-glass
* Blur: blur-sigma-sm
* Text: text-primary, text-base
* Border: border-default
* Radius: radius-sm
* Padding: space-4
* Dropdown: surface-glass, blur-sigma-md, shadow-md
* States: Similar to Select

### Command

* Background: surface-glass-prominent
* Blur: blur-sigma-md
* Text: text-primary, text-base
* Border: border-subtle
* Radius: radius-md
* Shadow: shadow-glass
* Padding: space-4
* States:
  * Hover: background surface-glass-clear
  * Active: background action-primary, text text-on-brand
  * Focus: border border-focus

### Context Menu

* Background: surface-glass
* Blur: blur-sigma-lg
* Text: text-primary, text-base
* Border: border-subtle
* Radius: radius-md
* Shadow: shadow-lg
* Padding: space-3
* Items: Hover background surface-glass-prominent
* States: Similar to Dropdown Menu

### Data Table

* Background: surface-glass-clear
* Blur: blur-sigma-sm
* Header Text: text-primary, font-semibold, text-sm
* Cell Text: text-secondary, font-normal, text-base
* Border: border-subtle (rows)
* Radius: radius-sm
* Padding: space-4 per cell
* States (for sortable headers):
  * Hover: background surface-glass
  * Active: text text-primary, icon action-primary

### Date Picker

* Background: surface-glass
* Blur: blur-sigma-md
* Text: text-primary, text-base
* Border: border-default
* Radius: radius-sm
* Padding: space-4
* Calendar: Inherit from Calendar
* States: Similar to Input

### Dialog

* Background: surface-glass
* Blur: blur-sigma-lg
* Title: text-primary, font-semibold, text-xl
* Content: text-secondary, text-base
* Radius: radius-lg
* Shadow: shadow-glass
* Padding: space-6
* States: Similar to Alert Dialog

### Direction

* Assuming directional layout (e.g., RTL/LTR support)
* No specific styles, use system defaults with tokens for padding/margins
* No states

### Drawer

* Background: surface-glass-prominent
* Blur: blur-sigma-lg
* Text: text-primary
* Border: border-subtle (edge)
* Radius: radius-0 (full height)
* Shadow: shadow-md
* Padding: space-8
* States:
  * Default: translateX(0)
  * Focus: elements with border-focus

### Dropdown Menu

* Trigger: Use Button secondary style with glass
* Menu Background: surface-glass
* Blur: blur-sigma-md
* Item Text: text-primary, text-base
* Border: border-subtle
* Radius: radius-md
* Shadow: shadow-glass
* Padding: space-3 per item
* States:
  * Default: opacity 1
  * Hover (item): background surface-glass-prominent
  * Active: background action-primary, text text-on-brand
  * Focus: border border-focus
  * Disabled: opacity 0.5

### Empty

* Background: surface-glass-clear
* Blur: blur-sigma-sm
* Text: text-muted, text-lg
* Icon: text-muted
* Padding: space-12
* No states (placeholder component)

### Field

* Assuming form field wrapper
* Label: text-secondary, text-sm
* Content: Inherit from Input/Select with glass
* Padding: space-2 bottom for label
* No states

### Hover Card

* Background: surface-glass
* Blur: blur-sigma-md
* Text: text-primary, text-base
* Border: border-subtle
* Radius: radius-lg
* Shadow: shadow-glass
* Padding: space-4
* Trigger: On hover, delay 300ms
* No interactive states beyond hover trigger

### Input

* Background: surface-glass-clear
* Blur: blur-sigma-sm
* Border: border-default (1px)
* Radius: radius-sm
* Padding: space-4
* Text: text-primary, text-base, font-normal
* Placeholder: text-muted, text-sm
* States:
  * Default: as above
  * Hover: border border-default
  * Active/Pressed: border border-focus (2px)
  * Focus: border border-focus with shadow-sm ring
  * Disabled: border border-subtle, text text-muted, opacity 0.5

### Input Group

* Background: surface-glass-clear
* Blur: blur-sigma-sm
* Border: border-default
* Radius: radius-sm (outer), radius-0 for inner inputs
* Padding: space-0 between inputs
* States: Inherit from Input

### Input OTP

* Background: surface-glass-clear
* Blur: blur-sigma-sm
* Border: border-default
* Radius: radius-sm
* Padding: space-2 between digits
* Text: text-primary, text-lg
* States: Similar to Input

### Item

* Assuming list item
* Text: text-primary, text-base
* Padding: space-4
* Hover: background surface-glass-prominent
* States: Similar to Dropdown Menu items

### Kbd

* Background: surface-glass-clear
* Blur: blur-sigma-sm
* Text: text-secondary, text-xs, font-medium
* Border: border-default
* Radius: radius-sm
* Padding: space-1 horizontal, space-1 vertical
* No states (inline keyboard shortcut)

### Label

* Text: text-secondary, text-sm, font-medium
* Padding: space-2 bottom
* No states (form label)

### Menubar

* Background: surface-glass
* Blur: blur-sigma-md
* Text: text-primary, font-semibold, text-base
* Border: border-subtle (bottom)
* Radius: radius-0
* Padding: space-4
* States:
  * Hover: background surface-glass-prominent
  * Active: text action-primary
  * Focus: border border-focus

### Native Select

* Background: surface-glass
* Blur: blur-sigma-sm
* Text: text-primary, text-base
* Border: border-default
* Radius: radius-sm
* Padding: space-4
* States: Similar to Select

### Navigation Menu

* Background: surface-glass-clear
* Blur: blur-sigma-sm
* Text: text-primary, text-base
* Border: none
* Padding: space-4
* Active: text action-primary, border-bottom border-focus
* States:
  * Hover: text action-primary-hover
  * Focus: border border-focus

### Pagination

* Background: surface-glass
* Blur: blur-sigma-sm
* Text: text-primary, text-base
* Border: border-subtle
* Radius: radius-md
* Padding: space-2
* Active Page: background action-primary, text text-on-brand
* States:
  * Hover: background surface-glass-prominent
  * Disabled: opacity 0.5

### Popover

* Background: surface-glass
* Blur: blur-sigma-md
* Text: text-primary, text-base
* Border: border-subtle
* Radius: radius-md
* Shadow: shadow-glass
* Padding: space-4
* No interactive states (positioned overlay)

### Progress

* Background: surface-glass-clear (track)
* Blur: blur-sigma-sm
* Fill: action-primary (bar)
* Radius: radius-full
* Height: space-2
* No states (static indicator)

### Radio Group

* Radio: Similar to Checkbox, but radius-full with glass background
* Label: text-primary, text-base
* Padding: space-3 between items
* States: Similar to Checkbox

### Resizable

* Handle: border-default, background surface-glass-clear
* Blur: blur-sigma-sm
* Width: space-1 (handle size)
* States:
  * Hover: background action-primary-hover
  * Active: background action-primary-active

### Scroll Area

* Background: transparent
* Scrollbar: surface-glass-clear (track), action-primary (thumb)
* Blur: blur-sigma-sm for thumb
* Radius: radius-sm for thumb
* No states (utility component)

### Select

* Background: surface-glass
* Blur: blur-sigma-sm
* Text: text-primary, text-base
* Border: border-default
* Radius: radius-sm
* Padding: space-4
* Dropdown: surface-glass, shadow-md
* States:
  * Default: as above
  * Hover: border border-focus
  * Focus: border border-focus with 2px ring
  * Disabled: opacity 0.5

### Separator

* Background: border-subtle (horizontal/vertical line)
* Height/Width: 1px
* No radius or padding
* No states

### Sheet

* Background: surface-glass-prominent
* Blur: blur-sigma-lg
* Radius: radius-xl (top for bottom sheets)
* Shadow: shadow-glass
* Padding: space-8
* States: Similar to Drawer

### Sidebar

* Background: surface-glass
* Blur: blur-sigma-md
* Text: text-primary
* Border: border-subtle (right)
* Padding: space-8
* Width: 256px (desktop), full on mobile
* States: Hover on items background surface-glass-prominent

### Skeleton

* Background: surface-glass-clear (animated shimmer)
* Blur: blur-sigma-sm
* Radius: radius-md
* No text or states (loading placeholder)

### Slider

* Track: surface-glass-clear
* Blur: blur-sigma-sm
* Thumb: action-primary, radius-full
* Fill: action-primary
* Size: space-2 height
* States:
  * Hover: thumb shadow-sm
  * Active: thumb scale 1.2
  * Focus: thumb border border-focus
  * Disabled: opacity 0.5

### Sonner

* Background: surface-glass
* Blur: blur-sigma-md
* Text: text-primary
* Radius: radius-md
* Shadow: shadow-glass
* Padding: space-4
* No states

### Spinner

* Color: action-primary
* Size: space-6
* No background or states (loading indicator)

### Switch

* Background: surface-glass-clear (off), surface-glass tinted with action-primary (on)
* Blur: blur-sigma-sm
* Thumb: surface-card, radius-full
* Border: border-default
* Radius: radius-full
* Size: space-6 width, space-3 height
* States:
  * Hover: shadow-sm
  * Focus: border border-focus
  * Disabled: opacity 0.5

### Table

* Similar to Data Table, without interactivity, with glass background

### Tabs

* Tab Text: text-secondary, font-medium, text-base
* Active: text-primary, border-bottom border-focus
* Background: surface-glass-clear
* Blur: blur-sigma-sm
* Border: border-subtle (bottom)
* Padding: space-4
* States:
  * Hover: text-primary
  * Focus: border border-focus

### Textarea

* Background: surface-glass-clear
* Blur: blur-sigma-sm
* Border: border-default
* Radius: radius-sm
* Padding: space-4
* Text: text-primary, text-base
* States: Similar to Input

### Toast

* Background: surface-glass
* Blur: blur-sigma-md
* Text: text-primary, text-base
* Border: none
* Radius: radius-md
* Shadow: shadow-glass
* Padding: space-4
* Variants: status-success/error/warning
* No states (transient)

### Toggle

* Background: surface-glass-clear (off), surface-glass tinted with action-primary (on)
* Blur: blur-sigma-sm
* Text/Icon: text-primary (off), text-on-brand (on)
* Border: border-default
* Radius: radius-md
* Padding: space-3
* States:
  * Hover: background action-primary-hover
  * Active: background action-primary-active
  * Focus: border border-focus
  * Disabled: opacity 0.5

### Toggle Group

* Similar to Button Group, with Toggle styles and glass effects

### Tooltip

* Background: surface-glass-prominent tinted with action-strong
* Blur: blur-sigma-md
* Text: text-on-dark, text-sm
* Border: none
* Radius: radius-sm
* Shadow: shadow-glass
* Padding: space-2
* No states (hover-triggered)

### Typography

* Use typography tokens directly (e.g., H1: text-4xl, font-bold, text-primary)
* Paragraph: text-base, font-normal, text-secondary
* No component-specific states

## Usage Examples

Examples in Flutter code, assuming a `DesignTokens` class/extension for tokens (e.g., `static const Color textPrimary = Color(0xff1f2937);`). Use `InkWell` or `GestureDetector` for states in custom widgets. For glass effects, use `ClipRRect` with `BackdropFilter`.

### Primary Button

```dart
import 'dart:ui';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const PrimaryButton({required this.label, required this.onPressed, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: DesignTokens.blurSigmaMd, sigmaY: DesignTokens.blurSigmaMd),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.space4, vertical: DesignTokens.space3),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceGlass.withOpacity(DesignTokens.opacityGlass), // Tinted with actionPrimary if needed
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 1, offset: Offset(0, 1))], // shadow-glass approx
            ),
            child: Text(label, style: TextStyle(color: DesignTokens.textOnBrand, fontSize: DesignTokens.textBase, fontWeight: DesignTokens.fontSemibold)),
          ),
        ),
      ),
    );
  }
}

// Usage: PrimaryButton(label: 'Submit', onPressed: () {});
```

### Card

```dart
import 'dart:ui';

class AppCard extends StatelessWidget {
  final Widget child;

  const AppCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DesignTokens.blurSigmaMd, sigmaY: DesignTokens.blurSigmaMd),
        child: Container(
          decoration: BoxDecoration(
            color: DesignTokens.surfaceGlass.withOpacity(DesignTokens.opacityGlass),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))], // shadow-glass approx
          ),
          padding: EdgeInsets.all(DesignTokens.space6),
          child: child,
        ),
      ),
    );
  }
}

// Usage: AppCard(child: Text('Card Content', style: TextStyle(color: DesignTokens.textPrimary, fontSize: DesignTokens.text2xl)));
```

### Input

```dart
import 'dart:ui';

class AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;

  const AppTextField({required this.hint, this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DesignTokens.blurSigmaSm, sigmaY: DesignTokens.blurSigmaSm),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: DesignTokens.textMuted, fontSize: DesignTokens.textSm),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              borderSide: BorderSide(color: DesignTokens.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              borderSide: BorderSide(color: DesignTokens.borderFocus, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              borderSide: BorderSide(color: DesignTokens.borderDefault),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              borderSide: BorderSide(color: DesignTokens.borderSubtle),
            ),
            fillColor: DesignTokens.surfaceGlassClear.withOpacity(DesignTokens.opacityGlass),
            filled: true,
            contentPadding: EdgeInsets.all(DesignTokens.space4),
          ),
          style: TextStyle(color: DesignTokens.textPrimary, fontSize: DesignTokens.textBase, fontWeight: DesignTokens.fontNormal),
        ),
      ),
    );
  }
}

// Usage: AppTextField(hint: 'Enter email');
```

### Accordion (Example Addition)

```dart
import 'dart:ui';

class AppAccordion extends StatefulWidget {
  final String title;
  final Widget content;

  const AppAccordion({required this.title, required this.content});

  @override
  _AppAccordionState createState() => _AppAccordionState();
}

class _AppAccordionState extends State<AppAccordion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusSm)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: DesignTokens.blurSigmaMd, sigmaY: DesignTokens.blurSigmaMd),
              child: Container(
                padding: EdgeInsets.all(DesignTokens.space4),
                decoration: BoxDecoration(
                  color: DesignTokens.surfaceGlass.withOpacity(DesignTokens.opacityGlass),
                  border: Border(bottom: BorderSide(color: DesignTokens.borderDefault)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.title, style: TextStyle(color: DesignTokens.textPrimary, fontSize: DesignTokens.textBase, fontWeight: DesignTokens.fontSemibold)),
                    Icon(_isExpanded ? Icons.chevron_up : Icons.chevron_down, color: DesignTokens.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: EdgeInsets.all(DesignTokens.space3),
            child: widget.content,
          ),
      ],
    );
  }
}

// Usage: AppAccordion(title: 'Section', content: Text('Details', style: TextStyle(color: DesignTokens.textSecondary)));
```

### Alert (Example Addition)

```dart
import 'dart:ui';

class AppAlert extends StatelessWidget {
  final String message;
  final Color accentColor; // e.g., statusError

  const AppAlert({required this.message, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DesignTokens.blurSigmaSm, sigmaY: DesignTokens.blurSigmaSm),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceGlassClear.withOpacity(DesignTokens.opacityGlass),
            border: Border(left: BorderSide(color: accentColor, width: 4.0)),
          ),
          child: Text(message, style: TextStyle(color: DesignTokens.textPrimary, fontSize: DesignTokens.textBase)),
        ),
      ),
    );
  }
}

// Usage: AppAlert(message: 'Error occurred', accentColor: DesignTokens.statusError);
```
---

## MANDATORY STATES

Every interactive component MUST have:

1. **Default**: normal state
2. **Hover**: visual feedback on mouseover
3. **Active/Pressed**: feedback on click
4. **Focus**: visible ring for accessibility
5. **Disabled**: reduced opacity, cursor not-allowed

---

## FINAL RULES

1.  Never invent values. Use only tokens.
2.  If a token doesn't exist for what you need, ask.
3.  Maintain consistency: same component = same tokens always.
4.  Mobile-first: start with mobile, adapt for desktop.

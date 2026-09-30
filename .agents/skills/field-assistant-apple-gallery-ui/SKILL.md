---
name: field-assistant-apple-gallery-ui
description: Apply the Apple product-gallery visual language to the AI Field Assistant Flutter app while keeping it practical, accessible, and clear on mobile. Use for screen redesigns, shared visual systems, and app branding; do not use it to change product behavior.
metadata:
  short-description: Apple gallery inspired mobile UI for AI Field Assistant
---

# AI Field Assistant gallery inspired UI

Use this skill when changing the visual design of the existing Flutter app or its app mark. The reference describes a spacious Apple product gallery for a foldable phone. Translate its visual principles into a Vietnamese field-work tool; do not copy the store layout, shopping controls, oversized desktop hero, or irrelevant foldable-phone imagery.

## Visual language

- Use Gallery White `#ffffff` and Studio Mist `#f5f5f7` as the main surfaces. Use Paper Frost `#fafafc` for restrained selected or secondary surfaces, Hairline Silver `#d6d6d6` for separators, and Control Gray `#e6e6e8` for disabled controls.
- Use Ink `#1d1d1f` for primary text and icons, Slate `#707070` for secondary copy, Steel `#86868b` for fine control outlines, Apple Blue `#0066cc` for links and text actions, and Pricing Blue `#0071e3` sparingly for compact emphasis. Keep status colors semantic and restrained.
- Prefer the platform's native text family (Roboto on Android) over bundling Apple's proprietary fonts. Translate the reference type roles to phone sizes: section headings around 28–34sp, body 16–17sp with comfortable line spacing, and labels 12–14sp. Keep weights near 400, 500, and 600; reserve display size for short headings.
- Work on a 4dp spacing grid. Keep 16–24dp page gutters and clear grouping. Use 28dp corners for feature cards, 20–28dp for image frames, and pill shapes for primary/secondary buttons. Multi-line inputs remain rounded rectangles, not pills.
- Separate surfaces with white against Studio Mist and occasional 1dp hairlines. Avoid gradients and decorative drop shadows. Use large white space around meaningful content, not empty hero space that pushes a task below the fold.
- Make the app mark simple and legible at launcher size. Reuse its shapes/colors in the in-app brand mark. Do not use the Apple logo or copy a third-party product logo.

## Mobile interaction requirements

- Preserve the app's existing Vietnamese labels, fields, navigation, IDs, callbacks, validation, loading, errors, retries, review confirmation, local persistence, and PDF actions. A visual change must not imply that AI, storage, App Check, or export has been newly verified.
- Keep controls usable on narrow phones and with large system text. Prefer 48dp or larger touch targets, responsive wrapping, scrolling, clear focus/disabled states, and sufficient text contrast.
- Keep primary actions visually dominant, secondary actions outlined or text based, and status information readable without relying on color alone.
- Avoid dense card stacks when typography, spacing, and a light section surface can provide the hierarchy. Use repeated cards only when they help users scan distinct report fields or records.

## Workflow

1. Inspect the existing screen states and interaction paths before restyling them.
2. Define shared colors, type roles, shapes, and control treatments once in the Flutter theme; reuse small brand or status widgets where appropriate.
3. Apply the system consistently to the app shell, input, draft/review, history, detail, empty/error/loading states, dialogs, and launcher branding in the requested scope.
4. Keep data/service/repository behavior unchanged. Update UI tests only when a meaningful interaction contract changes, and retain stable keys where possible.
5. Format and analyze the changed Flutter code. Verify Android resources/build or device appearance only when the environment and authorization allow; report what was not checked.

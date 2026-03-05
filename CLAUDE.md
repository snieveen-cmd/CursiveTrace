# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

CursiveTrace is an iOS app (SwiftUI + PencilKit) that teaches cursive handwriting. Users trace over letter and word guides; a scoring engine compares their strokes to the reference paths and awards 1–3 stars.

## Git Workflow

After completing any meaningful unit of work, commit and push to GitHub so progress is never lost:

```bash
git add -A
git commit -m "<type>: <short description>"
git push
```

Use conventional commit prefixes: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`. Keep the subject line under 72 characters and describe *what* changed and *why* when it isn't obvious. Commit at logical checkpoints — after adding a feature, fixing a bug, or making a self-contained change — rather than accumulating many unrelated edits in one commit.

## Build & Run

Open `CursiveTrace.xcodeproj` in Xcode and run on an iPad or iPhone simulator/device. There is no package manager (no SPM, CocoaPods, or Carthage). All dependencies are Apple frameworks (SwiftUI, PencilKit, UIKit).

There are no unit test targets in the current project.

## Architecture

Two `@StateObject` singletons are injected at the root and available as `@EnvironmentObject` throughout the tree:

- **`AppEnvironment`** — owns `NavigationPath` and exposes `navigateTo(_:)`, `pop()`, `popToRoot()`. All navigation goes through this object.
- **`ProgressStore`** — persists `UserProgress` to `UserDefaults` as JSON. Exposes `record(itemID:isWord:stars:)`, `bestStars(for:isWord:)`, and `isUnlocked(_:)`.

### Data flow for a tracing session

1. `HomeView` hosts the `NavigationStack` and routes `.tracing(itemID:)` destinations to `TracingContainerView<T: TracingItem>`.
2. `TracingContainerView` layers `GuideOverlayView` (reference path in SwiftUI/CGPath) over `TracingCanvasView` (a `PKCanvasView` UIViewRepresentable).
3. On submit, `PathRenderer.bezierPath(from:fittingIn:)` scales the stored `LetterPath` segments to the actual canvas rect, then `ScoringEngine.score(drawing:referencePaths:)` compares sampled student points to sampled reference points in two stages (coverage ≥ 65%, then mean deviation for star tier).
4. `ScoreView` is presented full-screen; the result is persisted via `ProgressStore`.

### Models

- **`TracingItem`** protocol — shared by `Letter` and `CursiveWord`. Both load their data lazily from bundle JSON.
- **`LetterPath`** / `PathSegment` — Codable structs wrapping CGPoint/CGSize that describe the reference glyph as moveTo/lineTo/curveTo segments with a `viewBox`.
- **`StarRating`** — `Int`-backed enum (.none=0, .one=1, .two=2, .three=3) with `Comparable`.
- **`UnlockRule`** — letters unlock sequentially (each requires the previous); words require all 26 letters completed at ≥ 1 star.

### Resources

- `cursive_paths.json` — array of `LetterPath` objects, one per lowercase letter (`a`–`z`).
- `words.json` — array of `{"word": "..."}` objects. Each word's paths are assembled from `cursive_paths.json` by character lookup; a word is silently dropped if any character is missing.

### Key scoring thresholds (ScoringEngine.swift)

- Coverage threshold: 22 pt radius; must cover > 65% of reference points or → 1 star.
- Mean deviation < 15 pt → 3 stars; < 28 pt → 2 stars; else → 1 star.

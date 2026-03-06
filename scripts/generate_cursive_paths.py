#!/usr/bin/env python3
"""
Generate cursive_paths.json from Dancing Script font.

The output is a JSON array of LetterPath objects matching the schema
consumed by CursiveTrace's PathRenderer.swift. Each letter a-z gets
one entry whose segments describe the largest contour of the glyph,
normalized to a 200x300 viewBox.
"""

import json
import math
import os
from fontTools.ttLib import TTFont
from fontTools.pens.recordingPen import RecordingPen

FONT_PATH = os.path.join(os.path.dirname(__file__), "DancingScript-Regular.otf")
OUTPUT_PATH = os.path.join(
    os.path.dirname(__file__),
    "..",
    "CursiveTrace",
    "Resources",
    "cursive_paths.json",
)

VIEWBOX_W = 200
VIEWBOX_H = 300
PAD_X = 10   # minimum horizontal padding
PAD_Y = 20   # minimum vertical padding (extra at top for ascenders)


def quad_to_cubic(p0, p1, p2):
    """Convert a quadratic Bézier (p0 on-curve, p1 off-curve, p2 on-curve)
    to a cubic Bézier (p0, c1, c2, p2)."""
    c1 = (
        p0[0] + 2 / 3 * (p1[0] - p0[0]),
        p0[1] + 2 / 3 * (p1[1] - p0[1]),
    )
    c2 = (
        p2[0] + 2 / 3 * (p1[0] - p2[0]),
        p2[1] + 2 / 3 * (p1[1] - p2[1]),
    )
    return c1, c2


def recording_to_cubic_contours(operations, ascender):
    """
    Convert RecordingPen operations to a list of contours.
    Each contour is a list of dicts: {type, point, control1, control2}
    with y already flipped (ascender - y).

    Handles moveTo, lineTo, curveTo (cubic), qCurveTo (quadratic), endPath/closePath.
    """
    contours = []
    current = None
    current_point = None

    def flip(x, y):
        return (x, ascender - y)

    for op, args in operations:
        if op == "moveTo":
            if current is not None:
                contours.append(current)
            current = []
            pt = flip(*args[0])
            current.append(
                {"type": "moveTo", "point": {"x": pt[0], "y": pt[1]},
                 "control1": None, "control2": None}
            )
            current_point = pt

        elif op == "lineTo":
            pt = flip(*args[0])
            current.append(
                {"type": "lineTo", "point": {"x": pt[0], "y": pt[1]},
                 "control1": None, "control2": None}
            )
            current_point = pt

        elif op == "curveTo":
            # Cubic — args are (c1, c2, endpt)
            c1 = flip(*args[0])
            c2 = flip(*args[1])
            pt = flip(*args[2])
            current.append(
                {"type": "curveTo", "point": {"x": pt[0], "y": pt[1]},
                 "control1": {"x": c1[0], "y": c1[1]},
                 "control2": {"x": c2[0], "y": c2[1]}}
            )
            current_point = pt

        elif op == "qCurveTo":
            # Quadratic — may be a spline with multiple off-curve points.
            # fontTools expands TrueType splines so that there may be
            # implicit on-curve points between consecutive off-curve points.
            # We handle this by iterating through pairs.
            pts = [flip(*a) for a in args]
            # pts[-1] is the on-curve endpoint; all others are off-curve.
            # For a single quad segment: pts = [off, on]
            # For an implied spline: pts = [off, off, ..., on]
            # Convert each segment to cubic.
            prev = current_point
            off_curves = pts[:-1]
            on_curve = pts[-1]

            if len(off_curves) == 1:
                c1, c2 = quad_to_cubic(prev, off_curves[0], on_curve)
                current.append(
                    {"type": "curveTo", "point": {"x": on_curve[0], "y": on_curve[1]},
                     "control1": {"x": c1[0], "y": c1[1]},
                     "control2": {"x": c2[0], "y": c2[1]}}
                )
                current_point = on_curve
            else:
                # Decompose spline into individual segments
                expanded = []
                for i in range(len(off_curves) - 1):
                    q0 = prev if i == 0 else expanded[-1]
                    q1 = off_curves[i]
                    q2 = (
                        ((off_curves[i][0] + off_curves[i + 1][0]) / 2,
                         (off_curves[i][1] + off_curves[i + 1][1]) / 2)
                    )
                    expanded.append(q2)
                    c1, c2 = quad_to_cubic(q0, q1, q2)
                    current.append(
                        {"type": "curveTo", "point": {"x": q2[0], "y": q2[1]},
                         "control1": {"x": c1[0], "y": c1[1]},
                         "control2": {"x": c2[0], "y": c2[1]}}
                    )
                    current_point = q2
                # Last segment to on_curve
                q0 = current_point
                q1 = off_curves[-1]
                c1, c2 = quad_to_cubic(q0, q1, on_curve)
                current.append(
                    {"type": "curveTo", "point": {"x": on_curve[0], "y": on_curve[1]},
                     "control1": {"x": c1[0], "y": c1[1]},
                     "control2": {"x": c2[0], "y": c2[1]}}
                )
                current_point = on_curve

        elif op in ("endPath", "closePath"):
            if current is not None:
                contours.append(current)
            current = None
            current_point = None

    if current is not None:
        contours.append(current)

    return contours


def contour_bbox(contour):
    """Return (min_x, min_y, max_x, max_y) bounding box of a contour."""
    xs = [seg["point"]["x"] for seg in contour]
    ys = [seg["point"]["y"] for seg in contour]
    # Include control points for a tighter estimate
    for seg in contour:
        for key in ("control1", "control2"):
            if seg[key]:
                xs.append(seg[key]["x"])
                ys.append(seg[key]["y"])
    return min(xs), min(ys), max(xs), max(ys)


def bbox_area(bbox):
    x0, y0, x1, y1 = bbox
    return (x1 - x0) * (y1 - y0)


def normalize_contour(contour, scale, ox, oy):
    """Apply uniform scale + offset to all points in a contour (in-place copy)."""
    result = []
    for seg in contour:
        def tx(pt):
            return {"x": round(pt["x"] * scale + ox, 2),
                    "y": round(pt["y"] * scale + oy, 2)}

        new_seg = {
            "type": seg["type"],
            "point": tx(seg["point"]),
            "control1": tx(seg["control1"]) if seg["control1"] else None,
            "control2": tx(seg["control2"]) if seg["control2"] else None,
        }
        result.append(new_seg)
    return result


def process_letter(char, glyph_set, ascender):
    pen = RecordingPen()
    glyph_set[char].draw(pen)
    contours = recording_to_cubic_contours(pen.value, ascender)

    if not contours:
        raise ValueError(f"No contours found for '{char}'")

    # Keep the largest contour by bounding-box area (drops dot on i/j, accents, etc.)
    best = max(contours, key=lambda c: bbox_area(contour_bbox(c)))

    # Compute bbox of the chosen contour
    x0, y0, x1, y1 = contour_bbox(best)
    glyph_w = x1 - x0
    glyph_h = y1 - y0

    if glyph_w == 0 or glyph_h == 0:
        raise ValueError(f"Zero-size glyph for '{char}'")

    max_w = VIEWBOX_W - 2 * PAD_X
    max_h = VIEWBOX_H - 2 * PAD_Y
    scale = min(max_w / glyph_w, max_h / glyph_h)

    # Center horizontally and vertically with padding
    ox = (VIEWBOX_W - glyph_w * scale) / 2 - x0 * scale
    oy = (VIEWBOX_H - glyph_h * scale) / 2 - y0 * scale

    normalized = normalize_contour(best, scale, ox, oy)
    return normalized


def main():
    font = TTFont(FONT_PATH)
    glyph_set = font.getGlyphSet()

    # Get ascender for y-flip reference
    ascender = font["hhea"].ascent  # typically ~800 for 1000 UPM

    letters = []
    for char in "abcdefghijklmnopqrstuvwxyz":
        try:
            segments = process_letter(char, glyph_set, ascender)
            letters.append({
                "character": char,
                "viewBox": {"width": VIEWBOX_W, "height": VIEWBOX_H},
                "segments": segments,
            })
            print(f"  {char}: {len(segments)} segments")
        except Exception as e:
            print(f"  ERROR for '{char}': {e}")

    with open(OUTPUT_PATH, "w") as f:
        json.dump(letters, f, indent=2)

    print(f"\nWrote {len(letters)} letters to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()

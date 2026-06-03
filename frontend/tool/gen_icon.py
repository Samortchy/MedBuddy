"""Generate the MedBuddy app icon PNG (teal, 'MED' + heartbeat pulse)."""
import os
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
os.makedirs(OUT_DIR, exist_ok=True)
OUT = os.path.join(OUT_DIR, "app_icon.png")

TEAL = (13, 148, 136, 255)       # #0D9488
TEAL_DARK = (15, 118, 110, 255)  # #0F766E
WHITE = (255, 255, 255, 255)

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# Vertical-ish two-tone background via two rounded rects (simple gradient feel).
d.rounded_rectangle([0, 0, SIZE, SIZE], radius=200, fill=TEAL_DARK)
d.rounded_rectangle([0, 0, SIZE, int(SIZE * 0.62)], radius=200, fill=TEAL)

# Heartbeat / pulse line (scaled from a 64-unit layout).
pts = [(8, 27), (21, 27), (26, 15), (33, 39), (39, 27), (56, 27)]
scaled = [(x / 64 * SIZE, y / 64 * SIZE) for (x, y) in pts]
d.line(scaled, fill=WHITE, width=30, joint="curve")
# round the segment ends
for (x, y) in (scaled[0], scaled[-1]):
    r = 15
    d.ellipse([x - r, y - r, x + r, y + r], fill=WHITE)

# "MED" wordmark.
font = None
for path in (
    "C:/Windows/Fonts/arialbd.ttf",
    "C:/Windows/Fonts/Arialbd.ttf",
    "C:/Windows/Fonts/arial.ttf",
):
    if os.path.exists(path):
        font = ImageFont.truetype(path, 300)
        break
if font is None:
    font = ImageFont.load_default()

d.text((SIZE / 2, SIZE * 0.64), "MED", font=font, fill=WHITE, anchor="mm")

img.save(OUT)
print("Saved:", os.path.abspath(OUT))

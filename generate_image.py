from PIL import Image, ImageDraw, ImageFilter
import os

print("Starting asset generation...")

# Define image size
width, height = 300, 300
size = (width, height)
assets_dir = "assets/images"

# Create the directory if it doesn't exist
os.makedirs(assets_dir, exist_ok=True)
print(f"Ensured directory exists: {assets_dir}")

# --- 1. Create sun.png ---
try:
    sun_img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(sun_img)

    # Draw a soft yellow circle in the center
    sun_color = (255, 215, 0, 200) # Yellow with some transparency
    radius = 40
    center = (width // 2, height // 2)

    draw.ellipse(
        [
            (center[0] - radius, center[1] - radius),
            (center[0] + radius, center[1] + radius)
        ],
        fill=sun_color
    )

    # Apply a heavy blur to create a glow
    sun_img = sun_img.filter(ImageFilter.GaussianBlur(radius=20))
    sun_path = os.path.join(assets_dir, "sun.png")
    sun_img.save(sun_path)
    print(f"Successfully generated: {sun_path}")

except Exception as e:
    print(f"Error generating sun.png: {e}")

# --- 2. Create shadow_logo.png ---
try:
    shadow_img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow_img)

    # Define 'W' logo points (simple, geometric)
    w_points = [
        (width * 25 // 100, height * 25 // 100),
        (width * 35 // 100, height * 75 // 100),
        (width * 50 // 100, height * 50 // 100),
        (width * 65 // 100, height * 75 // 100),
        (width * 75 // 100, height * 25 // 100)
    ]
    shadow_color = (50, 50, 50, 255) # Dark grey
    line_width = 20

    draw.line(w_points, fill=shadow_color, width=line_width, joint='miter')

    # Apply a blur to make it a soft shadow
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(radius=5))
    shadow_path = os.path.join(assets_dir, "shadow_logo.png")
    shadow_img.save(shadow_path)
    print(f"Successfully generated: {shadow_path}")

except Exception as e:
    print(f"Error generating shadow_logo.png: {e}")

# --- 3. Create logo.png ---
try:
    logo_img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(logo_img)

    # Faint color (black with very low opacity)
    faint_color = (0, 0, 0, 20)
    line_width = 20
    
    # Re-using w_points from above
    draw.line(w_points, fill=faint_color, width=line_width, joint='miter')
    
    logo_path = os.path.join(assets_dir, "logo.png")
    logo_img.save(logo_path)
    print(f"Successfully generated: {logo_path}")

except Exception as e:
    print(f"Error generating logo.png: {e}")

print("\nAsset generation complete.")
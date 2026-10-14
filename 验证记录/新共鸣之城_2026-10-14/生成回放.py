from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parent
labels = ["露台", "移除露台", "撤销：露台恢复", "重做：再次移除"]
font = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 24)
frames = []
for index, label in enumerate(labels, 1):
    shot = Image.open(root / f"final_edit_0{index}.png").convert("RGB")
    detail = shot.crop((375, 265, 1030, 650)).resize((786, 462), Image.Resampling.LANCZOS)
    frame = Image.new("RGB", (786, 512), "#f6f0e1")
    frame.paste(detail, (0, 50))
    ImageDraw.Draw(frame).text((22, 10), label, font=font, fill="#284f46")
    frames.append(frame)
frames[0].save(root / "编辑回放.gif", save_all=True, append_images=frames[1:], duration=1400, loop=0, disposal=2)
print("4 actual viewport frames, 786x512, 5.6s loop")

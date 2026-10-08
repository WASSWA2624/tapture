from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(r'D:\coding\apps\flutter\tapture')
goldens = root / 'frontend/test/core/widgets/fields/goldens'
output = root / '.tmp-task144-branding-qa'
output.mkdir(exist_ok=True)
font = ImageFont.truetype(r'C:\Windows\Fonts\arial.ttf', 20)
for corner in ('compact', 'compact_landscape_text2', 'medium', 'expanded_text2'):
    originals = []
    for theme in ('light', 'dark', 'outdoor'):
        for prefix in ('choice_branded', 'choice_branded_sheet'):
            source = goldens / f'{prefix}_{corner}_{theme}.png'
            with Image.open(source) as loaded:
                image = loaded.convert('RGB')
            originals.append((theme, prefix, image))
    # Preserve each complete screenshot at its original resolution.
    width = max(image.width for _, _, image in originals)
    height = max(image.height for _, _, image in originals)
    sheet = Image.new('RGB', (width * 3, (height + 30) * 2), '#bbbbbb')
    draw = ImageDraw.Draw(sheet)
    for index, (theme, prefix, image) in enumerate(originals):
        column, row = index // 2, index % 2
        x, y = column * width, row * (height + 30)
        draw.text((x + 4, y + 3), f'{corner} {theme} {prefix}', font=font, fill='black')
        sheet.paste(image, (x, y + 30))
    target = output / f'{corner}.png'
    sheet.save(target)
    print(target)

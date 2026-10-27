"""Draws the store and iOS pictures from the emblem (tool/emblem.py):

    store/play_icon_512.png        Google Play's app icon
    store/feature_graphic.png      Google Play's 1024×500 banner
    ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png   iOS app icons (no transparency)
    ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png the iOS launch screen's emblem

    python3 tool/store_assets.py   # from mobile/
"""
import json
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

import emblem

STORE = 'store'
ICONS = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
LAUNCH = 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
FONT = 'assets/fonts/PlayfairDisplay-Bold.ttf'


def save(im, path):
    im.save(path, optimize=True)
    print('wrote', path)


def feature_graphic():
    """Emerald, the emblem on the left, the name on the right; Play may
    cover the bottom with buttons, so nothing important sits there."""
    w, h = 1024, 500
    im = Image.new('RGB', (w, h), emblem._rgb(emblem.EMERALD900))
    # The light the app's headers have: a little brighter towards the top left.
    glow = Image.new('L', (w, h), 0)
    ImageDraw.Draw(glow).ellipse([-260, -380, 700, 480], fill=90)
    glow = glow.filter(ImageFilter.GaussianBlur(110))
    im.paste(emblem._rgb(emblem.EMERALD800), (0, 0, w, h), glow)
    mark = emblem.picture(300, star=0.96, bare=True)
    im.paste(mark, (90, (h - 300) // 2), mark)
    d = ImageDraw.Draw(im)
    font = ImageFont.truetype(FONT, 84)
    d.text((440, h // 2 - 8), 'Muslim', font=font, fill=emblem._rgb(emblem.CREAM), anchor='ls')
    d.text((440, h // 2 + 84), 'Vegukin', font=font, fill=emblem._rgb(emblem.GOLD300), anchor='ls')
    return im


def main():
    os.makedirs(STORE, exist_ok=True)
    save(emblem.picture(512, star=0.56, square=True), f'{STORE}/play_icon_512.png')
    save(feature_graphic(), f'{STORE}/feature_graphic.png')

    # iOS rounds the corners itself and refuses icons with transparency.
    for image in json.load(open(f'{ICONS}/Contents.json'))['images']:
        points = float(image['size'].split('x')[0])
        px = round(points * int(image['scale'][0]))
        save(emblem.picture(px, star=0.56, square=True).convert('RGB'), f"{ICONS}/{image['filename']}")

    # The opening animation (lib/features/opening/opening.dart) starts from a
    # star 2 × 29/108 × 288 points wide in the middle of the screen; the
    # launch screen shows this picture at 160 points, so the two meet.
    star = 2 * 29 / 108 * 288 / 160
    for scale, name in ((1, 'LaunchImage.png'), (2, 'LaunchImage@2x.png'), (3, 'LaunchImage@3x.png')):
        save(emblem.picture(160 * scale, star=star, bare=True), f'{LAUNCH}/{name}')


if __name__ == '__main__':
    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
    main()

#!/usr/bin/env python3

import io
import re
import sys
import subprocess
from itertools import product
from math import ceil, floor

from PIL import Image

aw, ah, vh = 320, 200, 200
scalem = f'sx={aw}/w;sy={vh}/h;ss=min(1,min(sx,sy))'
w = f'%[fx:{scalem};round(w*ss)]'
h = f'%[fx:{scalem};round(h*ss/{vh/ah})]'

# convert -list interpolate,filter,etc
res = subprocess.check_output(
    ['identify', '-format', f'{w}x{h}', sys.argv[1]],
    encoding='utf8',
)

# Use ImageMagick to resize (letterboxed) and quantize to 256 colors
img = io.BytesIO(subprocess.check_output([
    'convert', sys.argv[1],
    '-resize', f'{res}!>',              # shrink only, don't scale up
    '-background', 'black',
    '-gravity', 'center',
    '-extent', f'{aw}x{ah}',
    '-quantize', 'LUV',                 # convert -list colorspace
    '-dither', 'FloydSteinberg',        # convert -list dither
    '-colors', '256',
    'gif:-',
]))

with open('image.gif', 'wb') as f:
    f.write(img.read())

class RC4:
    def __init__(self, key):
        key = key * int(ceil(256/len(key)))
        j, S = 0, bytearray(range(256))
        for i in range(256):
            j = (j + S[i] + key[i]) % 256
            S[j], S[i] = S[i], S[j]

        self.S, self.i, self.j = S, 0, 0

    def next(self):
        self.i = (self.i + 1) % 256
        self.j = (self.j + self.S[self.i]) % 256
        self.S[self.j], self.S[self.i] = self.S[self.i], self.S[self.j]
        return self.S[(self.S[self.i] + self.S[self.j]) % 256]

    def xor(self, value):
        return value ^ self.next()

with open(sys.argv[2], 'rb') as pw:
    raw = bytearray(pw.read())
    lookup = [0]*256
    #for i in range(256): lookup[i] = 0
    with open('scancodes') as scancodes:
        for line in map(lambda a: a.strip(), scancodes):
            m = re.match('^(?:(Space)|(\S)\s(\S))\s+([0-9A-F]{2})\s+.*', line)
            if m:
                a, b, c, d = m.groups()
                d = int(d, 16)
                if a is not None: lookup[32] = d
                if b is not None: lookup[ord(b)] = d
                if c is not None: lookup[ord(c)] = d

    for i in range(len(raw)):
        raw[i] = lookup[raw[i]]

print(list(set(lookup)))
print(list(map(int, raw)))

rc4 = RC4(raw)

with Image.open(img) as im:
    pal = im.palette.getdata()[1]
    pal += (768 - len(pal)) * b'\0'

    with open('image.pal', 'wb') as f:
        # write palette data (mode 13h has 6 bits per channel, so right shift by two)
        image_pal = map(lambda x: x >> 2, bytearray(pal))
        f.write(bytes(map(rc4.xor, image_pal)))

    with open('image.raw', 'wb') as f:
        # write pixel data
        for r, c in product(range(ah), range(aw)):
            f.write(bytearray([rc4.xor(im.getpixel((c,r)))]))

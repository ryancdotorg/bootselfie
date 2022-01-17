#!/usr/bin/env python3

from sys import argv, stderr, stdout, version_info
from functools import partial
eprint = partial(print, file=stderr)

from math import floor, ceil
from binascii import hexlify, unhexlify

key = unhexlify(argv[1])
key = key * int(ceil(256/len(key)))
S = bytearray(range(256))

j = 0
for i in range(256):
    j = (j + S[i] + key[i]) % 256
    S[j], S[i] = S[i], S[j]

for row in range(32):
    offset = row * 8
    octets = map(lambda x: f'    0x{x:02x}', key[offset:offset+8])
    print(f'<Key+{offset:-3}>:'+''.join(octets))

print()

for row in range(32):
    offset = row * 8
    octets = map(lambda x: f'    0x{x:02x}', S[offset:offset+8])
    print(f'<S+  {offset:-3}>:'+''.join(octets))

#!/bin/sh
as -g forth.s && ld -Bstatic -o forth  a.out -lc -lgcc -lc -L/usr/lib -L/usr/lib/gcc/armv7-alpine-linux-musleabihf/12.2.1

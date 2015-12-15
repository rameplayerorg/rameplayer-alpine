#!/bin/sh
amixer -q -Dhw:sndrpiwsp cset name='HPOUT1 Digital Volume' 116
amixer -q -Dhw:sndrpiwsp cset name='HPOUT1L Input 1' AIF1RX1
amixer -q -Dhw:sndrpiwsp cset name='HPOUT1L Input 1 Volume' 32
amixer -q -Dhw:sndrpiwsp cset name='HPOUT1R Input 1' AIF1RX2
amixer -q -Dhw:sndrpiwsp cset name='HPOUT1R Input 1 Volume' 32
amixer -q -Dhw:sndrpiwsp cset name='HPOUT1 Digital Switch' on

#!/bin/sh
amixer -q -Dhw:sndrpiwsp cset name='HPOUT2L Input 1' AIF1RX1
amixer -q -Dhw:sndrpiwsp cset name='HPOUT2L Input 1 Volume' 32
amixer -q -Dhw:sndrpiwsp cset name='HPOUT2R Input 1' AIF1RX2
amixer -q -Dhw:sndrpiwsp cset name='HPOUT2R Input 1 Volume' 32
amixer -q -Dhw:sndrpiwsp cset name='HPOUT2 Digital Switch' on

#!/bin/bash

oscsend localhost 18032 /spatosc/core ss createSource sheefa
sleep 1
oscsend localhost 18032 /spatosc/core/source/sheefa/prop sf vol .1
sleep 1
oscsend localhost 18032 /spatosc/core/source/sheefa/prop sf azi -1
sleep 1
oscsend localhost 18032 /spatosc/core/source/sheefa/prop sf azi 1
sleep 1
oscsend localhost 18032 /spatosc/core/source/sheefa/prop sf azi 0
sleep 1
oscsend localhost 18032 /spatosc/core/source/sheefa/prop sf vol 1
sleep 2
oscsend localhost 18032 /spatosc/core/source/sheefa/uri s plugin://pink
sleep 5
oscsend localhost 18032 /spatosc/core/source/sheefa/prop sf sfreq 1000
sleep 1
oscsend localhost 18032 /spatosc/core/source/sheefa/prop sf sfreq 500
sleep 1
oscsend localhost 18032 /spatosc/core/source/sheefa/uri s plugin://dust
sleep 1
oscsend localhost 18032 /spatosc/core/source/sheefa/prop sf density1 20
sleep 3
oscsend localhost 18032 /spatosc/core/source/sheefa/prop sf density2 400
sleep 5
oscsend localhost 18032 /spatosc/core ss deleteNode sheefa

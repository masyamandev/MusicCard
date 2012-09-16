MusicCard
=========

Music card based on microcontriller Atmel atTiny13


Scheme:
Piezoelectric speaker should be connected to Pin2 and Pin3.
Firmware is designed to run on 4.8 mHz CPU clock.


Additional software:
Python/fromCsv.py
Script converts notes in csv fromat to format that can be included to asm file.
Usage (in linux): cat dogWaltz.csv | ./fromCsv.py > dogWaltz.inc

Python/toCsv.py
Opposite conversion to "Python/fromCsv.py".
Usage (in linux): cat dogWaltz.inc | ./toCsv.py > dogWaltz.csv

Python/playCsv.py
Generates test.au file that can be played on audio player. Used to test sound without flashing real microcontroller.
usage (in linux): cat dogWaltz.csv | ./playCsv.py


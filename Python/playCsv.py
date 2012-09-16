#!/usr/bin/python
import re
import sys
from struct import pack

voices = sys.stdin.readlines()

sampleRate = 16000
noSound = 0.001

voicesNumber = 3

noteNames = {"x": noSound, 
	"A2"  : 110,
	"Hb2" : 116.540940379522,
	"H2"  : 123.470825314031,
	"C3"  : 130.812782650299,
	"Db3" : 138.591315488436,
	"D3"  : 146.832383958704,
	"Eb3" : 155.56349186104,
	"E3"  : 164.813778456435,
	"F3"  : 174.614115716502,
	"Gb3" : 184.997211355817,
	"G3"  : 195.997717990875,
	"Ab3" : 207.652348789973,
	"A3"  : 220,
	"Hb3" : 233.081880759045,
	"H3"  : 246.941650628062,
	"C4"  : 261.625565300599,
	"Db4" : 277.182630976872,
	"D4"  : 293.664767917408,
	"Eb4" : 311.126983722081,
	"E4"  : 329.62755691287,
	"F4"  : 349.228231433004,
	"Gb4" : 369.994422711635,
	"G4"  : 391.995435981749,
	"Ab4" : 415.304697579945,
	"A4"  : 440,
	"Hb4" : 466.16376151809,
	"H4"  : 493.883301256124,
	"C5"  : 523.251130601198,
	"Db5" : 554.365261953745,
	"D5"  : 587.329535834816,
	"Eb5" : 622.253967444162,
	"E5"  : 659.255113825741,
	"F5"  : 698.456462866008,
	"Gb5" : 739.98884542327,
	"G5"  : 783.990871963499,
	"Ab5" : 830.609395159891,
	"A5"  : 880}

def au_file(sound, name='test.au'):
    fout = open(name, 'wb')
    # header needs size, encoding=2, sampling_rate=8000, channel=1
    fout.write(pack('>4s5L', '.snd'.encode("utf8"), 24, len(sound), 2, sampleRate, 1))
    # write data
    fout.write(sound);
    fout.close()
    print("File %s written" % name)

def generateSound(freqs, length, offset = 0):
    sample = "";
    freqLenghts = map((lambda f: int(sampleRate / f)), freqs)
    for i in xrange(offset, offset + int(length)):
	vol = 0
	for f in freqLenghts:
	    if i % f == 0:
		vol = 48
	sample = sample + pack('b', int(vol))
    #print sample
    return sample

data = ""
csvRegexp = re.compile("\s*,\s*")
tempo = int((0.5 * 60 / 160) * sampleRate)
length = 0

lastVoice = [noSound] * voicesNumber
for line in voices :
    #print line
    #break
    if line[:2] != "//" :
	notes = csvRegexp.split(line)
	i = 0;
	#print notes
	playNotes = [noSound] * voicesNumber
	for note in notes :
	    note = note.replace("\'", "").replace("\"", "").strip()
	    #print i, note
	    if note != "" :
		if note in noteNames :
		    lastVoice[i] = noteNames[note]
		else :
		    lastVoice[i] = noSound
	    playNotes[i] = lastVoice[i]
	    i += 1
	    
	#print playNotes
	data = data + generateSound(playNotes, tempo, length)
	length = length + tempo
"""	
data = data + generateSound([noteNames["C4"]], (0.5 * 60 / 160) * sampleRate)
data = data + generateSound([noteNames["C4"]], (0.5 * 60 / 160) * sampleRate)
data = data + generateSound([noteNames["C4"]], (0.5 * 60 / 160) * sampleRate)
data = data + generateSound([noteNames["C4"]], (0.5 * 60 / 160) * sampleRate)
"""
au_file(data)


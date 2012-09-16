#!/usr/bin/python
import re
import sys

data = sys.stdin.readlines()

voices = []
notes = None

noteNames = ["x", "D3", "Eb3", "E3", "F3", "Gb3", "G3", "Ab3",
	    "A3", "Hb3", "H3", "C4", "Db4", "D4", "Eb4", "E4",
	    "F4", "Gb4", "G4", "Ab4", "A4", "Hb4", "H4", "C5",
	    "Db5", "D5", "Eb5", "E5", "F5", "Gb5", "G5"]

numRegexp = re.compile("\d+")

#print "Counted", len(data), "lines."
for line in data :
    #print line
    if line[:5] == "Voice" :
	if not notes is None :
	    voices.append(notes)
	notes = []
    else:
	notes += numRegexp.findall(line)
#print "voices", len(voices)

noteArray = []

for voice in voices :
    #print "Voice", len(voice)
    notes = []
    for note in voice :
	#notes.append(note)
	notes.append(noteNames[int(note) & 31])
	#print noteNames[int(note) & 31], (int(note) / 32 - 1)
	for i in range(0, (int(note) / 32 - 1)) : 
	    notes.append(" ")
    noteArray.append(notes)

#print "min", len(min(noteArray, key=len))
#print "max", len(max(noteArray, key=len))

i = 0;
while i < len(min(noteArray, key=len)) :
    line = "";
    for voice in noteArray :
	if len(line) > 0:
	    line += ",\t"
	line += voice[i]
    i += 1
    print line
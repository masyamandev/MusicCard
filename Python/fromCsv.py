#!/usr/bin/python
import re
import sys

data = sys.stdin.readlines()

noteNames = ["x", "D3", "Eb3", "E3", "F3", "Gb3", "G3", "Ab3",
	    "A3", "Hb3", "H3", "C4", "Db4", "D4", "Eb4", "E4",
	    "F4", "Gb4", "G4", "Ab4", "A4", "Hb4", "H4", "C5",
	    "Db5", "D5", "Eb5", "E5", "F5", "Gb5", "G5"]

splitLength = 8

voices = [[], [], []]
currentNote = ['x', 'x', 'x']
currentLength = [0, 0, 0]

#whitespaceRegexp = re.compile("[\s\'\"]")
csvRegexp = re.compile("\s*,\s*")

for line in data :
    #print line
    if line[:2] != "//" :
	notes = csvRegexp.split(line)
	i = 0;
	#print notes
	for note in notes :
	    note = note.replace("\'", "").replace("\"", "").replace("\n", "").strip()
	    #print "_" + note,
	    if note == "":# or note == currentNote[i] :
		currentLength[i] += 1
	    else :
		while currentLength[i] > 0 :
		    noteLength = min(currentLength[i], splitLength)
		    #voices[i].append(currentNote[i] + " " + str(noteLength))
		    voices[i].append(noteNames.index(currentNote[i]) + (noteLength) * 32)
		    currentLength[i] -= noteLength
		currentNote[i] = note
		currentLength[i] = 1
	    i += 1

for voice in voices :
    voice.append(0) # end of song
    print "Voice" + str(voices.index(voice) + 1) + "data: ; Length: ", len(voice)
    i = 0
    sb = ""
    for note in voice :
	if i == 0 :
	    sb = "\t\t.db "
	else :
	    sb += ", "
	sb += str(note)
	i += 1;
	if i >= 16 :
	    print sb
	    i = 0
	    sb = ""
    if i % 2 == 1 :
	sb += ", 0"
    print sb
print "VoiceEnd: ; End of voice section"

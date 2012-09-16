.include "tn13def.inc"

; interrupt variables
.def	intVolume	= R2
.def	intVoiceTimeH	= R18
.def	intVoiceTimeL	= R19

.def	intTempoIsNext	= R3
.def	intTempoCounterH	= R20
.def	intTempoCounterL	= R21
.def	intVolumeInrement	= R25

.def	intTemp		= R4

; common constants
.def	one			= R10
.def	zero		= R11

; main loop vapiables
.def	temp		= R16
.def	position	= R22
.def	note		= R23
.def	duration	= R24

.def	endOfMelody	= R5

; tempo calculations
.equ 	XTAL = 4800000
.equ	TimerScaler = 256 ; Program steps in one timer interrupt
.equ	MaxFreq = XTAL / TimerScaler 	
.equ 	Tempo = 240*2;160 * 2 ; 1/8 per minute
.equ	TempoCounter = (MaxFreq * 60) / Tempo 

; microcontroller settings
.equ	TimerPrescaler = (0<<CS02) | (0<<CS01) | (1<<CS00)

.equ	OutPin1	= PB3
.equ	OutPin2 = PB4
.equ	TestPin	= PB0

; .dseg data structure
.equ	VoiceTimeH = 0
.equ	VoiceTimeL = 1
.equ	VoiceFreqH = 2
.equ	VoiceFreqL = 3
.equ	VoiceDuration = 4
.equ	VoicePosition = 5
.equ	VoiceDataH = 6
.equ	VoiceDataL = 7

.dseg
		; voices structure: VoiceTimeH, VoiceTimeL, VoiceFreqH, VoiceFreqL, VoiceDuration, VoicePosition, VoiceDataH, VoiceDataL
		Voice1:		.BYTE 8
		Voice2:		.BYTE 8
		Voice3:		.BYTE 8

.cseg
.org	$000
		rjmp	Init ; 1 0x0000 RESET, External Pin, Power-on Reset, Brown-out Reset, Watchdog Reset
		rjmp	UnusedInterrupt ; 2 0x0001 INT0 External Interrupt Request 0
		rjmp	UnusedInterrupt ; 3 0x0002 PCINT0 Pin Change Interrupt Request 0
		rjmp	TimerInterrupt ; 4 0x0003 TIM0_OVF Timer/Counter Overflow
		rjmp	UnusedInterrupt ; 5 0x0004 EE_RDY EEPROM Ready
		rjmp	UnusedInterrupt ; 6 0x0005 ANA_COMP Analog Comparator
		rjmp	UnusedInterrupt ; 7 0x0006 TIM0_COMPA Timer/Counter Compare Match A
		rjmp	UnusedInterrupt ; 8 0x0007 TIM0_COMPB Timer/Counter Compare Match B
		rjmp	UnusedInterrupt ; 9 0x0008 WDT Watchdog Time-out
		rjmp	UnusedInterrupt ; 10 0x0009 ADC ADC Conversion Complete
		
Init:
		; disable interrupts
		cli

		; Set output port
		ldi 	temp, (1<<OutPin1) | (1<<OutPin2) | (1<<TestPin)
		out 	DDRB, temp

		; Set stackptr to ram end
		ldi		temp, low(RAMEND)
		out		SPL, temp
		;ldi		temp, high(RAMEND)
		;out		SPH, temp

		; set up timer interrupt
		ldi		temp, (1<<TOIE0) ; timer overflow register
		out		TIMSK0, temp
		ldi 	temp, TimerPrescaler
		out 	TCCR0B, temp

		; clear variables
		clr		zero
		clr		one
		inc		one
		clr		endOfMelody

		; clear note positions
		ser		position
		ser		duration

		ldi		YH, high(voice1)
		ldi		YL, low(voice1)
		std		Y + VoicePosition, position
		std		Y + VoiceDuration, duration
		ldi		temp, high(Voice1Data * 2)
		std		Y + VoiceDataH, temp
		ldi		temp, low(Voice1Data * 2)
		std		Y + VoiceDataL, temp
		
		ldi		YH, high(voice2)
		ldi		YL, low(voice2)
		std		Y + VoicePosition, position
		std		Y + VoiceDuration, duration
		ldi		temp, high(Voice2Data * 2)
		std		Y + VoiceDataH, temp
		ldi		temp, low(Voice2Data * 2)
		std		Y + VoiceDataL, temp
		
		ldi		YH, high(voice3)
		ldi		YL, low(voice3)
		std		Y + VoicePosition, position
		std		Y + VoiceDuration, duration
		ldi		temp, high(Voice3Data * 2)
		std		Y + VoiceDataH, temp
		ldi		temp, low(Voice3Data * 2)
		std		Y + VoiceDataL, temp

        rcall	CheckNotes

		; enable interrupts
		sei

MainLoop:
		;cli
		; Check notes
		rcall	CheckNotes
		;sei
		cpse	endOfMelody, zero
			rjmp	Init
		rjmp	MainLoop

CheckNotes:
		ldi		YH, high(voice1)
		ldi		YL, low(voice1)
		rcall	CheckNote
		ldi		YH, high(voice2)
		ldi		YL, low(voice2)
		rcall	CheckNote
		ldi		YH, high(voice3)
		ldi		YL, low(voice3)
		rcall	CheckNote
		ret

CheckNote:
		ldd		temp, Y + VoiceDuration
		cpi		temp, 250
		brlo	NoteNotChanged
			; load next note
			ldd		position, Y + VoicePosition
			inc		position
			std		Y + VoicePosition, position
			ldd		ZH, Y + VoiceDataH
			ldd		ZL, Y + VoiceDataL
			add		ZL, position
			adc		ZH, zero
			lpm		note, Z
			; check if zero - end of melody
			cp		note, zero
			brne	NewNoteLoaded
				mov		endOfMelody, one
			NewNoteLoaded:
			; load duration
			mov		duration, note
			andi	duration, 0xE0
			lsr		duration
			lsr		duration
			lsr		duration
			lsr		duration
			lsr		duration
			dec		duration ; TODO: remove this
			std		Y + VoiceDuration, duration
			; load note
			andi	note, 0x1F
			breq	MuteNote
				ldi		ZH, high(NotesFreq * 2)
				ldi		ZL, low(NotesFreq * 2)
				add		ZL, note
				adc		ZH, zero
				lpm		temp, Z
				std		Y + VoiceFreqH, zero
				std		Y + VoiceFreqL, temp
				rjmp	NoteLoadFinish
			MuteNote:
				ser		temp ; 0xFF
				std		Y + VoiceFreqH, temp
				std		Y + VoiceFreqL, temp
			NoteLoadFinish:
			; clear counter
			std		Y + VoiceTimeH, zero
			std		Y + VoiceTimeL, zero
		NoteNotChanged:
		ret

TimerInterrupt:
		; save registers
		sbi		PORTB, TestPin
		in		intTemp, SREG
		push	intTemp
		push	YH
		push	YL
		; clear data
		clr		intVolume
		clr		intTempoIsNext
		; check end of 1/4
		subi	intTempoCounterL, 1
		sbci	intTempoCounterH, 0
		brcc	ContinueTempo
			; load delay
			ldi		intTempoCounterH, high(TempoCounter)
			ldi		intTempoCounterL, low(TempoCounter)
			mov		intTempoIsNext, one
		ContinueTempo:
		; play notes
		ldi		intVolumeInrement, 2
		ldi		YH, high(voice1)
		ldi		YL, low(voice1)
		rcall	CheckVoice
		;ldi		intVolumeInrement, 1
		ldi		YH, high(voice2)
		ldi		YL, low(voice2)
		rcall	CheckVoice
		ldi		YH, high(voice3)
		ldi		YL, low(voice3)
		rcall	CheckVoice
		; set volume
		cp		intVolume, zero
		breq	Vol0
		cp		intVolume, one
		breq	Vol1
		Vol2:
			cbi		PORTB, OutPin1
			sbi		PORTB, OutPin2
			rjmp	VolSetEnd
		Vol1:
			cbi		PORTB, OutPin1
			cbi		PORTB, OutPin2
			rjmp	VolSetEnd
		Vol0:
			sbi		PORTB, OutPin1
			cbi		PORTB, OutPin2
		VolSetEnd:
		; restore registers
		pop		YL
		pop		YH
		pop		intTemp
		out		SREG, intTemp 
		cbi		PORTB, TestPin
		reti

CheckVoice:
		ldd		intVoiceTimeH, Y + VoiceTimeH
		ldd		intVoiceTimeL, Y + VoiceTimeL
		subi	intVoiceTimeL, 1
		sbci	intVoiceTimeH, 0
		brcc	ContinueVoice
			; load delay
			ldd		intVoiceTimeH, Y + VoiceFreqH
			ldd		intVoiceTimeL, Y + VoiceFreqL
			add		intVolume, intVolumeInrement
		ContinueVoice:
;		ldi		intTemp, 4 ; volume
;		cp		intTemp, intVoiceTimeL
;		brlo	NoVolumeUp
;			cp		intVoiceTimeH, zero
;			brne	NoVolumeUp
;				inc		intVolume
;		NoVolumeUp:
		cp		intTempoIsNext, zero
		breq	TempoNotChanged
			ldd		intTemp, Y + VoiceDuration
			dec		intTemp
			std		Y + VoiceDuration, intTemp
		TempoNotChanged:
		std		Y + VoiceTimeH, intVoiceTimeH
		std		Y + VoiceTimeL, intVoiceTimeL
		ret

UnusedInterrupt:
		reti


.include "Python/dogWaltz.inc"


.equ 	fr_A2	= MaxFreq / 110
.equ	fr_Hb2	= MaxFreq / 116;.540940379522
.equ	fr_H2	= MaxFreq / 123;.470825314031
.equ	fr_C3	= MaxFreq / 130;.812782650299
.equ	fr_Db3	= MaxFreq / 138;.591315488436
.equ	fr_D3	= MaxFreq / 146;.832383958704
.equ	fr_Eb3	= MaxFreq / 155;.56349186104
.equ	fr_E3	= MaxFreq / 164;.813778456435
.equ	fr_F3	= MaxFreq / 174;.614115716502
.equ	fr_Gb3	= MaxFreq / 184;.997211355817
.equ	fr_G3	= MaxFreq / 195;.997717990875
.equ	fr_Ab3	= MaxFreq / 207;.652348789973
.equ	fr_A3	= MaxFreq / 220
.equ	fr_Hb3	= MaxFreq / 233;.081880759045
.equ	fr_H3	= MaxFreq / 246;.941650628062
.equ	fr_C4	= MaxFreq / 261;.625565300599
.equ	fr_Db4	= MaxFreq / 277;.182630976872
.equ	fr_D4	= MaxFreq / 293;.664767917408
.equ	fr_Eb4	= MaxFreq / 311;.126983722081
.equ	fr_E4	= MaxFreq / 329;.62755691287
.equ	fr_F4	= MaxFreq / 349;.228231433004
.equ	fr_Gb4	= MaxFreq / 369;.994422711635
.equ	fr_G4	= MaxFreq / 391;.995435981749
.equ	fr_Ab4	= MaxFreq / 415;.304697579945
.equ	fr_A4	= MaxFreq / 440
.equ	fr_Hb4	= MaxFreq / 466;.16376151809
.equ	fr_H4	= MaxFreq / 493;.883301256124
.equ	fr_C5	= MaxFreq / 523;.251130601198
.equ	fr_Db5	= MaxFreq / 554;.365261953745
.equ	fr_D5	= MaxFreq / 587;.329535834816
.equ	fr_Eb5	= MaxFreq / 622;.253967444162
.equ	fr_E5	= MaxFreq / 659;.255113825741
.equ	fr_F5	= MaxFreq / 698;.456462866008
.equ	fr_Gb5	= MaxFreq / 739;.98884542327
.equ	fr_G5	= MaxFreq / 783;.990871963499
.equ	fr_Ab5	= MaxFreq / 830;.609395159891
.equ	fr_A5	= MaxFreq / 880

NotesFreq:
		.db 		0,	fr_D3,	fr_Eb3,	fr_E3,	fr_F3,	fr_Gb3,	fr_G3,	fr_Ab3
		.db		fr_A3,	fr_Hb3,	fr_H3, fr_C4,  fr_Db4,	fr_D4,	fr_Eb4, fr_E4
		.db		fr_F4,  fr_Gb4, fr_G4,  fr_Ab4, fr_A4,  fr_Hb4, fr_H4,	fr_C5
		.db		fr_Db5,	fr_D5,	fr_Eb5, fr_E5,  fr_F5,  fr_Gb5, fr_G5

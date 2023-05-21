.MODEL SMALL
.386

	bar_left = 2h
	bar_right = 25h
	black = 0h
	end_of_line = 28h
	newline = 50h
	white = 0F0Fh

.STACK 100h
.DATA

;*** Definitionen ***
	;22-55
	pong1 DB         "                      *****    ****   *     *    *****     ", "$"
	pong2 DB         "                      *    *  *    *  **    *   *     *    ", "$"	
	pong3 DB         "                      *    *  *    *  * *   *   *          ", "$"
	pong4 DB         "                      *****   *    *  *   * *   *   ***    ", "$"
	pong5 DB         "                      *       *    *  *    **   *    **    ", "$"
	pong6 DB         "                      *        ****   *     *    ******    ", "$"
	;32-46
	startgame DB     "                                Spiel starten              ", "$"
	;27-51
	highscorelist DB "                           Highscoreliste anzeigen         ", "$"
	;36-39
	escape DB        "                                    Ende                   ", "$"
	nline DB 13, 10, "$"
	blink DB 		 "                                     ", "$"
	
	select DB 1 DUP(0)		;Auswahl auf "nichts" setzen

	argsb db 3 dup(?)
	argsw dw 1 dup(?)
	ball_direction db 1 dup(?)
	ball_position db 2 dup(?)
	bar_position_left db 2 dup(?)
	bar_position_right db 2 dup(?)
	buf db 20h dup(?)
	count_left db 1 dup(0)
	count_right db 1 dup(0)
	handle dw 1 dup(?)
	tmpb db 2 dup(?)
	tmpw dw 2 dup(?)

	dateiname db "C:\DATEN.txt",0
	space db " ","$"
	trenn db '|',"$"
	null db "0","$"
	eins db "1","$"
	zwei db "2","$"
	drei db "3","$"
	vier db "4","$"
	fuenf db "5","$"
	sechs db "6","$"
	sieben db "7","$"
	acht db "8","$"
	neun db "9","$"

.CODE

;*** MACROS ***

;Macro zur Textausgabe____________________________________________________
print MACRO output
	push ax					;Inhaltssicherung der benoetigten
	push dx					;Register auf Stack
	push ds

	mov ax, SEG &output		;Laden des auszugebenden
	mov ds, ax				;Strings
	mov dx, OFFSET &output

	mov ah, 9				;Ausgabe des geladenen Strings 
	int 21h					;mittels DOS-Funktion

	pop ds					;Stackinhalte zurueck in die
	pop dx					;Register schreiben
	pop ax
ENDM
;_________________________________________________________________________


;*** PROZEDUREN ***

;Prozedur zur Mausbehandlung______________________________________________
maus PROC FAR 			;beim Aufruf der maus-Prozedur ist cx = xpos, 
						;dx = ypos des Mauszeigers
	mov ax, @data		;Datensegment sichern
	mov ds, ax
	
	;Test ob "Spiel" gewaehlt wurde 13 Zeile
	cmp cx, 288
	jb one					;jumpbelow
	cmp cx, 320
	ja one					;jumpabove
	cmp dx, 91
	jb one
	cmp dx, 98
	ja one
	mov select, 1			;1 fuer "Spiel"
	jmp fin

one:
	;Test ob "Highscore" gewaehlt wurde 14 Zeile
	cmp cx, 216
	jb two					
	cmp cx, 408
	ja two					
	cmp dx, 98
	jb two
	cmp dx, 105
	ja two
	mov select, 2			;2 fuer "Score"
	jmp fin
	
two:
	;Test ob "Ende" gewaehlt wurde 15te Zeile
	cmp cx, 288
	jb fin			
	cmp cx, 320
	ja fin			
	cmp dx, 105
	jb fin
	cmp dx, 112
	ja fin
	mov select, 3			;3 fuer "Ende"
	jmp fin
	
fin:
	ret
	maus ENDP
;_________________________________________________________________________	

;Prozedur zur Ausgabe des Menuetextes_____________________________________
menuetext PROC FAR
	pusha
	
	mov cx, 3		;Schleifenzaehler initialisieren
space1:
	print nline
	loop space1
	
	print pong1
	print nline
	print pong2
	print nline
	print pong3
	print nline
	print pong4
	print nline
	print pong5
	print nline
	print pong6
	
	mov cx, 3		;Schleifenzaehler initialisieren
space2:
	print nline
	loop space2
	
	print startgame
	print nline
	print highscorelist
	print nline
	print escape
	print blink
	
	popa
	ret
	menuetext ENDP
;_________________________________________________________________________	

;Prozedur zum Aufraumen und Beenden des Programms
final PROC FAR
    mov ax,0              	;Maus zurueÅcksetzen
    int 33h

    mov ax,3				;Videomodus zurÅuecksetzen
    int 10h                 

    mov ah,4Ch				;Programmende 
    int 21h                 
	final ENDP
;_________________________________________________________________________
	

;*** Hauptprogramm ***

beginn: 
	
    ; Mausprozedur anmelden        
    mov cx,02h
    mov ax,01h
    int 33h
    mov ax,0Ch
    push cs
    pop es
    mov dx,OFFSET maus
    int 33h
	
    mov ax, @data
	mov ds, ax

	mov ax, 3h			;Videomodus setzen
	int 10h				;BS loeschen

	call menuetext		;Ausgabe des Auswahlmenues

	mov ax, 01h			;Maus aktivieren
    int 33h
	
choice:					;Warten bis Nutzerauswahl mittels
						;Maus getroffen wurde
	
	cmp select, 1		;Test ob "Spiel" gewaehlt wurde
	je game
	
	cmp select, 2		;Test ob "Highscore" gewaehlt wurde
	je score
	
	cmp select, 3		;Test ob "Ende" gewaehlt wurde
	je exit
	
	jmp choice
	
	mov ax, 02h			;Maus deaktivieren
	int 33h
	
	;Auswerten der Mausprozedure
game:
	;spiel aufrufen
	
	mov select, 0		;Auswahl wieder auf "nichts" setzen

;########################################################################

pong:
	mov ax, @DATA
	mov ds, ax

	mov ax, 12h
	int 10h

	mov dx, 3C4h
	mov al, 2
	out dx, al
	inc dx
	mov al, 0Fh
	out dx, al

	mov dx, 3CEh
	mov al, 5
	out dx, al
	inc dx
	mov al, 2
	out dx, al

	mov [bar_position_left], 0Ch
	mov [bar_position_right], 0Ch
	mov [ball_position], 17h
	mov [ball_position + 1], 0Ah
	mov [ball_direction], 0Ah

				;<<<<<<<<<<
	mov [argsw], offset white
	call draw_borders

	mov al, [bar_position_left]
	mov [argsb], al
	mov [argsb + 1], offset bar_left
	mov [argsw], offset white
	call draw_bar
	mov al, [bar_position_right]
	mov [argsb], al
	mov [argsb + 1], offset bar_right
	mov [argsw], offset white
	call draw_bar
				;<<<<<<<<<<

l1:
	call delay
	call redraw_ball
	mov ah, 1h
	int 16h
	jz l1
	mov ax, 0h
	int 16h

	cmp al, 71h		;"q"
	jne l2
	mov [argsb + 2], 8h
	call redraw_bar_left
l2:
	cmp al, 61h		;"a"
	jne l3
	mov [argsb + 2], 4h
	call redraw_bar_left
l3:
	cmp al, 6Fh		;"o"
	jne l4
	mov [argsb + 2], 8h
	call redraw_bar_right
l4:
	cmp al, 6Ch		;"l"
	jne l5
	mov [argsb + 2], 4h
	call redraw_bar_right
l5:
	cmp al, 1Bh
	jne l1
	mov ax, 3h
	int 12h
	jmp ende

;quadratischen Block zeichnen
;	[argsb]		.. Zeilen-Position
;	[argsb + 1]	.. Spalten-Position
;	[argsw]		.. Farbe
draw_block:
	mov dx, 3CEh		;Initialisierung
	mov al, 8		; ...
	out dx, al
	inc dx
	mov al, 0FFh
	out dx, al
	push 0A000h
	pop es
	mov ax, 0h		;Spalten-Abstand zum linken Rand ermitteln
	mov bh, 0h		; ...
	mov bl, [argsb + 1]
	add ax, bx
	add ax, bx
	mov [tmpw], ax
	mov ax, offset newline	;Zeilen-Abstand zum oberen Rand ermitteln
	mov bl, [argsb]		; ...
	mov bh, 0h
	mul bx
	mov bx, 10h
	mul bx
	mov [tmpw + 2], ax

	mov cx, 10h
d_bl1:
	mov ax, offset newline
	mul cx
	add ax, [tmpw + 2]
	add ax, [tmpw]
	mov di, ax
	mov al, es:[di]
	mov ax, [argsw]
	mov es:[di], ax
	loop d_bl1
	ret
endp

;Schlaeger-Flaeche zeichnen
;	[argsb]		.. x-position
;	[argsb + 1]	.. y-position
;	[argsw]		.. Farbe
draw_bar:
	call draw_block
	mov al, [argsb]
	inc al
	mov [argsb], al
	call draw_block
	mov al, [argsb]
	inc al
	mov [argsb], al
	call draw_block
	mov al, [argsb]
	inc al
	mov [argsb], al
	call draw_block
	ret
endp	

;loescht die linke Schlaegerflaeche auf ihrer alten Position und zeichnet sie auf ihrer neuen
redraw_bar_left:
	cmp [argsb + 2], 8h
	jne r_b_l1
	cmp [bar_position_left], 1h
	jna r_b_l2

	mov [argsw], offset black
	mov al, [bar_position_left]
	mov [argsb], al
	mov [argsb + 1], offset bar_left
	call draw_bar

	mov [argsw], offset white
	mov al, [bar_position_left]
	dec al
	mov [argsb], al
	mov [bar_position_left], al
	mov [argsb + 1], offset bar_left
	call draw_bar
	jmp r_b_l2

r_b_l1:
	cmp [argsb + 2], 4h
	jne r_b_l2
	cmp [bar_position_left], 19h
	jnb r_b_l2

	mov [argsw], offset black
	mov al, [bar_position_left]
	mov [argsb], al
	mov [argsb + 1], offset bar_left
	call draw_bar

	mov [argsw], offset white
	mov al, [bar_position_left]
	inc al
	mov [argsb], al
	mov [bar_position_left], al
	mov [argsb + 1], offset bar_left
	call draw_bar

r_b_l2:
	ret	
endp

;loescht die rechte Schlaegerflaeche auf ihrer alten Position und zeichnet sie auf ihrer neuen
redraw_bar_right:
	cmp [argsb + 2], 8h
	jne r_b_r1
	cmp [bar_position_right], 1h
	jna r_b_r2

	mov [argsw], offset black
	mov al, [bar_position_right]
	mov [argsb], al
	mov [argsb + 1], offset bar_right
	call draw_bar

	mov [argsw], offset white
	mov al, [bar_position_right]
	dec al
	mov [argsb], al
	mov [bar_position_right], al
	mov [argsb + 1], offset bar_right
	call draw_bar
	jmp r_b_r2

r_b_r1:
	cmp [argsb + 2], 4h
	jne r_b_r2
	cmp [bar_position_right], 19h
	jnb r_b_r2

	mov [argsw], offset black
	mov al, [bar_position_right]
	mov [argsb], al
	mov [argsb + 1], offset bar_right
	call draw_bar

	mov [argsw], offset white
	mov al, [bar_position_right]
	inc al
	mov [argsb], al
	mov [bar_position_right], al
	mov [argsb + 1], offset bar_right
	call draw_bar

r_b_r2:
	ret	
endp

;zeichnet die Spielfeldbegrenzung
draw_borders:
	mov [argsb], 0h
	mov [argsb + 1], 0h
	call draw_block
	mov al, offset newline
	dec al
	dec al
	mov [tmpb], al

d_bo1:				;obere grenze
	mov al, [argsb + 1]
	inc al
	mov [argsb + 1], al
	call draw_block
	cmp [argsb + 1], 27h
	jb d_bo1

d_bo2:
	mov al, [argsb]
	inc al
	mov [argsb], al
	call draw_block
	cmp [argsb], 1Dh
	jb d_bo2

d_bo3:
	mov al, [argsb + 1]
	dec al
	mov [argsb + 1], al
	call draw_block
	cmp [argsb + 1], 0h
	ja d_bo3

d_bo4:
	mov al, [argsb]
	dec al
	mov [argsb], al
	call draw_block
	cmp [argsb], 0h
	ja d_bo4
	ret
endp

redraw_ball:				;Ball wird in aktuelle Richtung bewegt
	cmp [ball_direction], 0Ah
	jne r_b_1
	call r_b_oben_links
r_b_1:	
	cmp [ball_direction], 06h
	jne r_b_2
	call r_b_unten_links
r_b_2:	
	cmp [ball_direction], 09h
	jne r_b_3
	call r_b_oben_rechts
r_b_3:	
	cmp [ball_direction], 05h
	jne r_b_4
	call r_b_unten_rechts
r_b_4:	
	cmp [ball_direction], 02h
	jne r_b_5
	call r_b_links
r_b_5:	
	cmp [ball_direction], 01h
	jne r_b_end
	call r_b_rechts
r_b_end:
	ret
endp

r_b_oben_links:
	mov al, [ball_position]
	mov ah, [ball_position + 1]
	mov [tmpb], al
	mov [tmpb + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset black
	call draw_block
	mov al, [tmpb]
	mov ah, [tmpb + 1]
	dec al
	dec ah
	cmp al, 0h				;oberer Spielfeldrand (Skizze 1)
	ja r_b_o_l1
	mov [ball_direction], 6h
	call r_b_unten_links
	jmp r_b_o_le
r_b_o_l1:
	cmp ah, 0h				;linker Spielfeldrand (Skizze 2)
	ja r_b_o_l2
	mov [ball_direction], 9h
	call r_b_oben_rechts
	mov al, [count_right]
	inc al
	mov [count_right], al

	cmp al, 9h
	jnb ende

	jmp r_b_o_le
r_b_o_l2:
	cmp ah, offset bar_left			;linke Schlaegerebene (Skizze 3)
	jne r_b_o_ld
	mov bl, [bar_position_left]
	add bl, 03h
	cmp al, [bar_position_left]		;ueber linkem Schlaeger
	jb r_b_o_ld
	cmp al, bl				;unter linkem Schlaeger
	ja r_b_o_ld
	sub bl, 2h
	cmp al, bl				;auf unterer Schlaegerhaelfte
	jna r_b_o_l3
	mov [ball_direction], 1h
	call r_b_rechts
	jmp r_b_o_le
r_b_o_l3:
	mov [ball_direction], 9h		;auf linkem Schlaeger (Skizze 4)
	call r_b_oben_rechts
	jmp r_b_o_le
r_b_o_ld:
	mov [ball_position], al
	mov [ball_position + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset white
	call draw_block
r_b_o_le:
	ret
endp

r_b_unten_links:
	mov al, [ball_position]
	mov ah, [ball_position + 1]
	mov [tmpb], al
	mov [tmpb + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset black
	call draw_block
	mov al, [tmpb]
	mov ah, [tmpb + 1]
	inc al
	dec ah
	cmp al, 1Dh				;unterer Spielfeldrand
	jb r_b_u_l1
	mov [ball_direction], 0Ah
	call r_b_oben_links
	jmp r_b_u_le
r_b_u_l1:
	cmp ah, 0h				;linker Spielfeldrand
	ja r_b_u_l2
	mov [ball_direction], 05h
	call r_b_unten_rechts
	mov al, [count_right]
	inc al
	mov [count_right], al

	cmp al, 9h
	jnb ende

	jmp r_b_u_le
r_b_u_l2:
	cmp ah, offset bar_left			;linke Schlaegerebene
	jne r_b_u_ld
	mov bl, [bar_position_left]
	add bl, 3h
	cmp al, [bar_position_left]		;ueber linkem Schlaeger
	jb r_b_u_ld
	cmp al, bl				;unter linkem Schlaeger
	ja r_b_u_ld
	sub bl, 1h
	cmp al, bl				;auf oberer Schlaegerhaelfte
	jnb r_b_u_l3
	mov [ball_direction], 1h
	call r_b_rechts
	jmp r_b_u_le
r_b_u_l3:
	mov [ball_direction], 05h
	call r_b_unten_rechts
	jmp r_b_u_le
r_b_u_ld:
	mov [ball_position], al
	mov [ball_position + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset white
	call draw_block
r_b_u_le:
	ret
endp

r_b_oben_rechts:
	mov al, [ball_position]
	mov ah, [ball_position + 1]
	mov [tmpb], al
	mov [tmpb + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset black
	call draw_block
	mov al, [tmpb]
	mov ah, [tmpb + 1]
	dec al
	inc ah
	cmp al, 0h				;oberer Spielfeldrand
	ja r_b_o_r1
	mov [ball_direction], 5h
	call r_b_unten_rechts
	jmp r_b_o_re
r_b_o_r1:
	cmp ah, 27h				;rechter Spielfeldrand
	jb r_b_o_r2
	mov [ball_direction], 0Ah
	call r_b_oben_links
	mov al, [count_left]
	inc al
	mov [count_left], al

	cmp al, 9h
	jnb ende

	jmp r_b_o_re
r_b_o_r2:
	cmp ah, offset bar_right		;rechte Schlaegerebene
	jne r_b_o_rd
	mov bl, [bar_position_right]
	add bl, 03h
	cmp al, [bar_position_right]		;ueber rechtem Schlaeger
	jb r_b_o_rd
	cmp al, bl				;unter rechtem Schlaeger
	ja r_b_o_rd
	sub bl, 2h
	cmp al, bl				;auf unterer Schlaegerhaelfte
	jna r_b_o_r3
	mov [ball_direction], 2h
	call r_b_links
	jmp r_b_o_re
r_b_o_r3:
	mov [ball_direction], 0Ah
	call r_b_oben_links
	jmp r_b_o_re
r_b_o_rd:
	mov [ball_position], al
	mov [ball_position + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset white
	call draw_block
r_b_o_re:
	ret
endp

r_b_unten_rechts:
	mov al, [ball_position]
	mov ah, [ball_position + 1]
	mov [tmpb], al
	mov [tmpb + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset black
	call draw_block
	mov al, [tmpb]
	mov ah, [tmpb + 1]
	inc al
	inc ah
	cmp al, 1Dh				;unterer Spielfeldrand
	jb r_b_u_r1
	mov [ball_direction], 9h
	call r_b_oben_rechts
	jmp r_b_u_re
r_b_u_r1:
	cmp ah, 27h				;rechter Spielfeldrand
	jb r_b_u_r2
	mov [ball_direction], 6h
	call r_b_unten_links
	mov al, [count_left]
	inc al
	mov [count_left], al

	cmp al, 9h
	jnb ende

	jmp r_b_u_re
r_b_u_r2:
	cmp ah, offset bar_right		;rechte Schlaegerebene
	jne r_b_u_rd
	mov bl, [bar_position_right]
	add bl, 03h
	cmp al, [bar_position_right]		;ueber rechtem Schlaeger
	jb r_b_u_rd
	cmp al, bl				;unter rechtem Schlaeger
	ja r_b_u_rd
	sub bl, 1h
	cmp al, bl				;auf oberer Schlaegerhaelfte
	jnb r_b_u_r3
	mov [ball_direction], 2h
	call r_b_links
	jmp r_b_u_re
r_b_u_r3:
	mov [ball_direction], 6h
	call r_b_unten_links
	jmp r_b_u_re
r_b_u_rd:
	mov [ball_position], al
	mov [ball_position + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset white
	call draw_block
r_b_u_re:
	ret
endp

r_b_rechts:
	mov al, [ball_position]
	mov ah, [ball_position + 1]
	mov [tmpb], al
	mov [tmpb + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset black
	call draw_block
	mov al, [tmpb]
	mov ah, [tmpb + 1]
	inc ah
r_b_re1:
	cmp ah, 27h				;rechter Spielfeldrand
	jb r_b_re2
	mov [ball_direction], 2h
	call r_b_links
	mov al, [count_left]
	inc al
	mov [count_left], al

	cmp al, 9h
	jnb ende

	jmp r_b_ree
r_b_re2:
	cmp ah, offset bar_right		;rechte Schlaegerebene
	jne r_b_red
	mov bl, [bar_position_right]
	add bl, 03h
	cmp al, [bar_position_right]		;ueber rechtem Schlaeger
	jb r_b_red
	cmp al, bl				;unter rechtem Schlaeger
	ja r_b_red
	sub bl, 1h
	cmp al, bl				;auf oberer Schlaegerhaelfte
	jnb r_b_re3
	mov [ball_direction], 0Ah
	call r_b_oben_links
	jmp r_b_ree
r_b_re3:
	mov [ball_direction], 6h
	call r_b_unten_links
	jmp r_b_ree
r_b_red:
	mov [ball_position], al
	mov [ball_position + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset white
	call draw_block
r_b_ree:
	ret
endp

r_b_links:
	mov al, [ball_position]
	mov ah, [ball_position + 1]
	mov [tmpb], al
	mov [tmpb + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset black
	call draw_block
	mov al, [tmpb]
	mov ah, [tmpb + 1]
	dec ah
r_b_li1:
	cmp ah, 0h				;linker Spielfeldrand
	ja r_b_li2
	mov [ball_direction], 1h
	call r_b_rechts
	mov al, [count_right]
	inc al
	mov [count_right], al

	cmp al, 9h
	jnb ende

	jmp r_b_lie
r_b_li2:
	cmp ah, offset bar_left			;linke Schlaegerebene
	jne r_b_lid
	mov bl, [bar_position_left]
	add bl, 03h
	cmp al, [bar_position_left]		;ueber linkem Schlaeger
	jb r_b_lid
	cmp al, bl				;unter linkem Schlaeger
	ja r_b_lid
	sub bl, 1h
	cmp al, bl				;auf oberer Schlaegerhaelfte
	jnb r_b_li3
	mov [ball_direction], 9h
	call r_b_oben_rechts
	jmp r_b_lie
r_b_li3:
	mov [ball_direction], 5h
	call r_b_unten_rechts
	jmp r_b_lie
r_b_lid:
	mov [ball_position], al
	mov [ball_position + 1], ah
	mov [argsb], al
	mov [argsb + 1], ah
	mov [argsw], offset white
	call draw_block
r_b_lie:
	ret
endp

delay:
	mov cx, 0FFFFh
	mov [tmpw], 01h
	mov [tmpw + 2], 02h
d1:	
	loop d1
	cmp [tmpw], 0h
	ja d2
	cmp [tmpw + 2], 0h
	je d3
	mov cx, [tmpw + 2]
	dec cx
	mov [tmpw + 2], cx
	mov [tmpw], 01h
	mov cx, 0FFFFh
	jmp d1
d2:
	mov cx, [tmpw]
	dec cx
	mov [tmpw], cx
	mov cx, 0FFFFh
	jmp d1
d3:
	ret
endp

;schreibt ein Zeichen in eine Textdatei
;[handle]	..	Datei-Handle
;[argsw]	..	Adresse des Zeichens
write:
	mov bx, [handle]
	mov ah, 40h
	mov dx, [argsw]
	mov cx, 1h
	int 21h
	ret
endp

ende:
	mov dx, offset dateiname
	mov cx, 0h
	mov ah, 3dh
	mov al, 1h
	int 21h
	mov [handle], ax
	jnc e_2

	mov dx, offset dateiname
	mov cx, 0h
	mov ah, 3Ch
	xor al, al
	int 21h
	mov [handle], ax

e_2:
	mov ah, 42h
	mov al, 2h
	mov bx, [handle]
	mov cx, 0h
	mov dx, 0h
	int 21h

	mov al, [count_left]
	mov ah, 0h
	shl ax, 1h
	add ax, offset null
	mov [argsw], ax

	call write
	mov [argsw], offset space
	call write
	mov al, [count_right]
	mov ah, 0h
	shl ax, 1h
	add ax, offset null
	mov [argsw], ax
	call write

	mov ah, 42h
	mov al, 2h
	mov bx, [handle]
	mov cx, 0h
	mov dx, 0h
	int 21h
	mov [argsw], offset trenn
	call write

	mov ah, 3Eh
	int 21h



	mov ax, 0h
	int 33h
	mov ax, 3h
	int 10h
	mov ah, 4Ch

;########################################################################

	jmp beginn
score:
	;punkte anzeigen
	mov select, 0h		;Auswahl wieder auf "nichts" setzen

;########################################################################

	mov dx, offset dateiname
	mov cx, 0h
	mov ah, 3dh
	mov al, 2h
	int 21h

	mov bx, ax
	mov ah, 3Fh
	mov cx, 20h
	mov dx, offset buf
	int 21h

	mov ax, 3h
	int 10h
	print buf

	mov ah, 0Bh
	int 21h
	mov ah, 0h
	int 16h
	cmp al, 1Bh
	jz ende

	mov ah, 3Eh
	int 21h

;########################################################################

	jmp beginn
exit:
	call final
	
	end beginn
	
; Milan Singh 260654803
; COMP 308 - McGill University - Winter 2017

.286
.model small
.stack 100h
.data
	vX dw 0
	vY dw 0
	vDepth dw 0
	vGran dw 0 
	vLineLen dw 0
	vCurBank dw 0
	vSeg dw 0
	vMode dw 0
	bBanks db 0
	penColor dd 0
	checkColour dd 0
	sameColour db 0
	startX dw 0
	endX dw 0
	startY dw 0
	endY dw 0
	XDiff dw 0
	YDiff dw 0
	firstInt dw 0
	secondInt dw 0
	thirdInt dw 0
	fourthInt dw 0

	ten db 10
	resnum dw 0
	numA db 0
	numB db 0
	numC db 0

	sChar db "Type a single character: ", 0
	sString db "Enter first word of first colour ", 0
	sString2 db "Enter second word of first colour ", 0
	sString3 db "Enter first word of second colour ", 0
	sString4 db "Enter second word of second colour ", 0
	sString5 db "Enter the mode number (in decimal)",10,13,0
	sTyped db "You typed: ", 0
	sZero db "0 ",0

	Sig dd ?
	success db "Success!",10,13,0
	SVGA_Info STRUC
		Signature           dd ?        ; "VESA" if VESA BIOS
		VersionL      		db ?        ; lower Version Number
		VersionH            db ?        ; higher Version Number
		OEMStringPtr        dd ?        ; pointer to description string
		CapableOf           dd ?        ; 32 flags of graphics card capabilities
		VidModePtr          dd ?        ; Pointer to list of available modes
		TotalMemory         dw ?        ; Memory available of card (in 64 kb blocks)
		OEMSoftwareVersion  dw ?        ; OEM software version
		VendorName          dd ?        ; pointer to vendor name
		ProductName         dd ?        ; pointer to product name
		ProductRevisionStr  dd ?        ; pointer to product revision string
		Reserved            db 512 DUP(?)   ; OEM scratchpad - size in bytes: 256 (VBE 1.0 & 1.2), 
										; 262 (VBE 1.1), 215 (VBE 2.0)
	SVGA_Info ENDS

	svga_i SVGA_Info <>

	SVGA_ModeInfo STRUC
		ModeAttributes      dw ?        ; mode attributes di								
		WinAAttributes      db ?    ; window A attributes di + 2								
		WinBAttributes      db ?    ; window B attributes di + 3
		WinGranularity      dw ?    ; window granularity di + 4
		WinSize             dw ?    ; window size di + 6
		WinASegment 		dw ?    ; window A start segment di + 8
		WinBSegment         dw ?    ; window B start segment di  + 10
		WinFuncPtr          dd ?        ; pointer to window function di + 12
		BytesPerScanLine    dw ?    ; bytes per scan line di + 16
		XResolution			dw ?    ; horizontal resolution di + 18
		YResolution         dw ?    ; vertical resolution di + 20
		XCharSize			db ?    ; character cell width di + 22
		YCharSize           db ?    ; character cell height di + 23
		NumberOfPlanes 		db ?    ; number of memory planes di  +24
		BitsPerPixel        db ?    ; bits per pixel di + 25
		NumberOfBanks       db ?    ; number of banks di + 26
		MemoryModel         db ?    ; memory model type di + 27
		BankSize           	db ?    ; bank size in kb
		NumberOfImagePages  db ?    ; number of images
		Reserved1           db ?    ; reserved for page function
		RedMaskSize         db ?    ; size of direct color red mask in bits
		RedFieldPosition    db ?    ; bit position of LSB of red mask
		GreenMaskSize       db ?    ; size of direct color green mask in bits
		GreenFieldPosition  db ?    ; bit position of LSB of green mask
		BlueMaskSize        db ?    ; size of direct color blue mask in bits
		BlueFieldPosition   db ?    ; bit position of LSB of blue mask
		RsvdMaskSize        db ?    ; size of direct color reserved mask in bits
		DirectColorModeInfo db ?    ; Direct Color mode attributes
		Reserved2           db 216 DUP(?)   ; remainder of ModeInfoBlock  
	SVGA_ModeInfo ENDS

	svga_mi SVGA_ModeInfo <>

	
.code

start:
	; Initialize data segment
	mov bp, sp
	mov ax, @data
	mov ds, ax

	lea dx, sString5
	call puts
	call getInt
 	push ax

	lea dx, sString
	call puts
	call getInt
	mov firstInt, ax

	lea dx, sString2
	call puts
	call getInt
	mov secondInt, ax

	lea dx, sString3
	call puts
	call getInt
	mov thirdInt, ax

	lea dx, sString4
	call puts
	call getInt
	mov fourthInt, ax

	call setMode
	pop ax

	;Assign values based off of mode
	
	call get_cardInfo

	mov ax, firstInt
	push ax
	mov ax, secondInt
	push ax
	call setPenColor
	pop ax
	pop ax

	
	mov ax, secondInt
	push ax
	call setCheckColour
	pop ax
	pop ax

	

	push  280	; Push y2
	push  320	; Push X2
	push  200	; Push Y
	push  280	; Push X
	call drawLine
	pop ax
	pop ax 
	pop ax 
	pop ax

	push  200	; Push y2
	push  360	; Push X2
	push  200	; Push Y
	push  280	; Push X
	call drawLine
	pop ax
	pop ax 
	pop ax 
	pop ax

	push 200 	; Push y2
	push 360 	; Push X2
	push 280 	; Push Y
	push 320 	; Push X
	call drawLine
	pop ax
	pop ax 
	pop ax 
	pop ax

	mov ax, thirdInt
	push ax
	mov ax, fourthInt
	push ax
	call setPenColor
	pop ax
	pop ax

	push 240;push Y
	push 320;push X
	call simpleFill
	pop ax
	pop ax

	mov ah, 0
	int 16h

	mov ax, 4f02h
	mov bx, 3
	int 10h
	
	; Terminate program
	mov ax, 4c00h
	int 21h


;void get_cardInfo
get_cardInfo:
;Get SVGA Info
	push es
	push di
	push bx
	push cx
	mov ax, @data
	mov es, ax
	mov ax, 4f00h
	mov di, OFFSET svga_i
	int 10h


	cmp ax, 4f00h
	jnz svga_cont 

	svga_end:
	mov ax, 0h; Fail -> Return 0
	pop cx
	pop bx
	pop di
	pop es
	ret
	svga_cont:

	;Get SVGA Model Info
	mov ax, 4f01h
	mov cx, vMode
	mov di, OFFSET svga_mi
	int 10h

	cmp ax, 4fh
	jne svga_end 

	;;;;Store Granularity
	;mov ax, es:[di+04h]
	;mov vGran, ax

	;;;;Store Segment
	mov ax, es:[di+08h]
	mov vSeg, ax

	;;;;Store XResolution
	mov ax, es:[di+12h]
	mov vX, ax

	;;;;Store YResolution
	mov ax, es:[di+14h]
	mov vY, ax

	
	;;;;Store BitsPerPixel
	mov ah, 0
	mov al, BYTE PTR es:[di+19h]
	mov bl, 8h
	div bl
	mov ah, 0
	mov vDepth, ax

	mov bx, vX
	mul bx
	mov vLineLen, ax


	;;;;Generate bBanks
	mov al, es:[di+1Ah]
	mov ah, 0
	cmp ax, 0h
	mov bBanks, 0h
	jle noBanks
	mov bBanks, 1h
	noBanks:
	pop cx
	pop bx
	pop di
	pop es
	ret

; bool AL SETMODE(int AH)
; [bp + 4] = AH
setMode:
	push bp
	mov bp, sp
	push bx

	mov ax, 4f02h
	mov bx, [bp+4] ; AX = argument AH
	mov vMode, bx
	int 10h


	cmp ax, 004fh
	je modeSuccess
	; Reset to text mode if unsucc
	mov ah, 00h
	mov al, 01h
	int 10h
	mov al, 0h  ; If it is not successful return 0
	pop bx
	pop bp
	ret

	modeSuccess:
	mov al, 1h  ; If it is  successful return 1
	pop bx
	pop bp
	ret

;bool AL setPenColor(int Colour)
; [bp+4] = Colour
setPenColor:
	push bp
	mov bp, sp

	mov ax, vDepth ; AX = NumBits(Colour)

	;Case (numBits(Colour))
	cmp ax, 4
	jz set_dword
	cmp ax, 3
	jz set_dword
	cmp ax, 2 
	jz set_word
	cmp ax, 1
	jz set_byte
	jmp set_error

	set_dword:
	mov ax, WORD PTR[bp+4]
	mov WORD PTR[penColor], ax 
	mov ax, WORD PTR[bp+6]
	mov WORD PTR[penColor+2], ax 
	mov ah, 0h
	mov al, 1h
	jmp set_end

	set_word:
	mov ax, WORD PTR[bp+4]
	mov WORD PTR[penColor], ax 
	mov ah, 0h
	mov al, 1h
	jmp set_end

	set_byte:
	mov al, BYTE PTR[bp+4]
	mov BYTE PTR[penColor], al 
	mov ah, 0h
	mov al, 1h
	jmp set_end

	set_error:
	mov ah, 0h
	mov al, 0h

	set_end:
	pop bx
	ret

;bool AL setCheckColor(int Colour)
;Sets checkColour used by readPixel
; [bp+4] = Colour
setCheckColour:
	push bp
	mov bp, sp

	mov ax, vDepth ; AX = NumBits(Colour)

	;Case (numBits(Colour))
	cmp ax, 4
	jz setC_dword
	cmp ax, 3
	jz setC_dword
	cmp ax, 2 
	jz setC_word
	cmp ax, 1
	jz setC_byte
	jmp setC_error

	setC_dword:
	mov ax, WORD PTR[bp+4]
	mov WORD PTR[checkColour], ax 
	mov ax, WORD PTR[bp+6]
	mov WORD PTR[checkColour+2], ax 
	mov ah, 0h
	mov al, 1h
	jmp set_end

	setC_word:
	mov ax, WORD PTR[bp+4]
	mov WORD PTR[checkColour], ax 
	mov ah, 0h
	mov al, 1h
	jmp set_end

	setC_byte:
	mov al, BYTE PTR[bp+4]
	mov BYTE PTR[checkColour], al 
	mov ah, 0h
	mov al, 1h
	jmp set_end

	setC_error:
	mov ah, 0h
	mov al, 0h

	setC_end:
	pop bx
	ret





; bool AL drawLine (int X, int Y, int X2, int Y2)
; [bp+4] = X
; [bp+6] = Y
; [bp+8] = X2
; [bp+10] = Y2
drawLine:
	push bp 
	mov bp, sp
	push bx
	push cx
	push dx

	mov ax, [bp+4]	;ax = X
	mov bx, [bp+8]	;bx = X2
	mov cx, [bp+6]  ;cx = Y
	mov dx, [bp+10] ;dx = Y2

	cmp ax, vX
	jg line_err
	cmp ax, 0h
	jl line_err
	cmp bx, vX
	jg line_err
	cmp bx, 0h
	jl line_err
	cmp cx, vY
	jg line_err
	cmp cx, 0h
	jl line_err
	cmp dx, vY
	jg line_err
	cmp dx, 0h
	jl line_err
	jmp line_succ
	line_err:
	mov ah, 0
	mov al, 0; Fail -> Return 0
	pop dx
	pop cx
	pop bx
	pop bp
	ret

	line_succ:

	cmp ax, bx
	jl noXYSwap
	cmp cx, dx
	jl noXYSwap

	xchg ax, bx
	xchg cx, dx

	noXYSwap:

	;Handle Vertical Line Case
	cmp ax, bx
	jne notVert ;if(X!=X2){notVert}
	vertLoop:
		push ax
		push cx
		call drawPixel
		pop cx
		pop ax 
		cmp cx, dx
		je endVert
		add cx, 1
		jmp vertLoop
	endVert:
	mov ah, 0
	mov al, 1; Success -> Return 1
	pop dx
	pop cx
	pop bx
	pop bp
	ret

	notVert:
	;Handle Horizontal Line Case
	cmp cx, dx
	jne notHorz ;if(X!=X2){notHorz}
	horzLoop:
		push ax
		push cx
		call drawPixel
		pop cx
		pop ax 
		cmp ax, bx
		je endHorz
		add ax, 1
		jmp horzLoop
	endHorz:
	mov ah, 0
	mov al, 1; Success -> Return 1
	pop dx
	pop cx
	pop bx
	pop bp
	ret

	notHorz:
	;Handle Diagonal Case
	;slope = (Y2-Y1)/(X2-X1)
	;ax = X1
	;bx = X2
	;cx = Y1
	;bx = Y2
	mov [startX], ax
	mov [endX], bx
	mov [startY], cx
	mov [endY], dx
	cmp ax, bx
	jg xDiffAbs
	sub bx, ax ;bx = X2-X1
	mov ax, bx
	jmp xDiffAbsEnd
	xDiffAbs:
	sub ax, bx
	xDiffAbsEnd:

	cmp cx, dx
	jg yDiffAbs
	sub dx, cx ;dx = X2-X1
	mov cx, dx
	jmp yDiffAbsEnd
	yDiffAbs:
	sub cx, dx
	yDiffAbsEnd:
	cmp ax, cx ;
	jge swapBridge; if dx<bx no need to swap
	;else swap
	mov ax, [startX]
	mov bx, [endX]
	mov cx, [startY]
	mov dx, [endY]			

	finit ; initialise float coproc
	finit ; initialise float coproc
	fld1 			
	fld1
	fadd
	fld1
	fdivr			;st(0) = 0.5
	
	sub bx, ax 		;bx = X2-X1
	cmp bx, 0h
	mov ax, bx
	jg XPos
	mov bx, -1h
	mul bx
	xPos:
	mov [XDiff], ax
	fild [XDiff]

	sub dx, cx 		;cx = Y2-Y1
	mov ax, dx
	cmp ax, 0h
	jg YPos
	mov bx, -1h
	mul bx
	yPos:
	mov [YDiff], ax
	fild [YDiff]

	mov ax, [startX]
	mov bx, [endX]
	mov cx, [startY]
	mov dx, [endY]	

	jmp swapBridgeEnd
	swapBridge:
	jmp noSwapXY

	swapBridgeEnd:

	fdiv 			;st(0) = (X2-X1)/(Y2-Y1) must be <= 1
	fld st(0)		;st(0), st(1) = (X2-X1)/(Y2-Y1) = deltaerr must be <= 1
	fsub st(0), st(2) ;st(0) = error = deltaerr-0.5
	;Now st(0) = error, st(1) = deltaerror, st(2)=0.5
	diagSwapLoop:
		cmp cx, dx
		je endSwap
		push ax
		push cx
		call drawPixel
		pop cx
		pop ax
		fadd st(0), st(1)

		fcom st(2) ;compare error to 0.5
		push ax
		fnstsw ax             ; copy flags to AX
 		sahf   
 		pop ax
		jc errSwapLess

		push bx 
		push dx
		mov bx, [startX]
		mov dx, [endX]
		cmp bx, dx
		jg xGT
		add ax, 1
		jmp xCont
		xGT:
		sub ax, 1
		xCont:
		pop bx
		pop dx

		fsub st(0), st(2)
		fsub st(0), st(2)

		errSwapLess:
		push bx 
		push dx
		mov bx, [startY]
		mov dx, [endY]
		cmp bx, dx
		jg yGT
		add cx, 1
		jmp yCont
		yGT:
		sub cx, 1
		yCont:
		pop bx
		pop dx
		jmp diagSwapLoop
	endSwap:
	mov ah, 0
	mov al, 1; Success -> Return 1
	pop dx
	pop cx
	pop bx
	pop bp
	ret

	noSwapXY:
	mov ax, [startX]
	mov bx, [endX]
	mov cx, [startY]
	mov dx, [endY]			

	finit ; initialise float coproc
	finit ; initialise float coproc
	fld1 			
	fld1
	fadd
	fld1
	fdivr			;st(0) = 0.5
	
	sub bx, ax 		;bx = X2-X1
	cmp bx, 0h
	mov ax, bx
	jg XPos2
	mov bx, -1h
	mul bx
	XPos2:
	mov [XDiff], ax
	fild [XDiff]

	sub dx, cx 		;cx = Y2-Y1
	mov ax, dx
	cmp ax, 0h
	jg YPos2
	mov bx, -1h
	mul bx
	YPos2:
	mov [YDiff], ax
	fild [YDiff]

	mov ax, [startX]
	mov bx, [endX]
	mov cx, [startY]
	mov dx, [endY]	

	fdivr 			;st(0) = (Y2-Y1)/(X2-X1) must be <= 1
	fld st(0)		;st(0), st(1) = (Y2-Y1)/(X2-X1)  = deltaerr must be <= 1
	fsub st(0), st(2) ;st(0) = error = deltaerr-0.5
	;Now st(0) = error, st(1) = deltaerror, st(2)=0.5
	diagSwap:
		cmp ax, bx
		je endLine
		push ax
		push cx
		call drawPixel
		pop cx
		pop ax
		fadd st(0), st(1)

		fcom st(2) ;compare error to 0.5
		push ax
		fnstsw ax             ; copy flags to AX
 		sahf   
 		pop ax
		jc errLess

		push bx 
		push dx
		mov bx, [startY]
		mov dx, [endY]
		cmp bx, dx
		jg yGT2
		add cx, 1
		jmp yCont2
		yGT2:
		sub cx, 1
		yCont2:
		pop bx
		pop dx

		fsub st(0), st(2)
		fsub st(0), st(2)

		errLess:
		push bx 
		push dx
		mov bx, [startX]
		mov dx, [endX]
		cmp bx, dx
		jg xGT2
		add ax, 1
		jmp xCont2
		xGT2:
		sub ax, 1
		xCont2:
		pop bx
		pop dx
		jmp diagSwap
	endLine:
	mov ah, 0
	mov al, 1; Success -> Return 1
	pop dx
	pop cx
	pop bx
	pop bp
	ret


; void drawPixel(int x, int y)
; [bp+6] = x
; [bp+4] = y
drawPixel:
	push bp 
	mov bp, sp
	push bx
	push cx 
	push dx
	push si
	push di
	push es 

	mov ax, [bp+6] ; AX = X coord
	mov cx, [bp+4] ; CX = Y coord
	mov dx, 0 ; dx = 0;

	;;;Test for valid input
	cmp ax, vX ; is X coord valid?
	jb draw_boundB
	cmp cx, vY ; is Y coord valid?
	jb draw_boundB
	jmp draw_error
	draw_boundB:

	;Must test for Banks here
	cmp bBanks, 1
	je draw_banks
	;;;Code for flat

	mul vDepth ; AX = X*depth
	mov bx, ax ; Store ax in bx

	mov ax, cx 
	mul vLineLen ; AX = Y*Bytes per line
	add ax,bx ; AX = pixel offset (Y*Bytes/line + X*ByteDepth)
	mov si, ax ; 
	jmp draw_switchC

	draw_banks:

	
	

	mul vDepth ; AX = X*depth
	mov bx, ax ; Store ax in bx

	mov ax, cx 
	mul vLineLen ; AX = Y*Bytes per line

	mov cx, vGran ; CX = Granularity
	add ax,bx ; AX = pixel offset (Y*Bytes/line + X*ByteDepth)
	adc dx, 0 ; DX = DX + Carry(add ax,bx) + 0 == Carry(...)

    test cx, cx
	jz draw_switchB
	div cx ; AX = pixel offset / granularity (int div)
	xchg ax, dx ; AX <-> DX i.e. DX = pixel offset / Granularity, AX = po % g

	draw_switchB:
	cmp dx, vCurBank ; Are we in the right bank
	mov si, ax ; 
	jz draw_switchC
	mov ax, 4f05h ; Window Control
	mov bx, 0
	int 10h
	mov vCurBank, dx


	draw_switchC: 
	mov es, vSeg ; ES = Memory Start
	mov ax, vDepth ; AX = NumBits(Colour)

	;Case (numBits(Colour))
	cmp ax, 4
	jz draw_dword
	cmp ax, 3
	jz draw_dword
	cmp ax, 2 
	jz draw_word
	cmp ax, 1
	jz draw_byte
	jmp draw_error

	draw_dword:
	mov ax, WORD PTR[penColor]
	mov dx, WORD PTR[penColor+2]
	mov WORD PTR es:[si], ax
	mov WORD PTR es:[si+2], dx
	jmp draw_end 


	draw_word:
	mov ax, WORD PTR[penColor]
	mov WORD PTR es:[si], ax
	jmp draw_end 

	draw_byte:
	mov al, BYTE PTR[penColor]
	mov BYTE PTR es:[si], al
	jmp draw_end 


	draw_error:
	mov ax, 0h; Fail -> Return 0
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop bp
	ret
	draw_end:
	mov ah, 0h
	mov al, 1h; Success -> Return 1
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop bp
	ret

; al readPixel(int x, int y)
; [bp+6] = x
; [bp+4] = y
; returns 1 in al if Colour(pixelAt(x,y)) == penColor else 0
readPixel:
	push bp 
	mov bp, sp
	push ax
	push bx
	push cx 
	push dx
	push si
	push di
	push es 

	mov ax, [bp+6] ; AX = X coord
	mov cx, [bp+4] ; CX = Y coord
	mov dx, 0 ; dx = 0;

	;;;Test for valid input
	cmp ax, vX ; is X coord valid?
	jb read_boundB
	cmp cx, vY ; is Y coord valid?
	jb read_boundB
	jmp read_error
	read_boundB:

	;Must test for Banks here
	cmp bBanks, 1
	je read_banks
	;;;Code for flat

	mul vDepth ; AX = X*depth
	mov bx, ax ; Store ax in bx

	mov ax, cx 
	mul vLineLen ; AX = Y*Bytes per line
	add ax,bx ; AX = pixel offset (Y*Bytes/line + X*ByteDepth)
	mov si, ax ; 
	readswitchC:

	read_banks:

	
	

	mul vDepth ; AX = X*depth
	mov bx, ax ; Store ax in bx

	mov ax, cx 
	mul vLineLen ; AX = Y*Bytes per line

	mov cx, vGran ; CX = Granularity
	add ax,bx ; AX = pixel offset (Y*Bytes/line + X*ByteDepth)
	adc dx, 0 ; DX = DX + Carry(add ax,bx) + 0 == Carry(...)

    test cx, cx
	jz read_switchB
	div cx ; AX = pixel offset / granularity (int div)
	xchg ax, dx ; AX <-> DX i.e. DX = pixel offset / Granularity, AX = po % g

	read_switchB:
	cmp dx, vCurBank ; Are we in the right bank
	mov si, ax ; 
	jz read_switchC
	mov ax, 4f05h ; Window Control
	mov bx, 0
	int 10h
	mov vCurBank, dx


	read_switchC: 
	mov es, vSeg ; ES = Memory Start
	mov ax, vDepth ; AX = NumBits(Colour)

	;Case (numBits(Colour))
	cmp ax, 4
	jz read_dword
	cmp ax, 3
	jz read_dword
	cmp ax, 2 
	jz read_word
	cmp ax, 1
	jz read_byte
	jmp read_error

	read_dword:
	mov ax, WORD PTR es:[si]
	mov dx, WORD PTR es:[si+2]
	mov bx, WORD PTR [checkColour]
	mov cx, WORD PTR [checkColour+2]
	cmp ax, bx
	jne read_error
	cmp cx, dx
	je dword_same
	mov al, 0h
	jmp read_end 
	dword_same:
	mov al, 1h
	jmp read_end 


	read_word:
	mov ax, WORD PTR es:[si]
	mov bx, WORD PTR [checkColour]
	cmp ax, bx
	je word_same
	mov al, 0h
	jmp read_end 
	word_same:
	mov al, 1h
	jmp read_end  

	read_byte:
	mov al, BYTE PTR es:[si]
	mov bl, BYTE PTR [checkColour]
	cmp al, bl
	je byte_same
	mov al, 0h
	jmp read_end 
	byte_same:
	mov al, 1h
	jmp read_end


	read_error:
	mov al, 0h ;default to 0
	read_end:
	mov [sameColour], al
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret

; void SIMPLEFILL (int X, int Y)
; [bp+4] = X
; [bp+6] = Y
simpleFill:
	push bp
	mov bp, sp
	push bx
	push cx
	push dx 

	mov ax, [bp+4] ;ax = X
	mov bx, [bp+6] ;bx = Y
	push ax
	push bx
	call readPixel
	pop bx
	pop ax

	fillUp:
		sub ax, 1		;start left of beginning
		fillLeftU:
			push ax
			push bx
			call readPixel
			pop bx
			pop ax
			mov cl, [sameColour]
			cmp cl, 1h
			je RightU

			push ax
			push bx
			call drawPixel
			pop bx
			pop ax

			sub ax, 1		
			push ax
			push bx
			call readPixel 	;set [sameColour] to 1 if checkColour = Colour at pixel
			pop bx
			pop ax
			mov cl, [sameColour]
			cmp cl, 1h
			jne fillLeftU

		RightU:
		mov ax, [bp+4] ;ax = X
		fillRightU:
			push ax
			push bx
			call readPixel
			pop bx
			pop ax
			mov cl, [sameColour]
			cmp cl, 1h
			je Up

			push ax
			push bx
			call drawPixel
			pop bx
			pop ax

			add ax, 1		
			push ax
			push bx
			call readPixel 	;set [sameColour] to 1 if checkColour = Colour at pixel
			pop bx
			pop ax
			mov cl, [sameColour]
			cmp cl, 1h
			jne fillRightU
		Up:
		mov ax, [bp+4] ;ax = X
		sub bx, 1		
		push ax
		push bx
		call readPixel 	;set [sameColour] to 1 if checkColour = Colour at pixel
		pop bx
		pop ax
		mov cl, [sameColour]
		cmp cl, 1h
		jne fillUp

	mov bx, [bp+6] ;ax = X
	fillDown:
		sub ax, 1		;start left of beginning
		fillLeftD:
			push ax
			push bx
			call readPixel
			pop bx
			pop ax
			mov cl, [sameColour]
			cmp cl, 1h
			je RightD

			push ax
			push bx
			call drawPixel
			pop bx
			pop ax

			sub ax, 1		
			push ax
			push bx
			call readPixel 	;set [sameColour] to 1 if checkColour = Colour at pixel
			pop bx
			pop ax
			mov cl, [sameColour]
			cmp cl, 1h
			jne fillLeftD
		RightD:
		mov ax, [bp+4] ;ax = X
		fillRightD:
			push ax
			push bx
			call readPixel
			pop bx
			pop ax
			mov cl, [sameColour]
			cmp cl, 1h
			je Down

			push ax
			push bx
			call drawPixel
			pop bx
			pop ax

			add ax, 1		
			push ax
			push bx
			call readPixel 	;set [sameColour] to 1 if checkColour = Colour at pixel
			pop bx
			pop ax
			mov cl, [sameColour]
			cmp cl, 1h
			jne fillRightD
		Down:
		mov ax, [bp+4] ;ax = X
		add bx, 1		
		push ax
		push bx
		call readPixel 	;set [sameColour] to 1 if checkColour = Colour at pixel
		pop bx
		pop ax
		mov cl, [sameColour]
		cmp cl, 1h
		jne fillDown


	pop dx
	pop cx
	pop bx
	pop bp
	ret


; The subroutine getche has the following C signature: char getche(void)
; When getche is invoked it reads a single character from the keyboard, echoes that character to the screen (using the function 9 of int 21h), and returns the character to the calling program (in register dl).
; Input: None
; Output: dl: Character read
getche:
	push ax ; Save register ax
	mov ah, 1 ; Reads stdin with echo (the value in al doesn't matter)
	int 21h ; Calls the interrupt
	mov dl, al ; Move character in dl
	pop ax ; Restore ax
	ret ; Returns to the caller



; The subroutine putch has the following C signature: void putch(char c)
; When putch is invoked it receives a single character from the calling program (in register dl) . It display that character on the screen at the current cursor location (using the function 2 of int 21h). It then returns to the calling program. The cursor is updated to the next screen location.
; Input: dl: Character to display
; Output: None
putch:
	push ax ; Save register ax
	mov ah, 2 ; Write character to stdout
	int 21h ; Call the interrupt
	pop ax ; Replace ax where it was
	ret ; Return to the caller



; The subroutine puts has the following C signature: void puts(char *p)
; When puts is invoked it receives a pointer to a string (in register dx). It assumes the string terminates with '\0' (and that Intel x86 uses little-endian). It displays all the characters in the string by invoking putch() in a loop and then terminates.
; Input: dx: Address of string to display
; Output: None
puts:
	; Save the registers on the stack
	push dx
	push bx
	
	; Move the address of the string in bx, because apparently we cannot do "mov dl, [ax]", but we can do "mov dl, [bx]"
	mov bx, dx
	
	puts_loop:
		mov dl, [bx] ; Get the current character
		cmp dl, 0 ; Verify if it is zero
		jz puts_exit ; Exit if it is
		call putch ; Otherwise, print it
		inc bx ; Move the pointer to the next character
		jmp puts_loop ; Restart the loop
	puts_exit:
	
	; Restore the content of the registers
	pop bx
	pop dx
	ret ; Return



; The subroutine gets has the following C signature: void gets(char *p)
; When gets is invoked it receives a pointer to a location in memory (in register dl) that is ready to receive a string. The subroutine gets() invokes getche() in a loop receiving characters from the user and saving each character within the memory space pointed to by p. When the user presses the enter key gets() stops processing. Your program adds a '\0' character to the end of the string, include the enter key in the resultant string.
; Input: dx: Address to store the string
; Output: None
gets:
	; Save the registers on the stack
	push dx
	push bx
	push ax
	
	; Move the address of the string in bx, because apparently we cannot do "mov [ax], dl", but we can do "mov [bx], dl"
	mov bx, dx
	
	gets_loop:
		call getche ; Read a single character and store it in al
		mov [bx], dl ; Move the character in the RAM
		inc bx ; Move the pointer to the next location
		cmp dl, 13 ; Verify if the user pressed the enter key (13 = 0Dh = carriage return)
		jz gets_exit ; If the user pressed enter, exit the loop
		jmp gets_loop ; Otherwise, restart the loop
	gets_exit:
	
	mov byte ptr [bx], 0 ; Put a null character at the end of the string in RAM
	
	; Restore the content of the registers
	pop ax
	pop bx
	pop dx
	ret ; Return


; The subroutine gets has the following C signature: int getInt(void)
; When getInt is invoked it an int from the keyboard and returns it in dl
; Input: None
; Output: An integer in AX
getInt:
	; Save the registers on the stack
	push dx
	push bx
	mov resNum, 0 ; 
	
	
	int_loop:
		call getche ; Read a single character and store it in dl
		cmp dl, 13 ; Verify if the user pressed the enter key (13 = 0Dh = carriage return)
		jz int_exit ; If the user pressed enter, exit the loop
		sub dl, 48 ; Convert to integer
		mov ax, resNum ;Move current result into al
		mul ten ;Multiply current number by ten
		mov dh, 0
		add ax, dx ;Add read number to result Number
		mov resNum, ax ;Store result number
		jmp int_loop ;Restart the loop
	int_exit:
	
	mov ax, resNum ; Place return int in al
	; Now ah + al = resNum i.e. ax is returning resNum
	pop bx
	pop dx
	ret ; Return


; The subroutine puts has the following C signature: void printInt(int)
; When puts is invoked it receives an int and prints it
; Input: int in ax
; Output: None
printInt:
	push bp; Save base pointer
	mov bp, sp ; set bp to current stack pointer

	push ax;
	push bx;
	push dx;
	mov ax, [bp+4] ; read argument passed on stack into ax
	mov bx, 0

	cmp al, 0
	jz zero_in

	ints_loop:
		cmp al, 0 ; Verify if it is zero
		jz ints_exit ; Exit if it is
		div ten ; Divide by ten, result -> al, rem -> ah
		mov dl, ah ; Move digit into dl for printing
		add dl, 48 ; Convert to char
		mov dh, 0 ; ensure dh is 0
		push dx ; save char to print on stack
		add bx, 1 ; add to counter
		mov ah, 0 ; ensure ah is 0 (for mul)
		jmp ints_loop ; Restart the loop
	ints_exit:

	pop_loop:
		cmp bx, 0 ; if counter is empty, stop
		jz pop_exit ; Exit if it is
		pop dx ; pop the highest value to print
		call putch; print it
		sub bx, 1; decrease counter
		jmp pop_loop ; Restart the loop
	pop_exit:
	
	; Restore the content of the registers
	pop dx
	pop bx
	pop ax
	pop bp
	ret ; Return

	zero_in: ; Deals with case where trying to print 0 (ints_loop is autoexited and nothing is printed)
	lea dx, sZero
	call puts; print 0,
	je pop_exit

end start
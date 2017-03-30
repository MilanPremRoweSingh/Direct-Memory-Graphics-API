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
	;This is just the API therefore no main method
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


end start
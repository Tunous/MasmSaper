include MasmSaper.inc

.code
start:
    invoke GetModuleHandle, 0
    mov hInstance, eax
    invoke WinMain, hInstance
    exit eax

WinMain proc hInst:HINSTANCE
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hWnd:HWND

    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra, NULL
    mov wc.cbWndExtra, NULL
    m2m wc.hInstance, hInst
    mov wc.hbrBackground, COLOR_WINDOW + 1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET className

    invoke LoadIcon, 0, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax

    invoke LoadCursor, 0, IDC_ARROW
    mov wc.hCursor, eax

    invoke RegisterClassEx, addr wc
    
    invoke CreateWindowEx,
           0,
           ADDR className,
           ADDR windowTitle,
           WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX,
           CW_USEDEFAULT,
           CW_USEDEFAULT,
           270,
           385,
           0,
           0,
           hInst,
           0

    mov hWnd, eax

    invoke LoadMenu, hInst, 600
    invoke SetMenu, hWnd, eax

    invoke Multiply, GRID_WIDTH, GRID_HEIGHT
    mov GRID_SIZE, eax

    invoke ShowWindow, hWnd, SW_SHOWNORMAL
    invoke UpdateWindow, hWnd

    BeginMessageLoop msg
    EndMessageLoop msg

    return msg.wParam
WinMain endp

TimeCallback proc hWnd:HWND, uMsg:UINT, pMidEvent:DWORD, dwTime:DWORD
    inc gameTime

    invoke RedrawWindow, hWnd, NULL, NULL, RDW_INVALIDATE 

    ret
TimeCallback endp

RevealArea proc x:DWORD, y:DWORD
    LOCAL hasTilesToProcess:BYTE

    mov hasTilesToProcess, TRUE
    
    mov esi, OFFSET viewedTiles
    mov eax, 0
    .WHILE eax < GRID_SIZE
        m2m [esi + 4 * eax], 0
        inc eax
    .ENDW

    invoke ConvertToArrayPos, x, y
    invoke ContinueRevealing, eax

    ret
RevealArea endp

ContinueRevealing proc pos:DWORD
    LOCAL remainder:DWORD
    
    invoke GetArrayElement, OFFSET viewedTiles, pos
    .IF eax == 1
        ret
    .ENDIF

    push ebx

    push esi

    mov esi, OFFSET viewedTiles

    mov ebx, pos
    m2m [esi + 4 * ebx], 1

    invoke RevealAt, pos

    pop esi

    ; Stop revealing if we are no longer on empty area 
    invoke GetArrayElement, OFFSET grid, pos 
    .IF eax != 0
        pop ebx
        ret 
    .ENDIF 
 
    invoke Divide, ebx, GRID_WIDTH
    mov remainder, edx
 
    mov ebx, pos 
 
    ; Left side 
    .IF remainder > 0 
        sub ebx, 1 
        invoke ContinueRevealing, ebx 
         
        .IF ebx >= GRID_WIDTH
            sub ebx, GRID_WIDTH
            invoke ContinueRevealing, ebx
            add ebx, GRID_WIDTH
        .ENDIF 
  
        add ebx, GRID_WIDTH 
 
        .IF ebx < GRID_SIZE 
            invoke ContinueRevealing, ebx 
        .ENDIF 
    .ENDIF 
 
    mov ebx, pos 
 
    mov eax, GRID_WIDTH 
    dec eax 
 
    ; Right side 
    .IF remainder < eax
        add ebx, 1 
        invoke ContinueRevealing, ebx
 
        .IF ebx >= GRID_WIDTH
            sub ebx, GRID_WIDTH
            invoke ContinueRevealing, ebx
            add ebx, GRID_WIDTH
        .ENDIF 
 
        add ebx, GRID_WIDTH 
 
        .IF ebx < GRID_SIZE 
            invoke ContinueRevealing, ebx
        .ENDIF 
    .ENDIF 
 
    mov ebx, pos 
 
    ; Top tile 
    .IF ebx >= GRID_WIDTH 
        sub ebx, GRID_WIDTH 
        invoke ContinueRevealing, ebx 
    .ENDIF 
 
    mov ebx, pos
    add ebx, GRID_WIDTH 
     
    ; Bottom tile 
    .IF ebx < GRID_SIZE 
        invoke ContinueRevealing, ebx 
    .ENDIF 
 
    pop ebx
    ret
ContinueRevealing endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hDC:DWORD
    LOCAL ps:PAINTSTRUCT

    .IF uMsg == WM_CREATE
        invoke LoadBitmap, hInstance, IDB_MINE
        mov mineBitmap, eax

        invoke LoadBitmap, hInstance, IDB_BG
        mov bgBitmap, eax

        invoke LoadBitmap, hInstance, IDB_TILE
        mov tileBitmap, eax

        invoke LoadBitmap, hInstance, IDB_MARKER
        mov markerBitmap, eax
    
    .ELSEIF uMsg == WM_DESTROY
        invoke DeleteObject, mineBitmap
        invoke DeleteObject, bgBitmap
        invoke DeleteObject, tileBitmap
        invoke DeleteObject, markerBitmap
        invoke PostQuitMessage, 0

    .ELSEIF uMsg == WM_COMMAND
        .IF wParam == 500
            invoke NewGame, hWnd

        .ELSEIF wParam == 1000
            invoke PostQuitMessage, 0

        .ELSEIF wParam == 1900
            invoke MessageBox, hWnd, ADDR author, ADDR authorPopupTitle, MB_OK
        .ENDIF

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, ADDR ps
        mov hDC, eax
        invoke Paint, hWnd, hDC
        invoke EndPaint, hWnd, ADDR ps

    .ELSEIF uMsg == WM_LBUTTONDOWN
        invoke HandleMouse, hWnd, lParam, TRUE

    .ELSEIF uMsg == WM_RBUTTONDOWN
        invoke HandleMouse, hWnd, lParam, FALSE

    .ELSE
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    .ENDIF
    
    ret
WndProc endp

Multiply proc a:DWORD, b:DWORD
    push ebx

    xor edx, edx
    mov eax, a
    mov ebx, b
    mul ebx

    pop ebx

    return eax
Multiply endp

Divide proc a:DWORD, b:DWORD
    push ebx

    xor edx, edx
    mov eax, a
    mov ebx, b
    div ebx

    pop ebx

    ret
Divide endp

ConvertToArrayPos proc x:DWORD, y:DWORD
    invoke Multiply, y, GRID_WIDTH
    add eax, x

    ret
ConvertToArrayPos endp

ShuffleArray proc arr:DWORD, arraySize:DWORD
    LOCAL lArraySize  :DWORD

    mov eax, arraySize
    mov lArraySize, eax

    push ebx
    push esi
    push edi

    mov esi, arr
    mov edi, arr
    xor ebx, ebx

    .WHILE lArraySize > 0
        invoke nrandom, arraySize   ; Get the random number within "arraySize" range
        mov ecx, [esi + ebx * 4]    ; Get the incremental pointer
        mov edx, [edi + eax *4 ]    ; Get the random pointer
        mov [esi + ebx * 4], edx    ; Write random pointer back to incremental location
        mov [edi + eax * 4], ecx    ; Write incremental pointer back to random location
        add ebx, 1                  ; Increment the original pointer
        sub lArraySize, 1           ; Decrement the loop counter
    .ENDW

    pop edi
    pop esi
    pop ebx

    ret
ShuffleArray endp

GetArrayElement proc arr:DWORD, i:DWORD
    push esi

    xor edx, edx
    mov esi, arr
    mov eax, i
    mov eax, [esi + 4 * eax]

    pop esi

    ret
GetArrayElement endp

GetArrayElementXY proc arr:DWORD, x:DWORD, y:DWORD
    invoke ConvertToArrayPos, x, y
    invoke GetArrayElement, arr, eax

    ret
GetArrayElementXY endp

IncrementIfMine proc mines:DWORD
    mov ecx, [esi + 4 * ebx]
    .IF ecx == -1
        inc mines
    .ENDIF

    return mines
IncrementIfMine endp

ClearGrid proc
    push esi
    push edi
    push ebx
    
    mov esi, OFFSET grid
    mov edi, OFFSET visibilityArray
    mov ebx, 0

    .WHILE eax < GRID_SIZE
        mov [esi + 4 * eax], ebx
        mov [edi + 4 * eax], ebx
        inc eax
    .ENDW

    pop ebx
    pop edi
    pop esi
    ret
ClearGrid endp

GenerateGrid proc ignoreX:DWORD, ignoreY:DWORD
    LOCAL mines:DWORD
    LOCAL ignorePos:DWORD

    push ebx
    push esi
    push edi
    push ecx
    push edx

    invoke ConvertToArrayPos, ignoreX, ignoreY
    mov ignorePos, eax 

    ; Initialize array holding positions for mines
    mov esi, OFFSET mineGenerationArray
    xor ebx, ebx

    .WHILE ebx < GRID_SIZE
        mov [esi + 4 * ebx], ebx
        inc ebx
    .ENDW

    ; Shuffle it to always get random position
    invoke GetTickCount
    invoke nseed, eax
    invoke ShuffleArray, OFFSET mineGenerationArray, GRID_SIZE

    mov esi, OFFSET grid
    mov edi, OFFSET mineGenerationArray

    invoke ClearGrid

    xor ebx, ebx
    mov edx, -1
    mov eax, 30
    
    ; Select fixed amount of randomized positions for mines
    .WHILE ebx < eax
        mov ecx, [edi + 4 * ebx]                    ; Get position from first array
        .IF ecx == ignorePos                        ; If this position is ignored then we don't want to place mine here
            inc eax                                 ; Let's skip it and take different pos
        .ELSE
            mov [esi + 4 * ecx], edx                ; And place mine at that position in actual array
        .ENDIF
        inc ebx
    .ENDW

    xor ebx, ebx

    .WHILE ebx < GRID_SIZE
        mov mines, 0                                ; Reset count
        mov ecx, [esi + 4 * ebx]                    ; Get grid element

        .IF ecx != -1                               ; Skip mines
            push ebx                                ; Store current position

            invoke Divide, ebx, GRID_WIDTH

            pop ebx
            push ebx

            ; Check for mines at each near position

            ; Left side
            .IF edx > 0
                sub ebx, 1                          ; ...
                invoke IncrementIfMine, mines       ; XO.
                mov mines, eax                      ; ...
                
                .IF ebx >= GRID_WIDTH
                    sub ebx, GRID_WIDTH             ; X..
                    invoke IncrementIfMine, mines   ; .O.
                    mov mines, eax                  ; ...
                    add ebx, GRID_WIDTH
                .ENDIF

                add ebx, GRID_WIDTH

                .IF ebx < GRID_SIZE                 ; ...
                    invoke IncrementIfMine, mines   ; .O.
                    mov mines, eax                  ; X..
                .ENDIF
            .ENDIF

            pop ebx
            push ebx

            mov eax, GRID_WIDTH
            dec eax

            ; Right side
            .IF edx < eax
                add ebx, 1                          ; ...
                invoke IncrementIfMine, mines       ; .OX
                mov mines, eax                      ; ...

                .IF ebx >= GRID_WIDTH
                    sub ebx, GRID_WIDTH             ; ..X
                    invoke IncrementIfMine, mines   ; .O.
                    mov mines, eax                  ; ...
                    add ebx, GRID_WIDTH
                .ENDIF

                add ebx, GRID_WIDTH

                .IF ebx < GRID_SIZE                 ; ...
                    invoke IncrementIfMine, mines   ; .O.
                    mov mines, eax                  ; ..X
                .ENDIF
            .ENDIF

            pop ebx
            push ebx

            mov eax, GRID_WIDTH

            ; Top tile
            .IF ebx >= eax
                sub ebx, GRID_WIDTH                 ; .X.
                invoke IncrementIfMine, mines       ; .O.
                mov mines, eax                      ; ...
            .ENDIF

            pop ebx
            push ebx

            add ebx, GRID_WIDTH
            
            ; Bottom tile
            .IF ebx < GRID_SIZE                     ; ...
                invoke IncrementIfMine, mines       ; .O.
                mov mines, eax                      ; .X.
            .ENDIF

            pop ebx
            mov eax, mines
            mov [esi + 4 * ebx], eax
        .ENDIF

        inc ebx
    .ENDW

    pop edx
    pop ecx
    pop edi
    pop esi
    pop ebx

    ret
GenerateGrid endp

NewGame proc hWnd:HWND
    invoke ClearGrid

    mov gameOver, FALSE
    mov isFirstMove, TRUE
    mov gameTime, 0
    mov leftMines, 30

    invoke RedrawWindow, hWnd, NULL, NULL, RDW_INVALIDATE

    ret
NewGame endp

RevealAt proc i:DWORD
    push esi

    mov esi, OFFSET visibilityArray
    mov eax, i
    m2m [esi + 4 * eax], 1

    pop esi
    ret
RevealAt endp

RevealAtXY proc x:DWORD, y:DWORD
    invoke ConvertToArrayPos, x, y
    invoke RevealAt, eax

    ret
RevealAtXY endp

ToggleMarkerAt proc x:DWORD, y:DWORD
    .IF isFirstMove
        ret
    .ENDIF

    push esi
    push ebx

    mov esi, OFFSET visibilityArray

    invoke ConvertToArrayPos, x, y
    mov ebx, eax

    invoke GetArrayElement, esi, ebx
    .IF eax == 0
        .IF leftMines > 0
            m2m [esi + 4 * ebx], 2
            dec leftMines
        .ENDIF
    .ELSEIF eax == 2
        m2m [esi + 4 * ebx], 0
        inc leftMines
    .ENDIF

    pop ebx
    pop esi
    ret
ToggleMarkerAt endp

RevealAllMines proc
    push ebx

    mov ebx, 0

    .WHILE ebx < GRID_SIZE
        invoke GetArrayElement, OFFSET grid, ebx
        .IF eax == -1
            invoke RevealAt, ebx
        .ENDIF
        inc ebx
    .ENDW

    pop ebx
    ret
RevealAllMines endp

CheckHasWon proc hWnd:HWND
    LOCAL hasWon:BYTE
 
    mov hasWon, TRUE

    push ebx
    mov ebx, 0

    .WHILE ebx < GRID_SIZE
        invoke GetArrayElement, OFFSET visibilityArray, ebx
        .IF !eax
            invoke GetArrayElement, OFFSET grid, ebx
            .IF eax != -1
                mov hasWon, FALSE
                .BREAK
            .ENDIF
        .ENDIF

        inc ebx
    .ENDW

    .IF hasWon
        invoke StopGame, hWnd
        invoke MessageBox, hWnd, ADDR winText, ADDR winTextTitle, MB_OK
    .ENDIF

    pop ebx
    ret
CheckHasWon endp

HandleMouse proc hWnd:HWND, lParam:LPARAM, isLeftClick: BYTE
    LOCAL x:DWORD
    LOCAL y:DWORD
    LOCAL maxX:DWORD
    LOCAL maxY:DWORD

    .IF gameOver
        invoke NewGame, hWnd
        ret
    .ENDIF

    invoke Multiply, 20, GRID_WIDTH
    mov maxX, eax

    invoke Multiply, 20, GRID_HEIGHT
    mov maxY, eax

    mov eax, lParam
    and eax, 0FFFFh
    sub eax, 10

    .IF eax < 0 || eax >= maxX
        ret
    .ENDIF

    invoke Divide, eax, 20
    mov x, eax
    
    mov eax, lParam
    shr eax, 16
    sub eax, 10

    .IF eax < 0 || eax >= maxY
        ret
    .ENDIF

    invoke Divide, eax, 20
    mov y, eax

    .IF isLeftClick && isFirstMove
        invoke GenerateGrid, x, y
        mov isFirstMove, FALSE
        invoke SetTimer, hWnd, ID_TIMER, 1000, OFFSET TimeCallback
    .ENDIF

    .IF isLeftClick
        invoke GetArrayElementXY, OFFSET visibilityArray, x, y
        .IF eax != 2
            invoke GetArrayElementXY, OFFSET grid, x, y
            .IF eax == -1
                invoke StopGame, hWnd
            .ELSE
                .IF eax == 0
                    invoke RevealArea, x, y
                .ELSE
                    invoke RevealAtXY, x, y
                .ENDIF
                invoke CheckHasWon, hWnd
            .ENDIF
        .ENDIF
    .ELSE
        invoke ToggleMarkerAt, x, y
    .ENDIF

    invoke RedrawWindow, hWnd, NULL, NULL, RDW_INVALIDATE 

    ret
HandleMouse endp

StopGame proc hWnd:HWND
    invoke KillTimer, hWnd, ID_TIMER
    mov gameOver, TRUE
    invoke RevealAllMines

    ret
StopGame endp

Paint proc hWnd:DWORD, hDC:HDC
    LOCAL hMemDC:HDC

    invoke CreateCompatibleDC, hDC
    mov hMemDC, eax

    invoke DrawGrid, hDC, hMemDC
    invoke DrawTime, hDC
    invoke DrawMines, hDC

    invoke DeleteDC, hMemDC
    ret
Paint endp

DrawTime proc hDC:HDC
    LOCAL minutes:DWORD
    LOCAL seconds:DWORD
    
    invoke Divide, gameTime, 60
    mov minutes, eax
    mov seconds, edx
    
    invoke dwtoa, minutes, OFFSET drawText
    invoke TextOut, hDC, 30, 315, ADDR drawText, SIZEOF drawText - 1

    invoke TextOut, hDC, 50, 315, ADDR timeDivider, SIZEOF timeDivider

    invoke dwtoa, seconds, OFFSET drawText
    invoke TextOut, hDC, 60, 315, ADDR drawText, SIZEOF drawText - 1

    ret
DrawTime endp

DrawMines proc hDC:HDC
    invoke TextOut, hDC, 210, 315, ADDR star, SIZEOF star - 1
    invoke dwtoa, leftMines, OFFSET drawText
    invoke TextOut, hDC, 220, 315, ADDR drawText, SIZEOF drawText - 1

    ret
DrawMines endp

DrawBitmap proc hDC:HDC, hMemDC:HDC, bitmap:DWORD, x:DWORD, y:DWORD
    LOCAL oldObject:DWORD

    invoke SelectObject, hMemDC, bitmap
    mov oldObject, eax

    invoke BitBlt, hDC, x, y, 20, 20, hMemDC, 0, 0, SRCCOPY

    invoke SelectObject, hMemDC, oldObject

    ret
DrawBitmap endp

DrawGrid proc hDC:HDC, hMemDC:HDC
    LOCAL brush:DWORD
    LOCAL oldBrush:DWORD
    LOCAL i:DWORD
    LOCAL j:DWORD
    LOCAL x:DWORD
    LOCAL y:DWORD
    LOCAL endX:DWORD
    LOCAL endY:DWORD
    LOCAL color:DWORD
    LOCAL originalAlign:DWORD
    LOCAL originalBkMode:DWORD
    LOCAL currentCount:DWORD
    
    ; Initialize brush
    invoke GetSysColor, COLOR_BTNSHADOW
    mov color, eax
    invoke CreateSolidBrush, color
    mov brush, eax
    invoke SelectObject, hDC, brush
    mov oldBrush, eax

    ; Make the background behind text transparent
    invoke SetBkMode, hDC, TRANSPARENT
    mov originalBkMode, eax

    invoke GetTextAlign, hDC
    mov originalAlign, eax
    invoke SetTextAlign, hDC, TA_CENTER or VTA_CENTER or TA_NOUPDATECP
    
    mov i, 0
    mov x, 10
    mov endX, 30

    .WHILE i < 12
        mov j, 0
        mov y, 10
        mov endY, 30
        
        .WHILE j < 15
            ;invoke Rectangle, hDC, x, y, endX, endY

            invoke GetArrayElementXY, OFFSET visibilityArray, i, j

            .IF eax != 0
                .IF eax == 1
                    invoke GetArrayElementXY, OFFSET grid, i, j
                    mov currentCount, eax
                    .IF eax == -1
                        invoke DrawBitmap, hDC, hMemDC, mineBitmap, x, y
                    .ELSE
                        invoke dwtoa, eax, OFFSET countText
                        invoke DrawBitmap, hDC, hMemDC, bgBitmap, x, y

                        .IF currentCount > 0
                            push x
                            push y
                            add x, 10
                            add y, 2


                            invoke TextOut, hDC, x, y, ADDR countText, SIZEOF countText - 1

                            pop y
                            pop x
                        .ENDIF
                    .ENDIF
                .ELSE
                    invoke DrawBitmap, hDC, hMemDC, markerBitmap, x, y
                .ENDIF
            .ELSE
                invoke DrawBitmap, hDC, hMemDC, tileBitmap, x, y
            .ENDIF
            
            add y, 20
            add endY, 20
            inc j
        .ENDW
        
        add x, 20
        add endX, 20
        inc i
    .ENDW

    ; Cleanup
    invoke SelectObject, hDC, oldBrush
    invoke DeleteObject, brush
    invoke SetBkMode, hDC, originalBkMode
    invoke SetTextAlign, hDC, originalAlign

    ret
DrawGrid endp

end start

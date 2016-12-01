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
           255,
           375,
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

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hDC:DWORD
    LOCAL ps:PAINTSTRUCT
    
    .IF uMsg == WM_DESTROY
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
                
                sub ebx, GRID_WIDTH
                .IF ebx >= 0                        ; X..
                    invoke IncrementIfMine, mines   ; .O.
                    mov mines, eax                  ; ...
                .ENDIF

                add ebx, GRID_WIDTH
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

                sub ebx, GRID_WIDTH
                .IF ebx >= 0                        ; ..X
                    invoke IncrementIfMine, mines   ; .O.
                    mov mines, eax                  ; ...
                .ENDIF

                add ebx, GRID_WIDTH
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
    push esi
    push ebx

    mov esi, OFFSET visibilityArray

    invoke ConvertToArrayPos, x, y
    mov ebx, eax

    invoke GetArrayElement, esi, ebx
    .IF eax == 0
        m2m [esi + 4 * ebx], 2
        dec leftMines
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
        invoke MessageBox, hWnd, ADDR winText, ADDR winTextTitle, MB_OK
        invoke StopGame, hWnd
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

    invoke Multiply, 19, GRID_WIDTH
    mov maxX, eax

    invoke Multiply, 19, GRID_HEIGHT
    mov maxY, eax

    mov eax, lParam
    and eax, 0FFFFh
    sub eax, 10

    .IF eax < 0 || eax >= maxX
        ret
    .ENDIF

    invoke Divide, eax, 19
    mov x, eax
    
    mov eax, lParam
    shr eax, 16
    sub eax, 10

    .IF eax < 0 || eax >= maxY
        ret
    .ENDIF

    invoke Divide, eax, 19
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
                invoke RevealAtXY, x, y
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

Paint proc hWnd:DWORD, hDC:DWORD
    invoke DrawGrid, hDC
    invoke DrawTime, hDC
    invoke DrawMines, hDC
    ret
Paint endp

DrawTime proc hDC:DWORD
    LOCAL minutes:DWORD
    LOCAL seconds:DWORD
    
    invoke Divide, gameTime, 60
    mov minutes, eax
    mov seconds, edx
    
    invoke dwtoa, minutes, OFFSET drawText
    invoke TextOut, hDC, 30, 305, ADDR drawText, SIZEOF drawText - 1

    invoke TextOut, hDC, 50, 305, ADDR timeDivider, SIZEOF timeDivider

    invoke dwtoa, seconds, OFFSET drawText
    invoke TextOut, hDC, 60, 305, ADDR drawText, SIZEOF drawText - 1

    ret
DrawTime endp

DrawMines proc hDC:DWORD
    invoke dwtoa, leftMines, OFFSET drawText
    invoke TextOut, hDC, 150, 305, ADDR drawText, SIZEOF drawText - 1

    ret
DrawMines endp

DrawGrid proc hDC:DWORD
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
            invoke Rectangle, hDC, x, y, endX, endY

            invoke GetArrayElementXY, OFFSET visibilityArray, i, j

            .IF eax != 0
                push x
                push y
                add x, 10
                add y, 2

                .IF eax == 1
                    invoke GetArrayElementXY, OFFSET grid, i, j
                    .IF eax == -1
                        invoke TextOut, hDC, x, y, ADDR star, SIZEOF star - 1
                    .ELSE
                        invoke dwtoa, eax, OFFSET countText
                        invoke TextOut, hDC, x, y, ADDR countText, SIZEOF countText - 1
                    .ENDIF
                .ELSE
                     invoke TextOut, hDC, x, y, ADDR marker, SIZEOF marker - 1
                .ENDIF

                pop y
                pop x
            .ENDIF
            
            add y, 19
            add endY, 19
            inc j
        .ENDW
        
        add x, 19
        add endX, 19
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

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

    mov hMainWnd, eax

    invoke LoadMenu, hInst, 600
    invoke SetMenu, hMainWnd, eax

    invoke GetTickCount
    invoke nseed, eax

    invoke ShowWindow, hMainWnd, SW_SHOWNORMAL
    invoke UpdateWindow, hMainWnd

    BeginMessageLoop msg
    EndMessageLoop msg

    return msg.wParam
WinMain endp

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

        invoke LoadBitmap, hInstance, IDB_MINE_CORRECT
        mov mineCorrectBitmap, eax

        invoke LoadBitmap, hInstance, IDB_MINE_INVALID
        mov mineInvalidBitmap, eax
    
    .ELSEIF uMsg == WM_DESTROY
        invoke DeleteObject, mineBitmap
        invoke DeleteObject, bgBitmap
        invoke DeleteObject, tileBitmap
        invoke DeleteObject, markerBitmap
        invoke DeleteObject, mineCorrectBitmap
        invoke DeleteObject, mineInvalidBitmap
        invoke PostQuitMessage, 0

    .ELSEIF uMsg == WM_COMMAND
        .IF wParam == 500
            invoke NewGame, hWnd

        .ELSEIF wParam == 1000
            invoke PostQuitMessage, 0

        .ELSEIF wParam == 501
            invoke DialogBoxParam, hInstance, ADDR dialogName, 0, ADDR DialogProc, 0
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

DialogProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .IF uMsg == WM_INITDIALOG
        invoke SendDlgItemMessage, hWnd, 202, UDM_SETRANGE32, 1, 100
        invoke SetDlgItemInt, hWnd, 201, minesCount, FALSE
        invoke SetFocus, hWnd

    .ELSEIF uMsg == WM_CLOSE
        invoke EndDialog, hWnd, NULL

    .ELSEIF uMsg == WM_COMMAND
        .IF wParam == 203
            invoke GetDlgItemInt, hWnd, 201, NULL, FALSE
            mov minesCount, eax
            .IF minesCount > 100
                mov minesCount, 100
            .ELSEIF minesCount < 1
                mov minesCount, 1
            .ENDIF
            invoke EndDialog, hWnd, NULL
            invoke StopGame, hMainWnd
            invoke NewGame, hMainWnd
        .ENDIF
    .ENDIF

    xor eax, eax
    ret
DialogProc endp

; ******************************************************************************
; Utility procedures
; ******************************************************************************

Multiply proc a:DWORD, b:DWORD
    push ebx

    xor edx, edx
    mov eax, a
    mov ebx, b
    mul ebx

    pop ebx

    ret
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
        mov edx, [edi + eax * 4]    ; Get the random pointer
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

; ******************************************************************************
; Grid generation
; ******************************************************************************

ClearGrid proc
    push esi
    push edi
    
    mov esi, OFFSET grid
    mov edi, OFFSET visibilityArray
    xor eax, eax

    .WHILE eax < GRID_SIZE
        m2m [esi + 4 * eax], 0
        m2m [edi + 4 * eax], 0
        inc eax
    .ENDW

    pop edi
    pop esi
    ret
ClearGrid endp

GenerateGrid proc ignoreX:DWORD, ignoreY:DWORD
    LOCAL ignorePos:DWORD

    push ebx
    push esi
    push edi
    push ecx

    invoke InitMineGenArray

    ; Calculate the position at which we shouldn't place a mine
    invoke ConvertToArrayPos, ignoreX, ignoreY
    mov ignorePos, eax 

    mov esi, OFFSET grid
    mov edi, OFFSET mineGenerationArray
    xor ebx, ebx
    mov eax, minesCount
    
    ; Select fixed amount of randomized positions for mines
    .WHILE ebx < eax
        mov ecx, [edi + 4 * ebx]                    ; Get position from first array
        .IF ecx == ignorePos                        ; If this position is ignored then we don't want to place mine here
            inc eax                                 ; Let's skip it and take different position
        .ELSE
            m2m [esi + 4 * ecx], MINE               ; Place mine at the position in grid array
        .ENDIF
        inc ebx
    .ENDW

    xor ebx, ebx

    .WHILE ebx < GRID_SIZE
        mov ecx, [esi + 4 * ebx]

        ; Skip mines
        .IF ecx == MINE
            inc ebx
            .CONTINUE
        .ENDIF

        invoke GridTileAction, ebx, FALSE
        m2m [esi + 4 * ebx], eax

        inc ebx
    .ENDW

    pop ecx
    pop edi
    pop esi
    pop ebx

    ret
GenerateGrid endp

GridTileAction proc pos:DWORD, revealTiles:BYTE
    LOCAL mines:DWORD
    LOCAL remainder:DWORD

    push ebx

    mov mines, 0
    mov ebx, pos

    invoke Divide, ebx, GRID_WIDTH
    mov remainder, edx

    .IF remainder > 0
        ; ...
        ; XO.
        ; ...
        sub ebx, 1
        .IF revealTiles
            invoke RevealAreaStep, ebx
        .ELSE
            invoke IncrementIfMine, mines
            mov mines, eax
        .ENDIF

        ; X..
        ; .O.
        ; ...
        .IF ebx >= GRID_WIDTH
            sub ebx, GRID_WIDTH
            .IF revealTiles
                invoke RevealAreaStep, ebx
            .ELSE
                invoke IncrementIfMine, mines
                mov mines, eax
            .ENDIF
            add ebx, GRID_WIDTH
        .ENDIF

        add ebx, GRID_WIDTH

        ; ...
        ; .O.
        ; X..
        .IF ebx < GRID_SIZE
            .IF revealTiles
                invoke RevealAreaStep, ebx
            .ELSE
                invoke IncrementIfMine, mines
                mov mines, eax
            .ENDIF
        .ENDIF

        mov ebx, pos
    .ENDIF

    .IF remainder < GRID_WIDTH - 1
        ; ...
        ; .OX
        ; ...
        add ebx, 1
        .IF revealTiles
            invoke RevealAreaStep, ebx
        .ELSE
            invoke IncrementIfMine, mines
            mov mines, eax
        .ENDIF

        ; ..X
        ; .O.
        ; ...
        .IF ebx >= GRID_WIDTH
            sub ebx, GRID_WIDTH
            .IF revealTiles
                invoke RevealAreaStep, ebx
            .ELSE
                invoke IncrementIfMine, mines
                mov mines, eax
            .ENDIF
            add ebx, GRID_WIDTH
        .ENDIF

        ; ...
        ; .O.
        ; ..X
        add ebx, GRID_WIDTH

        .IF ebx < GRID_SIZE
            .IF revealTiles
                invoke RevealAreaStep, ebx
            .ELSE
                invoke IncrementIfMine, mines
                mov mines, eax
            .ENDIF
        .ENDIF

        mov ebx, pos
    .ENDIF

    ; .X.
    ; .O.
    ; ...
    .IF ebx >= GRID_WIDTH
        sub ebx, GRID_WIDTH
        .IF revealTiles
            invoke RevealAreaStep, ebx
        .ELSE
            invoke IncrementIfMine, mines
            mov mines, eax
        .ENDIF

        mov ebx, pos
    .ENDIF

    ; ...
    ; .O.
    ; .X.
    add ebx, GRID_WIDTH
    .IF ebx < GRID_SIZE
        .IF revealTiles
            invoke RevealAreaStep, ebx
        .ELSE
            invoke IncrementIfMine, mines
            mov mines, eax
        .ENDIF
    .ENDIF

    pop ebx

    return mines
GridTileAction endp

InitMineGenArray proc
    push esi

    mov esi, OFFSET mineGenerationArray
    xor eax, eax

    .WHILE eax < GRID_SIZE
        mov [esi + 4 * eax], eax
        inc eax
    .ENDW

    invoke ShuffleArray, esi, GRID_SIZE
    invoke ClearGrid

    pop esi
    ret
InitMineGenArray endp

IncrementIfMine proc mines:DWORD
    mov eax, [esi + 4 * ebx]
    .IF eax == MINE
        inc mines
    .ENDIF

    return mines
IncrementIfMine endp

; ******************************************************************************
; Game round management
; ******************************************************************************

NewGame proc hWnd:HWND
    invoke ClearGrid

    mov gameOver, FALSE
    mov isFirstMove, TRUE
    mov gameTime, 0
    m2m leftMines, minesCount

    invoke RedrawWindow, hWnd, NULL, NULL, RDW_INVALIDATE

    ret
NewGame endp

StopGame proc hWnd:HWND
    invoke KillTimer, hWnd, ID_TIMER
    mov gameOver, TRUE
    invoke RevealAllMines

    ret
StopGame endp

CheckHasWon proc hWnd:HWND
    LOCAL hasWon:BYTE
 
    mov hasWon, TRUE

    push ebx
    mov ebx, 0

    .WHILE ebx < GRID_SIZE
        invoke GetArrayElement, OFFSET visibilityArray, ebx
        .IF !eax
            invoke GetArrayElement, OFFSET grid, ebx
            .IF eax != MINE
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

TimeCallback proc hWnd:HWND, uMsg:UINT, pMidEvent:DWORD, dwTime:DWORD
    inc gameTime

    invoke RedrawWindow, hWnd, NULL, NULL, RDW_INVALIDATE 

    ret
TimeCallback endp

; ******************************************************************************
; Tile revealing
; ******************************************************************************

RevealAt proc i:DWORD, isSpecialReveal:BYTE
    push esi
    push ebx

    mov esi, OFFSET visibilityArray
    mov eax, i

    mov ebx, [esi + 4 * eax]

    .IF isSpecialReveal && ebx == 2
        m2m [esi + 4 * eax], 3
    .ELSE
        m2m [esi + 4 * eax], 1
    .ENDIF

    pop ebx
    pop esi
    ret
RevealAt endp

RevealAtXY proc x:DWORD, y:DWORD
    invoke ConvertToArrayPos, x, y
    invoke RevealAt, eax, FALSE

    ret
RevealAtXY endp

RevealAllMines proc
    push ebx

    mov ebx, 0

    .WHILE ebx < GRID_SIZE
        invoke GetArrayElement, OFFSET grid, ebx
        .IF eax == MINE
            invoke RevealAt, ebx, TRUE
        .ENDIF
        inc ebx
    .ENDW

    pop ebx
    ret
RevealAllMines endp

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
    invoke RevealAreaStep, eax

    ret
RevealArea endp

RevealAreaStep proc pos:DWORD
    ; Skip already viewed tiles
    invoke GetArrayElement, OFFSET viewedTiles, pos
    .IF eax == TRUE
        ret
    .ENDIF

    push ebx
    push esi

    ; Mark tile as viewed
    mov esi, OFFSET viewedTiles
    mov ebx, pos
    m2m [esi + 4 * ebx], TRUE

    pop esi
    pop ebx

    ; Reveal the tile
    invoke RevealAt, pos, FALSE

    ; Stop revealing if we are no longer on empty area 
    invoke GetArrayElement, OFFSET grid, pos 
    .IF eax != 0
        ret 
    .ENDIF

    invoke GridTileAction, pos, TRUE
 
    ret
RevealAreaStep endp

; ******************************************************************************
; Mouse handling
; ******************************************************************************

HandleMouse proc hWnd:HWND, lParam:LPARAM, isLeftClick: BYTE
    LOCAL x:DWORD
    LOCAL y:DWORD
    LOCAL maxX:DWORD
    LOCAL maxY:DWORD

    .IF gameOver
        invoke NewGame, hWnd
        ret
    .ENDIF

    invoke Multiply, TILE_SIZE, GRID_WIDTH
    mov maxX, eax

    invoke Multiply, TILE_SIZE, GRID_HEIGHT
    mov maxY, eax

    mov eax, lParam
    and eax, 0FFFFh
    sub eax, 10

    .IF eax < 0 || eax >= maxX
        ret
    .ENDIF

    invoke Divide, eax, TILE_SIZE
    mov x, eax
    
    mov eax, lParam
    shr eax, 16
    sub eax, 10

    .IF eax < 0 || eax >= maxY
        ret
    .ENDIF

    invoke Divide, eax, TILE_SIZE
    mov y, eax

    .IF isLeftClick && isFirstMove
        invoke GenerateGrid, x, y
        mov isFirstMove, FALSE
        invoke SetTimer, hWnd, ID_TIMER, 1000, OFFSET TimeCallback
    .ENDIF

    invoke ConvertToArrayPos, x, y
    mov lastClickPosition, eax

    .IF isLeftClick
        invoke GetArrayElementXY, OFFSET visibilityArray, x, y
        .IF eax != 2
            invoke GetArrayElementXY, OFFSET grid, x, y
            .IF eax == MINE
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

; ******************************************************************************
; Drawing procedures
; ******************************************************************************

Paint proc hWnd:DWORD, hDC:HDC
    LOCAL hMemDC:HDC

    invoke CreateCompatibleDC, hDC
    mov hMemDC, eax

    invoke DrawGrid, hDC, hMemDC
    invoke DrawTime, hDC
    invoke DrawMines, hDC, hMemDC

    invoke DeleteDC, hMemDC
    ret
Paint endp

DrawTime proc hDC:HDC
    LOCAL minutes:DWORD
    LOCAL seconds:DWORD
    
    invoke Divide, gameTime, 60
    mov minutes, eax
    mov seconds, edx
    
    invoke dwtoa, minutes, OFFSET timeText
    invoke TextOut, hDC, 30, 301, ADDR timeText, SIZEOF timeText - 1

    invoke TextOut, hDC, 50, 301, ADDR timeDivider, SIZEOF timeDivider - 1

    invoke dwtoa, seconds, OFFSET timeText
    invoke TextOut, hDC, 60, 301, ADDR timeText, SIZEOF timeText - 1

    ret
DrawTime endp

DrawMines proc hDC:HDC, hMemDC:HDC
    invoke DrawBitmap, hDC, hMemDC, mineBitmap, 192, 300
    invoke dwtoa, leftMines, OFFSET minesCountText
    invoke TextOut, hDC, 215, 301, ADDR minesCountText, SIZEOF minesCountText - 1

    ret
DrawMines endp

DrawBitmap proc hDC:HDC, hMemDC:HDC, bitmap:DWORD, x:DWORD, y:DWORD
    LOCAL oldObject:DWORD

    invoke SelectObject, hMemDC, bitmap
    mov oldObject, eax

    mov eax, TILE_SIZE
    sub eax, 1

    invoke BitBlt, hDC, x, y, eax, eax, hMemDC, 0, 0, SRCCOPY

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
    LOCAL originalAlign:DWORD
    LOCAL originalBkMode:DWORD
    LOCAL currentCount:DWORD
    
    ; Initialize brush
    invoke CreateSolidBrush, Black
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
    mov x, 11

    .WHILE i < GRID_WIDTH
        mov j, 0
        mov y, 11
        
        .WHILE j < GRID_HEIGHT
            invoke GetArrayElementXY, OFFSET visibilityArray, i, j

            .IF eax == 1
                invoke GetArrayElementXY, OFFSET grid, i, j
                mov currentCount, eax

                .IF currentCount == MINE
                    ; Draw mine
                    invoke ConvertToArrayPos, i, j
                    .IF eax == lastClickPosition
                        invoke DrawBitmap, hDC, hMemDC, mineInvalidBitmap, x, y
                    .ELSE
                        invoke DrawBitmap, hDC, hMemDC, mineBitmap, x, y
                    .ENDIF

                .ELSE
                    ; Draw background
                    invoke dwtoa, eax, OFFSET countText
                    invoke DrawBitmap, hDC, hMemDC, bgBitmap, x, y

                    .IF currentCount > 0
                        ; Draw number
                        add x, 9
                        add y, 1

                        .IF currentCount == 1
                            mov eax, 16711757
                        .ELSEIF currentCount == 2
                            mov eax, 34641
                        .ELSEIF currentCount == 3
                            mov eax, 8615580
                        .ELSEIF currentCount == 4
                            mov eax, 1911635
                        .ELSEIF currentCount == 5
                            mov eax, 11227702
                        .ELSEIF currentCount == 6
                            mov eax, 8615580
                        .ELSEIF currentCount == 7
                            mov eax, 1911635
                        .ELSE
                            mov eax, 6248271
                        .ENDIF

                        invoke SetTextColor, hDC, eax
                        push eax

                        invoke TextOut, hDC, x, y, ADDR countText, SIZEOF countText - 1

                        pop eax
                        invoke SetTextColor, hDC, eax

                        sub x, 9
                        sub y, 1
                    .ENDIF
                .ENDIF

            .ELSEIF eax == 2
                ; Draw marker
                invoke DrawBitmap, hDC, hMemDC, markerBitmap, x, y

            .ELSEIF eax == 3
                ; Draw correctly marked mine
                invoke DrawBitmap, hDC, hMemDC, mineCorrectBitmap, x, y

            .ELSE
                ; Draw empty tile
                invoke DrawBitmap, hDC, hMemDC, tileBitmap, x, y
            .ENDIF

            mov eax, TILE_SIZE
            add y, eax
            inc j
        .ENDW

        mov eax, TILE_SIZE
        add x, eax
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

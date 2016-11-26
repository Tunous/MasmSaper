.386
.model flat, stdcall
option casemap:none

include MasmSaper.inc

.data
    star db "*", 0

.data?
    mineGenerationArray db 180 dup (?)

.const
    GRID_WIDTH DWORD 12
    GRID_HEIGHT DWORD 15

.code
start:
    invoke GetModuleHandle, 0
    mov hInstance, eax
    invoke GetCommandLine
    mov CommandLine, eax
    invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess, eax

; いいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいい�

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
        mov ecx, [esi+ebx*4]        ; Get the incremental pointer
        mov edx, [edi+eax*4]        ; Get the random pointer
        mov [esi+ebx*4], edx        ; Write random pointer back to incremental location
        mov [edi+eax*4], ecx        ; Write incremental pointer back to random location
        add ebx, 1                  ; Increment the original pointer
        sub lArraySize, 1           ; Decrement the loop counter
    .ENDW

    pop edi
    pop esi
    pop ebx

    ret
ShuffleArray endp

; いいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいい�

GenerateGrid proc
    LOCAL gridSize:DWORD

    push ebx
    push esi
    push edi
    push ecx
    push edx

    ; Calculate size of the grid: width * height
    mov eax, GRID_WIDTH
    mov ebx, GRID_HEIGHT
    mul ebx
    mov gridSize, eax   

    ; Initialize array holding positions for mines
    mov esi, OFFSET mineGenerationArray
    xor ebx, ebx

    .WHILE ebx < gridSize
        mov [esi + 4 * ebx], ebx
        inc ebx
    .ENDW

    ; Shuffle it to always get random position
    invoke GetTickCount
    invoke nseed, eax
    invoke ShuffleArray, OFFSET mineGenerationArray, gridSize

    ; Select fixed amount of randomized positions for mines
    mov esi, OFFSET grid
    mov edi, OFFSET mineGenerationArray
    xor ebx, ebx
    
    mov edx, -1                     ; Mine is identified by -1
    
    .WHILE ebx < 30
        mov ecx, [edi + 4 * ebx]    ; Get position from first array
        mov [esi + 4 * ecx], edx    ; And place mine at that position in actual array
        inc ebx
    .ENDW

    pop edx
    pop ecx
    pop edi
    pop esi
    pop ebx

    ret
GenerateGrid endp

GetGridElement proc x:DWORD, y:DWORD
    ; GRID_WIDTH * y + x
    mov eax, GRID_WIDTH
    mov ecx, y
    mul ecx
    add eax, x

    mov esi, OFFSET grid
    mov eax, [esi + 4 * eax]

    ret
GetGridElement endp

; いいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいい�

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, cmdLine:LPSTR, cmdShow:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hWnd:HWND

    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, offset WndProc
    mov wc.cbClsExtra, NULL
    mov wc.cbWndExtra, NULL

    push hInst
    pop wc.hInstance

    mov wc.hbrBackground, COLOR_WINDOW + 1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, offset className

    invoke LoadIcon, 0, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax

    invoke LoadCursor, 0, IDC_ARROW
    mov wc.hCursor, eax

    invoke RegisterClassEx, addr wc
    
    invoke CreateWindowEx,
           0,
           addr className,
           addr windowTitle,
           WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX,
           CW_USEDEFAULT,
           CW_USEDEFAULT,
           255,
           355,
           0,
           0,
           hInst,
           0

    mov hWnd, eax

    invoke LoadMenu, hInst, 600
    invoke SetMenu, hWnd, eax

    invoke GenerateGrid

    invoke ShowWindow, hWnd, SW_SHOWNORMAL
    invoke UpdateWindow, hWnd

    .WHILE TRUE
        invoke GetMessage, addr msg, 0, 0, 0
        .BREAK .IF (!eax)
        invoke TranslateMessage, addr msg
        invoke DispatchMessage, addr msg
    .ENDW
    mov eax, msg.wParam
    ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hDC:DWORD
    LOCAL Ps:PAINTSTRUCT
    
    .IF uMsg == WM_DESTROY
        invoke PostQuitMessage, 0
    .ELSEIF uMsg == WM_COMMAND
        .IF wParam == 1000
            invoke PostQuitMessage, 0
        .ELSEIF wParam == 1900
            invoke MessageBox, hWnd, addr author, addr authorPopupTitle, MB_OK
        .ENDIF
    .ELSEIF uMsg == WM_CREATE
        ;szText button1, "PRZYCISK"
        ;invoke PushButton, addr button1, hWnd, 10, 10, 100, 20, 1900
    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr Ps
        mov hDC, eax
        invoke Paint, hWnd, hDC
        invoke EndPaint, hWnd, addr Ps
    .ELSE
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
    
    xor eax, eax
    ret
WndProc endp

Paint proc hWnd:DWORD, hDC:DWORD
    invoke DrawGrid, hDC
    ret
Paint endp

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

            invoke GetGridElement, i, j

            .IF eax == -1
                push x
                push y
                add x, 10
                add y, 2

                ;invoke dwtoa, eax, offset lpszNumber
                invoke TextOut, hDC, x, y, addr star, sizeof star - 1
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

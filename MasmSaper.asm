.386
.model flat, stdcall
option casemap:none

include MasmSaper.inc

.code
start:
    invoke GetModuleHandle, 0
    mov hInstance, eax
    invoke GetCommandLine
    mov CommandLine, eax
    invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess, eax

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
           270,
           365,
           0,
           0,
           hInst,
           0

    mov hWnd, eax

    invoke LoadMenu, hInst, 600
    invoke SetMenu, hWnd, eax

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

    
    ; Initialize brush
    invoke GetSysColor, COLOR_BTNSHADOW
    mov color, eax
    invoke CreateSolidBrush, color
    mov brush, eax
    invoke SelectObject, hDC, brush
    mov oldBrush, eax
    
    mov i, 0
    mov x, 10
    mov endX, 30

    .WHILE i < 10
        mov j, 0
        mov y, 10
        mov endY, 30
        
        .WHILE j < 12
            invoke Rectangle, hDC, x, y, endX, endY
            add y, 25
            add endY, 25

            inc j
        .ENDW
        
        add x, 25
        add endX, 25
        
        inc i
    .ENDW

    ; Cleanup
    invoke SelectObject, hDC, oldBrush
    invoke DeleteObject, brush

    ret
DrawGrid endp

end start

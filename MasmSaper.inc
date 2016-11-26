include \masm32\include\masm32rt.inc

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :HWND, :UINT, :WPARAM, :LPARAM
Paint proto :DWORD, :DWORD
DrawGrid proto :DWORD


.data?
    hInstance HINSTANCE ?
    CommandLine LPSTR ?
    lpszNumber db 2 dup (?)

.data
    windowTitle      db "Saper", 0
    authorPopupTitle db "Autor", 0
    author           db "Lukasz Rutkowski", 0
    className        db "WinClass", 0
    grid             DWORD 180 dup (?)
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib

include \masm32\macros\macros.asm


WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :HWND, :UINT, :WPARAM, :LPARAM
Paint proto :DWORD, :DWORD
DrawGrid proto :DWORD


.data?
    hInstance HINSTANCE ?
    CommandLine LPSTR ?

.data
    windowTitle      db "Saper", 0
    authorPopupTitle db "Autor", 0
    author           db "Lukasz Rutkowski", 0
    className        db "WinClass", 0
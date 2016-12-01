.386
.model flat, stdcall
option casemap :none

; include files
; ~~~~~~~~~~~~~
include \masm32\include\windows.inc
include \masm32\include\masm32.inc
include \masm32\include\gdi32.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc

; macros
; ~~~~~~
include \masm32\macros\macros.asm

; libraries
; ~~~~~~~~~
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib


WinMain proto               :HINSTANCE
WndProc proto               :HWND, :UINT, :WPARAM, :LPARAM

Multiply proto              :DWORD, :DWORD
Divide proto                :DWORD, :DWORD

ConvertToArrayPos proto     :DWORD, :DWORD
ShuffleArray proto          :DWORD, :DWORD
GetArrayElement proto       :DWORD, :DWORD
GetArrayElementXY proto     :DWORD, :DWORD, :DWORD

IncrementIfMine proto       :DWORD
GenerateGrid proto          :DWORD, :DWORD
NewGame proto               :HWND
StopGame proto              :HWND
RevealAt proto              :DWORD
RevealAtXY proto            :DWORD, :DWORD
RevealAllMines proto
CheckHasWon proto           :HWND
ClearGrid proto

HandleMouse proto           :HWND, :LPARAM, :BYTE

Paint proto                 :DWORD, :DWORD
DrawGrid proto              :DWORD
DrawTime proto              :DWORD

.const
    GRID_WIDTH              DD 12
    GRID_HEIGHT             DD 15
    ID_TIMER                DD 1001

.data
    windowTitle             DB "Saper", 0
    authorPopupTitle        DB "Autor", 0
    author                  DB "Lukasz Rutkowski", 0
    className               DB "WinClass", 0
    star                    DB "*", 0
    marker                  DB "!", 0
    gameOver                DB FALSE
    winTextTitle            DB "Wygrana", 0
    winText                 DB ":D", 0
    grid                    DD 180 DUP (0)
    visibilityArray         DD 180 DUP (0)
    isFirstMove             DB TRUE
    gameTime                DD 0


.data?
    GRID_SIZE               DD ?
    hInstance               HINSTANCE ?
    lpszNumber              DB 2 DUP (?)
    rpszNumber              DB 16 DUP (?)
    mineGenerationArray     DD 180 DUP (?)

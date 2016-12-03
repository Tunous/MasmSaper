.386
.model flat, stdcall
option casemap :none

; ********************************************************************
; Include files
; ********************************************************************

include \masm32\include\windows.inc
include \masm32\include\masm32.inc
include \masm32\include\gdi32.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc


; ********************************************************************
; Macros
; ********************************************************************

include \masm32\macros\macros.asm


; ********************************************************************
; Libraries
; ********************************************************************

includelib \masm32\lib\masm32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib


; ********************************************************************
; Prototypes
; ********************************************************************

WinMain proto               :HINSTANCE
WndProc proto               :HWND, :UINT, :WPARAM, :LPARAM

Multiply proto              :DWORD, :DWORD
Divide proto                :DWORD, :DWORD
ConvertToArrayPos proto     :DWORD, :DWORD
ShuffleArray proto          :DWORD, :DWORD
GetArrayElement proto       :DWORD, :DWORD
GetArrayElementXY proto     :DWORD, :DWORD, :DWORD

ClearGrid proto
GenerateGrid proto          :DWORD, :DWORD
IncrementIfMine proto       :DWORD

NewGame proto               :HWND
StopGame proto              :HWND
CheckHasWon proto           :HWND
TimeCallback proto          :HWND, :UINT, :DWORD, :DWORD

RevealAt proto              :DWORD
RevealAtXY proto            :DWORD, :DWORD
RevealAllMines proto
RevealArea proto            :DWORD, :DWORD
RevealAreaStep proto        :DWORD

HandleMouse proto           :HWND, :LPARAM, :BYTE
ToggleMarkerAt proto        :DWORD, :DWORD

Paint proto                 :DWORD, :DWORD
DrawTime proto              :HDC
DrawMines proto             :HDC
DrawGrid proto              :HDC, :HDC


; ********************************************************************
; Data
; ********************************************************************

IDB_MINE equ                1
IDB_BG equ                  2
IDB_TILE equ                3
IDB_MARKER equ              4

.const
    GRID_WIDTH              DD 12
    GRID_HEIGHT             DD 15
    ID_TIMER                DD 1001
    TILE_SIZE               DD 19

.data
    windowTitle             DB "Saper", 0
    authorPopupTitle        DB "Autor", 0
    author                  DB "Lukasz Rutkowski", 0
    className               DB "WinClass", 0
    star                    DB "*", 0
    marker                  DB "!", 0
    timeDivider             DB ":", 0
    gameOver                DB FALSE
    winTextTitle            DB "Wygrana", 0
    winText                 DB ":D", 0
    grid                    DD 180 DUP (0)
    visibilityArray         DD 180 DUP (0)
    viewedTiles             DD 180 DUP (0)
    isFirstMove             DB TRUE
    gameTime                DD 0
    leftMines               DD 30

.data?
    GRID_SIZE               DD ?
    hInstance               HINSTANCE ?
    drawText                DB 4 DUP (?)
    countText               DB 2 DUP (?)
    mineGenerationArray     DD 180 DUP (?)

    mineBitmap              DD ?
    bgBitmap                DD ?
    tileBitmap              DD ?
    markerBitmap            DD ?

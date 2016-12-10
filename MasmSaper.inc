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

RevealAt proto              :DWORD, :BYTE
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

DialogProc proto            :HWND, :UINT, :DWORD, :DWORD


; ********************************************************************
; Data
; ********************************************************************

.const
    GRID_WIDTH              EQU 12
    GRID_HEIGHT             EQU 15
    ID_TIMER                EQU 1001
    TILE_SIZE               EQU 19
    GRID_SIZE               EQU GRID_WIDTH * GRID_HEIGHT

    IDB_MINE                EQU 1
    IDB_BG                  EQU 2
    IDB_TILE                EQU 3
    IDB_MARKER              EQU 4
    IDB_MINE_CORRECT        EQU 5
    IDB_MINE_INVALID        EQU 6

    EDIT_ID                 EQU 52
    BUTTON_ID               EQU 53

.data
    windowTitle             DB "Saper", 0
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
    editClassName           DB "edit", 0
    buttonClassName         DB "button", 0
    minesCount              DD 30
    dialogName              DB "popupinfo", 0
    zeroText DB "5", 0

.data?
    hInstance               HINSTANCE ?
    hEdit                   HWND ?
    drawText                DB 4 DUP (?)
    countText               DB 2 DUP (?)
    mineGenerationArray     DD 180 DUP (?)
    hMainWnd                HWND ?

    mineBitmap              DD ?
    bgBitmap                DD ?
    tileBitmap              DD ?
    markerBitmap            DD ?
    mineCorrectBitmap       DD ?
    mineInvalidBitmap       DD ?

    lastClickPosition       DD ?
    minesText               DB 8 DUP (?)

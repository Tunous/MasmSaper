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
DialogProc proto            :HWND, :UINT, :DWORD, :DWORD

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
DrawBitmap proto            :HDC, :HDC, :DWORD, :DWORD, :DWORD
DrawTime proto              :HDC
DrawMines proto             :HDC, :HDC
DrawGrid proto              :HDC, :HDC


; ********************************************************************
; Data
; ********************************************************************

.const
    ID_TIMER                EQU 1001
    TILE_SIZE               EQU 19

    ; Grid constants
    ; **************
    GRID_WIDTH              EQU 12
    GRID_HEIGHT             EQU 15
    GRID_SIZE               EQU GRID_WIDTH * GRID_HEIGHT

    ; Bitmap identifiers
    ; ******************
    IDB_MINE                EQU 1
    IDB_BG                  EQU 2
    IDB_TILE                EQU 3
    IDB_MARKER              EQU 4
    IDB_MINE_CORRECT        EQU 5
    IDB_MINE_INVALID        EQU 6

    ; Visibility array constants
    ; **************************
    VISIBLE                 EQU 1
    MARKER                  EQU 2
    CORRECT_MINE            EQU 3

.data
    windowTitle             DB "Saper", 0
    className               DB "WinClass", 0
    timeDivider             DB ":", 0
    winTextTitle            DB "Wygrana", 0
    winText                 DB ":D", 0
    dialogName              DB "popupinfo", 0

    ; Value specifying whether the game has finished.
    ; TRUE means that the grid should be cleaned after next click.
    gameOver                DB FALSE

    ; Value specifying whether the user is going to perform first move.
    ; TRUE means that the next click will generate mines placement making
    ; sure that the clicked tile won't have one.
    isFirstMove             DB TRUE

    ; The game grid marking placement of mines and near mines counts for rest
    ; of the tiles
    grid                    DD 180 DUP (0)

    ; Array holding information about revealed mines and markers
    visibilityArray         DD 180 DUP (0)

    ; Helper array used when revealing all near tiles after hitting on spot
    ; without mines next to it
    viewedTiles             DD 180 DUP (0)

    ; The time spent playing current round (in seconds)
    gameTime                DD 0

    ; The amount of mines which haven't been marked yet
    leftMines               DD 30

    ; The number of mines to generate
    minesCount              DD 30

.data?
    hInstance               HINSTANCE ?
    hMainWnd                HWND ?

    ; Helper array used generate random placement of mines in a way which
    ; prevents selecting same position more than once.
    mineGenerationArray     DD 180 DUP (?)

    ; The last tile that the user has clicked on
    ; Used to mark mine which cause game loss.
    lastClickPosition       DD ?

    ; Arrays used to draw in-game information such as game time and left mines
    ; count
    minesCountText          DB 4 DUP (?)
    countText               DB 2 DUP (?)
    timeText                DB 4 DUP (?)

    ; Bitmaps
    ; *******
    mineBitmap              DD ?
    bgBitmap                DD ?
    tileBitmap              DD ?
    markerBitmap            DD ?
    mineCorrectBitmap       DD ?
    mineInvalidBitmap       DD ?
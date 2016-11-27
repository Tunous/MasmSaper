include \masm32\include\masm32rt.inc


WinMain proto               :HINSTANCE
WndProc proto               :HWND, :UINT, :WPARAM, :LPARAM

Multiply32 proto            :DWORD, :DWORD
Divide32 proto              :DWORD, :DWORD

ConvertToArrayPos proto     :DWORD, :DWORD
ShuffleArray proto          :DWORD, :DWORD
GetArrayElement proto       :DWORD, :DWORD
GetArrayElementXY proto     :DWORD, :DWORD, :DWORD

IncrementIfMine proto       :DWORD
GenerateGrid proto
NewGame proto               :HWND
RevealAt proto              :DWORD
RevealAtXY proto            :DWORD, :DWORD
RevealAllMines proto
CheckHasWon proto           :HWND

HandleMouse proto           :HWND, :LPARAM

Paint proto                 :DWORD, :DWORD
DrawGrid proto              :DWORD


.const
    GRID_WIDTH              DD 12
    GRID_HEIGHT             DD 15

.data
    windowTitle             DB "Saper", 0
    authorPopupTitle        DB "Autor", 0
    author                  DB "Lukasz Rutkowski", 0
    className               DB "WinClass", 0
    star                    DB "*", 0
    gameOver                DB FALSE
    winTextTitle            DB "Wygrana", 0
    winText                 DB ":D", 0
    grid                    DD 180 DUP (0)
    visibilityArray         DD 180 DUP (0)


.data?
    hInstance               HINSTANCE ?
    lpszNumber              DB 2 DUP (?)
    mineGenerationArray     DD 180 DUP (?)

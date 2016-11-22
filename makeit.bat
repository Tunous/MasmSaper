@echo off

    if exist "MasmSaper.obj" del "MasmSaper.obj"
    if exist "MasmSaper.exe" del "MasmSaper.exe"

    \masm32\bin\ml /c /coff "MasmSaper.asm"
    if errorlevel 1 goto errasm

    \masm32\bin\PoLink /SUBSYSTEM:WINDOWS "MasmSaper.obj"
    if errorlevel 1 goto errlink
    dir "MasmSaper.*"
    goto TheEnd

  :errlink
    echo _
    echo Link error
    goto TheEnd

  :errasm
    echo _
    echo Assembly Error
    goto TheEnd
    
  :TheEnd

pause

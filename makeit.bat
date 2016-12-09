@echo off

: Cleanup
if exist "MasmSaper.obj" del "MasmSaper.obj"
if exist "MasmSaper.exe" del "MasmSaper.exe"

: Assmeble into OBJ file
\masm32\bin\ml /coff /c "MasmSaper.asm"
if errorlevel 1 goto errasm

: Build resources
\masm32\bin\rc rsrc.rc
if errorlevel 1 goto errres

: Build exe
\masm32\bin\link /SUBSYSTEM:WINDOWS "MasmSaper.obj" "rsrc.res"
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

:errres
  echo _
  echo Resources Error
  goto TheEnd
    
:TheEnd
  pause

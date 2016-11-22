@echo off

: If resources exist, build them
if not exist rsrc.rc goto over1
\masm32\bin\rc.exe /v rsrc.rc
\masm32\bin\cvtres.exe /machine:ix86 rsrc.res
:over1

: Cleanup
if exist "MasmSaper.obj" del "MasmSaper.obj"
if exist "MasmSaper.exe" del "MasmSaper.exe"

: Assmeble into OBJ file
\masm32\bin\ml /c /coff "MasmSaper.asm"
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

: Link the main OBJ file with the resource OBJ file
\masm32\bin\link.exe /SUBSYSTEM:WINDOWS "MasmSaper.obj" "rsrc.obj"
if errorlevel 1 goto errlink
dir "MasmSaper.*"
goto TheEnd

: Link the main OBJ file
:nores
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

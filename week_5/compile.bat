@del week_5.nes
@del week_5.o
@del week_5.map.txt
@del week_5.labels.txt
@del week_5.nes.dbg
@echo.
@echo Compiling...
ca65 week_5.asm -g -o week_5.o
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Linking...
ld65 -o week_5.nes -C week_5.cfg week_5.o -m week_5.map.txt -Ln week_5.labels.txt --dbgfile week_5.nes.dbg
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Success!
@pause
@GOTO success
:failure
@echo.
@echo Build error 
@pause
:success
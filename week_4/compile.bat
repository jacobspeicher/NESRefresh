@del week_4.o
@del week_4.nes
@del week_4.map.txt
@del week_4.labels.txt
@del week_4.nes.dbg
@echo.
@echo Compiling...
ca65 week_4.asm -g -o week_4.o
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Linking...
ld65 -o week_4.nes -C week_4.cfg week_4.o -m week_4.map.txt -Ln week_4.labels.txt --dbgfile week_4.nes.dbg
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
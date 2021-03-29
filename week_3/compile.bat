@del week_3_ca65.o
@del week_3_ca65.nes
@del week_3_ca65.map.txt
@del week_3_ca65.labels.txt
@del week_3_ca65.nes.ram.nl
@del week_3_ca65.nes.0.nl
@del week_3_ca65.nes.1.nl
@del week_3_ca65.nes.dbg
@echo.
@echo Compiling...
ca65 week_3_ca65.asm -g -o week_3_ca65.o
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Linking...
ld65 -o week_3_ca65.nes -C week_3.cfg week_3_ca65.o -m week_3_ca65.map.txt -Ln week_3_ca65.labels.txt --dbgfile week_3_ca65.nes.dbg
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Success!
@pause
@GOTO endbuild
:failure
@echo.
@echo. Build error!
@pause
:endbuild
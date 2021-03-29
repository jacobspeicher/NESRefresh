@del week_6.o
@del week_6.nes
@echo.
@echo Compiling...
ca65 week_6.asm -g -o week_6.o
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Linking...
@ld65 -o week_6.nes -C week_6.cfg week_6.o
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
@del week_7.o
@del week_7.nes
@echo Compiling
ca65 week_7.asm -g -o week_7.o
@IF ERRORLEVEL 1 GOTO failure
@echo Linking...
ld65 -o week_7.nes -C week_7.cfg week_7.o
@IF ERRORLEVEL 1 GOTO failure
@echo Success!
@pause
@GOTO success
:failure
@echo Build Error
@pause
:success
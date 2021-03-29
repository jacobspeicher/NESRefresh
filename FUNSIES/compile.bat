@del super_palette_bros.o
@del super_palette_bros.nes
@echo.
@echo Compiling...
ca65 super_palette_bros.asm -g -o super_palette_bros.o
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Linking...
@ld65 -o super_palette_bros.nes -C super_palette_bros.cfg super_palette_bros.o
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
cd ..
copy /b lib\love.exe+game.love lib\play.exe
cd lib
tar.exe -a -cf ..\windows.zip play.exe *.dll 
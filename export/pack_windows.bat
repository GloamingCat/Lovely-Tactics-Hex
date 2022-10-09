cd ..
copy /b lib\love.exe+game.love lib\play.exe
copy /b lib32\love.exe+game.love lib32\play.exe
cd lib
tar.exe -a -cf ..\windows64.zip play.exe *.dll 
cd ..\lib32
tar.exe -a -cf ..\windows32.zip play.exe *.dll 
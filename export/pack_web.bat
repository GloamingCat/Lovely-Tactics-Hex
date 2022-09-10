CALL love.js.cmd ..\game.love ..\web -c -t Game
del ..\web\index.html
copy /b index.html ..\web\index.html
cd ..\web
del game.zip
tar.exe -a -cf game.zip favicon.ico index.html love.* game.*
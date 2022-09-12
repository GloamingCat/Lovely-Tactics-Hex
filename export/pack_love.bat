cd ..
tar.exe -a -cf game.zip *.json main.lua conf.lua audio data fonts images scripts shaders
del game.love
ren game.zip game.love
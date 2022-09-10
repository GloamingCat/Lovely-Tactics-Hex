cd ..
tar.exe -a -cf game.zip project.json main.lua conf.lua audio data fonts images scripts shaders
del game.love
ren game.zip game.love
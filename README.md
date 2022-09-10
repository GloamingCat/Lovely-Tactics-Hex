<p align="center">
  <img src="http://i.imgur.com/IgJIz9V.png"><br>
  <img height=300 src="http://i.imgur.com/XSVEcTt.pngg">
</p>


The Lovely Tactics Hex project is a framework for development of tactical role-playing games (TRPG), built using the LÖVE2D engine.
The main games used as inspiration for this project are Final Fantasy Tactics Advance (for GBA), Jeanne D'arc, and Trails in the Sky (both for PSP).
The "Hex" in the name is because the battle grid is hexagonal, but isometric and orthogonal tiles are also available.

Project's repository: https://github.com/GloamingCat/Lovely-Tactics-Hex

<p align="center">
<img width=400 src="https://66.media.tumblr.com/939e12a4f0b1fb41464b8389c2e7cbf8/tumblr_pvkjjmKqRP1x9yfk6o4_1280.png">
<img width=400 src="https://66.media.tumblr.com/ffde850fb9b1e15a786228f0baaaf132/tumblr_pvkjjmKqRP1x9yfk6o5_1280.png">
<img width=400 src="https://66.media.tumblr.com/162763f7aa323d9e6dd1944d1066e145/tumblr_pvkjjmKqRP1x9yfk6o1_1280.png">
<img width=400 src="https://66.media.tumblr.com/0ec170b34248f5c96146cf3d2475f26a/tumblr_pvkjjmKqRP1x9yfk6o3_1280.png">
<img width=400 src="https://66.media.tumblr.com/b25c4d6440d58030a88dda099696fa54/tumblr_pvkjjmKqRP1x9yfk6o6_1280.png">
<img width=400 src="https://66.media.tumblr.com/de6f15c8791b79b562776773c0d4dea8/tumblr_pvkjjmKqRP1x9yfk6o2_1280.png">
</p>

## Installation

To run this project, you need to first install LÖVE2D. Follow steps here: https://love2d.org/.
Once the engine is properly installed, all you have to do is run the project folder as any other game made in the engine.

### Windows
For Windows users who are new to LÖVE2D, here is a simple step-by-step to run the project:
1) Download this project as a zip, in the green button at the top of this page;
2) Download LÖVE2D zip from the site above, according to your platform (32-bit should work);
3) Extract LÖVE2D files into a new empty folder;
4) Extract the project's root folder into the same newly created folder. The project's root folder, that cointans the main.lua file inside, should be in the same folder as "love.exe" file;
5) Drag the project's root folder and drop over "love.exe" file. This should run the game.

### Linux

For Linux users,
1) Download this project as a zip, in the green button at the top of this page;
2) Download LÖVE2D package from the site above and install it;
3) Extract the project's root folder to any folder;
4) Enter the project's root folder (the one containing "main.lua" file), open the terminal and type
```
love ./
```
This should run the game.

## How to Play

* Use arrow keys or mouse to navigate around the field or GUI;
* Press shift to walk faster;
* Press Z/Enter/Space to confirm a GUI selection or interact with NPCs;
* Press X/Backspace/ESC to cancel a GUI selection;
* Press a cancel button in field to show the Field Menu;
* Collide with green jellies to start a battle;
* For debugging:
  * Press F1 to quick-save and F5 to quick-load (does not work during battle);
  * Hold K to kill all enemies in the next turn;
  * Hold L to kill all allies in the next turn.

## Editor

I am also working on a complementary project, which is an editor for the json files - database, settings and fields. It's still in a very early stage, but it can be already found here: https://github.com/GloamingCat/LTH-Editor.

<p align="center">
  <img height=220 src="https://66.media.tumblr.com/eaac8ab6d9f2f4be8dae3abbaaa44c65/tumblr_pkuy0poEfV1x9yfk6o1_1280.jpg">
  <img height=220 src="https://66.media.tumblr.com/7ae1a235c4b3fe02e50e139bb4eab1c3/tumblr_pf5hy6Jwxw1x9yfk6o2_1280.jpg">
</p>

## Documentation and API

Since this project is still under development, its design and features may change a lot, so I'll write a proper documentation when it gets more stable.

## Credits

* UI and character art by me: https://www.instagram.com/gloamingcat/;
* Scenery art by Alex dos Ventos: http://diabraar.tumblr.com/;
* Music generated with Melody Raiser 1999: https://archive.org/details/melody-raiser-1999;
* SFX generated with Bfxr: https://www.bfxr.net/;
* Please check the license.txt file for information about third party code.

## Contact

My e-mail is nightlywhiskers (at) gmail.com. You can also find me in DeviantArt, Instagram and some random art/gamedev forums, as GloamingCat.

# 5DChess Sandbox
 A small implementation of 5D chess without win/lose rules. This is (more or less) a 5D Chess sandbox.
 
 It's written in [Love2D](https://love2d.org/), so you'll need to use [Love](https://love2d.org/) to
 run it. Simply execute the `love` binary with this repository as the current directory

## Controls

 Click to select a piece (even an enemy piece). All the valid locations that piece can move to will be
 highlighted for you (no matter what board those locations appear on). Click to select one, or click to
 select another piece. Making a move will immediately advance the turn counter and will take you onto
 whichever board is active.
 
 You can click-and-drag to move around, and you can zoom with the mouse wheel. That's pretty much it -
 piece movements are implemented, but there's no AI and (currently) no victory, so it's really just a
 sandbox.

## To-do

 - [X] Implement regular chess rules
 - [X] Robust chess piece/location selection system
 - [X] Implement time traveling
 - [X] Implement dimension hopping
 - [X] Friendly/enemy piece previewing
 - [X] Panning/zooming/movement
 - [X] Make turn system more robust
 - [ ] Figure out what's wrong with the knights
 - [ ] Implement a win/lose/replay system
 - [ ] Create some sort of AI system for the game
 - [ ] Maybe a title screen?
 - [ ] Multiplayer?

## Licensing

 All the images used were found on Wikipedia/WikiMedia Commons and are in the Public Domain:
 - https://en.wikipedia.org/wiki/File:Western_white_side_Bishop.svg
 - https://en.wikipedia.org/wiki/File:Western_black_side_Bishop.svg
 - https://en.wikipedia.org/wiki/File:Western_white_side_King.svg
 - https://en.wikipedia.org/wiki/File:Western_black_side_King.svg
 - https://en.wikipedia.org/wiki/File:Western_white_side_Knight.svg
 - https://en.wikipedia.org/wiki/File:Western_black_side_Knight.svg
 - https://en.wikipedia.org/wiki/File:Western_white_side_Pawn.svg
 - https://commons.wikimedia.org/wiki/File:Western_black_side_Pawn_(1).svg
 - https://en.wikipedia.org/wiki/File:Western_white_side_Queen.svg
 - https://en.wikipedia.org/wiki/File:Western_black_side_Queen.svg
 - https://en.wikipedia.org/wiki/File:Western_white_side_Rook.svg
 - https://en.wikipedia.org/wiki/File:Western_black_side_Rook.svg
 
 The font file (`comic.ttf`) contains Comic Neue, which is licensed under the Open Font License (found
 in `OFL.txt`).
 
 The other files in this repository I publish under the MIT license that follows.

### MIT License

```
MIT License

Copyright (c) 2022 Anthony Maranto

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

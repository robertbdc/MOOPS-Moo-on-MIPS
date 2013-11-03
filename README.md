CS3340-Bulls-Hit-Project
========================

Bulls and Cows game for CS3340 Computer Architecture class project

##About the Game

The game is a 2 player code breaking game.
The first player randomly comes up with a hexadecimal number composed of 4 unique numbers.
The second player then tries to guess the number.
The first player tells the second player how many bulls (matching number at the correct position) and cows (matching numbers in the incorrect position) there are.
If the second player guesses the number within a set amount of tries, they win.

#TODO
----------------------

###Music Playing 
1. A procedure which introduces the user to the sounds at the beginning of program executin.
   What sounds does a guitar or bell have to do with cows or bulls?  The user does not know what they mean, so the program
   should play the sounds at the beginning to aquaint the user with the sounds, and tell them what they mean as well.
2. Define if both the player guess and computer guess signal a sound.  Should the computer guess be beeped at?

###AI for user generated number:
1. function to store guessed numbers and where they were guessed at
  * a boolean array of already guessed numbers may be useful here.
2. function(s) which takes the guessed numbers and the number of cows and bulls in previous guess to make a guess 
    
###Winning the game
1. check for win function
  * if number of bulls = 4, win game

###Extra Stuff
1. Add ability to play again.  Keep score and see how badly you can beat the AI.
2. Add option to play against another person, or to just let the AI duke it out.
2. Extend MARS through its tool interface, allowing a GUI for the program.
  Doing this opens up the ability to add a timer, as well as playback of a cow moo's, rather than sticking to MIDI for sound output.



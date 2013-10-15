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

Functions 
----------------------
###For computer generated number:  
1. function to generate number  
  1. generate random int digit between 0 and 15. 
    Or would 1 and 16 is better to avoid conflict with unitialized bytes being 0?
  2. if it is found in array, regenerate(no repeated numbers)
    otherwise store it in the array
2. function to get guess from user 
  * needs some kind of input validation (nothing oustide of 0x0 to 0xF)
  * also cannot input numbers that have already been guessed
3. function to compare user input to generated number
  * return number of cows and number of bulls
4. helper function for general input of digits

###AI for user generated number:
1. function to store guessed numbers and where they were guessed at
  * a boolean array of already guessed numbers may be useful here.
2. function(s) which takes the guessed numbers and the number of cows and bulls in previous guess to make a guess 
    
###In general:
1. check for win function
  * if number of bulls = 4, win game 
2. might help if we had helper for input of digits, to make code more readable, etc.       
3. function to save return address(push it onto the stack?)
4. helper functions for stack operations.  For push: decrement $sp by the amount of bytes needed to store whatever is going into the stack.
Then save thing in word located at address in $sp.
For pop: if ($sp === $fp){ error:cannot pop empty stack}; else increment $sp by the size in bytes of the thing stored in the stack.
5. fucntion to convert between in and hex

Variables 
----------
1. score
2. number of guesses so far
3. max number of guesses(?)
4. user input
5. boolean array of already guessed digits
  * eg. 0 for all values initially; if number is guessed, set array[number] = 1  
6. ASCII array containing the users previously guessed 4 digit numbers


Stuff we need to define:
----------------------------
1. how/where to store variables
 * The number to be guessed.
    This can be stored as an array of 4 integers or as 4 bytes of ascii.  Storing it as ASCII seems to be the way to go for easy printing and readability.
 * other variables?

2. UI
  * are we going to be putting a timer in here somehow? I think that would be a nice addition to the game.
  * we should probably display the previously guessed numbers to make it more polished looking. 
  this means we would have to have an array storing the previously guessed numbers.
  Probably best to keep this as ASCII to make it smaller and easier to print out.
 * for when the computer is guessing at your number, one option is to have you input your secret number in hex.   the computer will store it in memory to automate your response of how many cows and bulls there are, but will not have access to it for guessing purposes.
     this way you don't have to remember your number and then find out how many cows and bulls there are based on the computer's guess.
3. How the game is going to flow?  I see a few options:
  1. the user tries to guess the number before a set amount of turns and maybe a set amount of time.
    what about when it is the computer's turn?  It would be pretty lame if you just had to see how many cows and bulls a random number from a computer had, but what else could they do? 
  2. the user alternates turns with the computer trying to see who can guess the number first.  you guess at the computer's number and then they guess at yours in a head to head showdown to the death.  this adds a sense of competitition, making the game a little more interesting.
4. Stack usage 
  * are we going to be needing to store anything other than 4 bytes in the stack?  If so we would need some kind of data structure in the stack.
  * Solution:always have an int on the top of the stack which represents how big the next item is in the stack.
    This will increase memory usage by 4 kbytes for everything on the stack, so that kind of sucks.
       
  

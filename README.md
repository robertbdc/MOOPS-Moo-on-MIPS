CS3340-Bulls-Hit-Project
========================

Bulls and Cows game for CS3340 Computer Architecture class project

TODO:
Functions we will need
----------------------
##For computer generated number:
1.function to generate number    
 1.generate random int between 0 and 15
  *(maybe 1 and 16 is better to avoid conflict with unitialized variables being 0)
  2.if it is found in array, regenerate(no repeated numbers)
  *if not genertate rest of numbers
2. function to get guess from user    
  *maybe helper function for general input of digits
  *needs some kind of input validation
    *cannot input numbers that have already been guessed
3. function to compare user input to generated number
  *return number of cows and number of bulls

##For user generated number:
1. function to store guessed numbers and where they were guessed at
2. function(s) which takes the guessed numbers and the number of cows and bulls in previous guess to make a guess 
    
##In general:
1. function to convert number to hex representation
  *eg. if we store generated numbers as integers, convert 12 to C before being output
            is this even needed?
2. check for win function
            if number of bulls = 4, win game 
3. might help if we had helper for input of digits        
        
variables we will need
----------------------
1.score
2.number of guesses so far
3.max number of guesses(?)
4.user input
5.boolean array of already guessed numbers
  *eg. 0 for all values initially; if number is guessed, set array[number] = 1  


Standards we need to define:
----------------------------
1. how to store number to be guessed?
           array of 4 integers?
2. how/where to store variables

AI for computer guesses
=======================

The computer guess function is a relatively simplistic, brute-force algorithm, with very little optimization. It occurs in discrete phases, with multiple steps within each phase. Only the previous guess and result are directly considered, so it is entirely possible that the computer will make the same guess twice. It also ignores probability, though it does keep a count of how many times a digit has shown up as "possible", leaving a hook for future enhancement.

##Terminology

* Bull: A correct character in the right position
* Cow: A character that is in the answer, but is in the wrong position
* Bovine: A Bull or a Cow (Total bovines = Bulls + Cows)
* Goat: A character that is not in the answer

#Number Array

In all the steps, we will be looking at whether a digit has a chance of being in the final answer. This is done using an array of 16 words, corresponding to the hex digits 0-F.

Each time a digit is a Bovine (a possible cow or bull), its array element will be incremented. (This could be used in the future for probability-based enhancement.)

If a digit is found to be a definite Bovine, the array element will be set to 0x08000000 (very large positive).

If a digit is found to be a Goat, though, its array element is set to -1 and it will no longer be considered.

#Phase 1: Hardcoded Sequences

The first 16 guesses come from a hardcoded table, similar to a set of hardcoded opening gambits in a chess game. These will serve to weed out one or more sets of digits as consisting entirely of Goats. Each series of four guesses comes from picking the fifth digit from the series before.

    0: 0123 4567 89AB CDEF
    1: 49E3 8D27 C16B 05AF
    2: 81A3 C5E7 092B 4D6F
    3: C963 0DA7 41EB 852F

After set 0 has been processed, we may or may not have some known Goats. Any Goats will be removed from consideration in subsequent attempts.

Continue until we are down to two guesses, one with three Bovines, and the other with one Bovine. (Or until we run out of digits - behavior at this point is uncertain, will probably cycle back to top.)

For example:

Answer: 83A6

    0123: Bovines = 1 (1 cow, no bulls)
    4567: Bovines = 1
    89AB: Bovines = 2 (2 bulls, but we're not tracking that in this version)
    CDEF: Bovines = 0 (future: we would have skipped this check entirely because we already have 4 Bovines in this set)

    (Now in Set 1)
    (49E3: remove E, it's a Goat)
    4938: Bovines = 2
    (D27C: remove C/D, they're Goats)
    2716: Bovines = 1
    B05A: Bovines = 1
    (F: it's a Goat)

    (Now in Set 2)
    81A3: Bovines = 3
    (C5E7: remove C/E, they're Goats)
    5709: Bovines = 0 (all Goats)
    (2B4D: remove D, it's a Goat)
    2B46: Bovines = 1
    Done with Phase 1, we have 81A3 with 3 Bovines, and 2B46 with 1 Bovine.

###Issue:
Some sequences fall through the entire hardcoded list without ever getting to 3 Bovines. Examples: A68E. Need to find the pattern and find a workaround. May have to add a secondary table, or change strategy when we have a 2+1.

#Phase 2: Swap bad for good until we learn something

We have a set of four digits, three of which are bovines. We have another set of four digits, one of which is a bovine.

If we swap a digit from the 1-bovine into the 3-bovine, one of three things can happen to the bovine count - all of which tell us something about the digits we're comparing.

##Bovines = 4
Success! Go to Phase 4 (have cows, get bulls)

##Bovines = 3
The swapped-out digit and the swapped-in digit are the same type. Go to Phase 3 (find the oddball).

##Bovines = 2
The swapped-out digit is a definite bovine, and the swapped-in digit is a definite goat. Mark the digits, and repeat Phase 2.

#Phase 3: Find the oddball

We have a digit in our 3-bovine that is the same type as a digit in our 1-bovine. If they are both goats, then we know about all the digits of the 3-bovine. If they are both bovines, we know about all the digits of the 1-bovine.

Our next guess will tell us which one it is. This is Phase 3 Mode 0. Get the next digit from the 1-bovine.

Terminology:
* digitfm3 = unknown digit from the 3-bovine
* digitfm1 = unknown digit from the 1-bovine
* newdigit = another digit from the 1-bovine

Swap that digit with the unknown digit of the 3-bovine and interpret the result:

##Bovines = 4
Success! digitfm3 was a Goat, newdigit was the Bovine. Go to Phase 4 (have cows, get bulls)

##Bovines = 3
The Bovine count didn't change. digitfm1, newdigit, and digitfm3 are all Goats. All the other digits in the 3-Bovine are Bovines.

Now we have 3 known Bovines, and the last known Bovine is in the 1-bovine. And we've eliminated two unknowns.

*If we only have one unknown left, it's a Bovine. Swap it in and go to Phase 4 (have cows, get bulls)
*If we have two unknowns left, swap one of them as the next guess. That will give you 4 Bovines, or you know which is the last Bovine. This is Phase 3 Mode 1.

##Bovines = 2
digitfm3 was a Bovine. digitfm1 is the only Bovine in the 1-bovine.

Now we have 1 known Bovine, and one of the unknowns in the 3-bovine is a Goat.

* If we only have one unknown left, it's a Goat. Swap it out and go to Phase 4 (have cows, get bulls)
* If we have 2 or 3 unknowns, swap one of them as the next guess. Repeat until we only have one unknown left. This is Phase 3 Mode 2.

#Phase 4: Arrange Cows to find Bulls

##Tracking Bulls vs. Cows

For each of our Cows, we can use four bits to indicate whether it might be a Bull in a specific position. For example:

    0000 - we don't know where it's a Bull (0 = available, so we can initialize to 0x0)
    1001 - can only be a Bull in the second or third position
    1101 - it's a Bull in the third position

So for each of our Cows, we will track its possible Bull positions.

##Possibilities

We will always have 0, 1, or 2 known Bulls. If we had 3 Bulls, the remaining digit could not be a Cow. If we had 4 Bulls, we would be done!

##Modes

###Phase 4 Mode 0: swap 2 unknown digits

When we swap any 2 unknown digits, a limited number of things can happen:

* Count increases from 0 to 2: both are now Bulls
 * Switch the other two. (Definite Win!)

* Count drops from 2 to 0: both were originally Bulls
 * Flip back, flip the other two. (Definite Win!)

* Count unchanged at 0: both were cows before and after.
 * Swap with the other two. Either they'll both be Bulls, or swapping them will make them both Bulls. (Phase 4 Mode 1, need to figure some more)

* Count increases by 1: one is now a Bull, but we don't know which one. 
 * 0 to 1: keep these and switch the other two
 * 1 to 2: keep these and switch the middle two

* Count drops by 1: one was originally a Bull, but we don't know which one
 * 2 to 1: flip back and switch the other two
 * 1 to 0: flip back and switch the middle two

###Phase 4 Mode X: need to figure out endgames

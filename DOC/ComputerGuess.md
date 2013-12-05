AI for computer guesses
=======================

The computer guess function is a relatively simplistic, brute-force algorithm, with very little optimization. It occurs in discrete phases, with multiple steps within each phase. Only the previous guess and result are directly considered, so it is entirely possible that the computer will make the same guess twice. It also ignores probability, though it does keep a count of how many times a digit has shown up as "possible", leaving a hook for future enhancement.

##Terminology

* *Bull:* A correct character in the right position
* *Cow:* A character that is in the answer, but is in the wrong position
* *Bovine:* A Bull or a Cow (Total bovines = Bulls + Cows)
* *Goat:* A character that is not in the answer
* *Pen:* A Guess (4 digits) that has 2 or 3 Bovines.
* *Field:* A Guess that has at least 1 Bovine.
* *Pasture:* A Guess that has 1 Bovine, if needed. (If Pen + Field have 4, the Pasture is not used)

##Phase overview

* *Phase 1:* Use a hardcoded list of initial guesses to come up with two or three guesses, which in total have four Bovines.
* *Phase 2:* Swap digits between these guesses until we identify four Bovines.
* *Phase 3:* Swap the Bovines around until we have four Bulls, and win.

#Phase 1: Hardcoded Sequences

The first 16 guesses come from a hardcoded table, similar to a set of hardcoded opening gambits in a chess game. These will serve to weed out one or more sets of digits as consisting entirely of Goats. Each series of four guesses comes from picking the fifth digit from the series before.

    0: 0123 4567 89AB CDEF
    1: 49E3 8D27 C16B 05AF
    2: 81A3 C5E7 092B 4D6F
    3: C963 0DA7 41EB 852F

After set 0 has been processed, we may or may not have some known Goats. Any Goats will be removed from consideration in subsequent attempts.

Continue until we are down to two or three guesses, which total four Bovines. At least one of these (the Pen) will have two (or three) Bovines.

##Number Array

In this phase, we will be looking at whether a digit has a chance of being in the final answer. This is done using an array of 16 values, corresponding to the hex digits 0-F.

Each time a digit is a Bovine (a possible cow or bull), its array element will be incremented. (This could be used in the future for probability-based enhancement.)

If a digit is found to be a Goat, though, its array element is set to -1 and it will no longer be considered.

##Examples

###Typical example
We end up with a Pen, a Field, and a Pasture

Answer: 75C0

    0123: Bovines = 1 (1 cow, no bulls)
        0123 is defined as the Field
    4567: Bovines = 2 (1 cow, 1 bull - but we're not tracking the difference)
        4567 is defined as the Pen
    89AB: Bovines = 0
        All of these digits are marked as Goats
    CDEF: Bovines = 1
        CDEF is defined as the Pasture

At this point, Pen + Field + Pasture = 4 Bovines. Go to Phase 2.

###Best-case example

Since we have 3 Bovines in the Pen, we only have a Pen and a Field. We might also have 2 in the Pen and 2 in the Field.

Answer: 3601

    0123: Bovines = 3
        0123 is defined as the Pen
    4567: Bovines = 1
        4567 is defined as the Field

At this point, Pen + Field + Pasture = 4 Bovines. Go to Phase 2.

###Worst-case example

If a guess straddles all four possible guesses in a set, we have to try the next set. (That's the reason for the hardcoded sets.)

Answer: 83AD

    0123: Bovines = 1 (1 cow, no bulls)
        0123 is defined as the Field
    4567: Bovines = 1
        4567 is defined as the Pasture
    89AB: Bovines = 1 (1 bull, but we're not tracking Bull v. Cow in this Phase)
        89AB is ignored (we already have a Field and a Pasture, and the Pen must contain at least 2 Bovines)
    CDEF: Bovines = 1
        We should not even submit this guess, because we already know it has exactly one Bovine. (This shortcut is not currently implemented.)

At this point, we have to change to the next set. We clear out the Pen, Field, and Pasture, and start over with the next hard-coded sequence.

    49E3: Bovines = 1
        49E3 is defined as the Field
    8D27: Bovines = 2
        8D27 is defined as the Pen
    C16B: Bovines = 0
        All of these are marked as Goats
    05AF: Bovines = 1
        05AF is defined as the Pasture

At this point, Pen + Field + Pasture = 4 Bovines. Go to Phase 2.

##Notes

* Marking Goats does not seem to be needed in the current technique. If we have a set that is all Goats, we will have 4 Bovines in the other three Guesses. But the code is still present because it might be helpful in the future.

* If it would be helpful, set the array element to 0x08000000 (very large positive) if a digit is found to be a definite Bovine. But we don't find definite Bovines in Phase 1, and we use a different technique in other Phases.

* The original algorithm continued until we had 3 Bovines in the Pen and 1 in the Field. But for some sequences, such as A68E, that condition never happened. All 4 sets of 4 guesses ended up with no more than 2 Bovines in a guess.

* Once we were forced to accept this limitation, Phase 2 actually became less complex. It iterates a simplified process instead of handling a half-dozen modes.

#Phase 2: Swap between Pen and Field

We have the Pen with at least 2 Bovines, and the Field with at least 1 Bovine. We will swap digits from the Field to the Pen until we know that all the digits in the Field are Goats. Every time we swap digits and the Bovine count in the Pen changes, we learn something about the digits we swapped.

If we end up with a Pen containing 3 Bovines and a Field of 4 Goats, we will swap digits from the Pasture to the unknown Pen digit, until we find the Bovine in the Pasture.

Phase 2 uses an array of 16 values, corresponding to the hex digits 0-F. Each element starts out as 0, indicating the digit's status is Unknown. If we determine a digit is a Bovine, its element is set to 1; if it's a Goat, set it to -1.

###Initialize

When we first enter Phase 2 from Phase 1, we save the number of Bovines in the Pen as the "previous guess count". This will let us see if swapping digits between the Pen and the Field increases the Bovines, decreases them, or leaves them the same.

We also save the number of Bovines in the Field (could be 1 or 2). We don't know where they are, but we know they're in there. Whenever we find a Bovine in the Field, and move it from the Field to the Pen, we will decrease the count of Bovines in the Field. When we run out of Bovines in the Field, we can still find one in the Pasture.

We want to swap the first unknown Digit in the Pen with the first unknown Digit in the Field. This will change later (see "Result: Bovines remain the same"). But for now, set the "which unknown in Field" value to 0 (first unknown in Field).

###Swap

On every turn in Phase 2, we look through the Pen for the first unknown digit using the status array. (Known digits in the Pen will always be Bovines.)

Then, we look through the Field for an unknown digit. (Known digits in the Field will always be Goats.)

If the "which unknown in Field" value is > 0, skip the number of unknown digits indicated. See "Result: Bovines remain the same".

We swap these unknowns out, and send the Pen to the caller as our next guess.

For example, using Answer: 75C0

    Pen: 4567 (none known)
    Field: 0123 (none known)
    Pasture: CDEF (not used until later)

The first unknown digit of the Pen is 4, the first unknown digit of the Field is 0. We will update the Pen to 0567 and submit it as our guess. The field will contain 4123.

###Result: Bovines Increase

If the number of Bovines increases, then the digit we swapped from the Field to the Pen is a Bovine. And the digit we swapped from the Pen to the Field is a Goat.

Mark the digit we swapped to the Pen as a known Bovine (array element = 1), and the one we swapped to the Field as a known Goat (array element = -1).

We started out with 1 or 2 Bovines in the Field. Decrease the count of Bovines in the Field. If we have no more Bovines in the Field, it's time to look for that one lone Bovine in the Pasture. We simply copy the Guess stored as the Pasture to the Field - the rest of the routine keeps looking at the Field.

Save the number of Bovines in the Pen as the new "previous guess count".

Also, reset the "which unknown in Field" value back to 0 (first unknown in Field). See "Result: Bovines remain the same".

Go to the Swap routine to generate our next guess. Note that we have marked some digits as known Bovines/Goats, so we'll be swapping the next unknown digit.

###Result: Bovines Decrease

If the number of Bovines decreases, then it's just the opposite of what happened on an increase. The digit we swapped from the Field to the Pen is a Goat, and the digit we swapped from the Pen to the Field is a Bovine.

Mark the digits with their newfound status, and swap them back to their original positions.

Don't update the "previous guess count" to reflect the decrease. We swapped the digits back, so the "previous guess count" compares with the swapped-back guess.

Go to the Swap routine to generate our next guess. Again, we have marked some digits as known Bovines/Goats. Even when a guess generates a negative result, we learn something.

###Result: Bovines remain the same

If the number of Bovines remains the same, then the digits we swapped are the same type - they're both Bovines, or they're both Goats.

As noted, the Swap routine will look for the first unknown digit in the Pen, and the first unknown digit in the Field. We need to change this behavior slightly.

Increment the "which unknown in Field" value. This will tell the Swap routine to skip "n" unknown digits in the Field. This value started at 0, so Swap starts out not skipping any unknown digits.

Go to the Swap routine to generate our next guess. We have the same unknowns as before, but we will compare the unknown in the Pen with a different unknown in the Field.

(Note: we don't bother swapping the digits back to their original positions, like we did when Bovines decreased.)

##Notes

* The original design for this Phase involved 5 phases (plus setup), and expected a Pen with 3 Bovines (and a Field with 1 Bovine). That design fell apart when it turned out we couldn't guarantee coming in with 3 Bovines.

* This algorithm evolved by starting with the increase/decrease cases, and then coming up with an iterative method to find a digit in the Field that didn't match.

#Phase 3: Arrange Cows to find Bulls

This phase involves swapping pairs of digits within the Pen, and choosing the next swap based on the result.

###Swappable pairs

This phase has four modes, corresponding to the pairs of digits that can be swapped.

Example guess: ABCD

* Mode 0: Swap A-B
* Mode 1: Swap B-C
* Mode 2: Swap C-D
* Mode 3: Swap D-A

###Initialization

When Phase 3 starts, the Mode is set to -1 to indicate that we are either just entering this mode, or we are re-initializing after reordering the guess (see "Bulls stay the same").

Initialization sets Mode to 0, and sets the "last Bulls count" to the current number of Bulls.

Swap the digits indicated by Mode 0 to generate the new Guess. 

###Bulls increase by 2

This means that the digits we swapped are both now Bulls. Set our new "last Bulls count".

We need to swap the other two, and we should have 4 bulls.

To do this, increase the Mode by 2. Take the modulo 4 result (mask with 0x03) and it wraps around.

Swap the digits indicated by the new Mode to generate the new Guess. 

###Bulls increase by 1

We don't know which of the digits we swapped became a Bull, but one of them did. Set our new "last Bulls count".

We'll leave one digit as it is, and swap the other digit with its other neighbor.

To do this, increase the Mode by 1 (and mask with 0x03).

Swap the digits indicated by the new Mode to generate the new Guess. 

###Bulls decrease by 1

We don't know which of the digits we swapped was originally a Bull, but one of them was.

Swap the digits back to where they started. Don't change the "last Bulls count".

Now, we'll leave one digit as it is, and swap the other digit with its other neighbor.

To do this, increase the Mode by 1 (and mask with 0x03).

Swap the digits indicated by the new Mode to generate the new Guess. 

###Bulls decrease by 2

This means that the digits we swapped were originally Bulls.

Swap the digits back to where they started. Don't change the "last Bulls count".

We need to swap the other two, and we should have 4 bulls.

To do this, increase the Mode by 2 (and mask with 0x03).

Swap the digits indicated by the new Mode to generate the new Guess. 

###Bulls stay the same

This means that the digits we swapped were not Bulls before and they're not Bulls now. They belong in the other two positions of the guess.

Rotate the entire guess by two digits. For example: ABCD becomes CDAB.

Reset the Mode to -1 to indicate that we need to start from scratch after this guess. Now that we have the pairs in the right place, the swaps in the other modes will eventually get us 4 Bulls.

Submit the new guess.

##Notes

* The algorithm may lose some efficiency because it does not track the status of individual digits. It does not have any sense of probability based on the number of times a digit was involved in a guess containing Bulls.

* The "Bulls stay the same" condition, in particular, may be causing extra guesses by not ensuring that the pairs don't get moved again. It might need to block odd-numbered Modes. But it pushes through with brute force and does the job.

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

Continue until we are down to two guesses, one with two Bovines, and the other with one or two Bovines.

For example:

Answer: 83AD

    0123: Bovines = 1 (1 cow, no bulls)
    4567: Bovines = 1
    89AB: Bovines = 1 (1 bull, but we're not tracking that in this version)
    CDEF: Bovines = 1
    
    (Now in Set 1)
    49E3: Bovines = 1
    8D27: Bovines = 2
    Done with Phase 1, we have 49E3 with 1 Bovine, and 8D27 with 2 Bovines.

A previous algorithm continued until we had 3 Bovines, but sometimes that doesn't happen at all (A68E, for example).

#Phase 2: Swap bad for good until we learn something

We have a set of four digits, two or more of which are bovines. We have another set of four digits, one or two of which is a bovine.

##Terminology

* Pen: Our primary guess. We will keep the known Bovines here until all four digits are Bovines
* Field: Other possible bovines. We will swap in from here until we find a Bovine.

##Modes

###Pre-check

* If we have 1 known Bovine in the Field, go to Phase 2, Mode 3
* If we have 3 known Bovines in the Pen, go to Phase 2, Mode 4

###Phase 2, Mode 0: Multiple unknowns in both Pen and Field

If we swap a digit from the Field into the Pen, one of three things can happen to the Bovine count - all of which tell us something about the digits we're comparing.

* Bovines increase: Digit from Pen is a Goat, Digit from Field is a Bovine. Keep digits swapped and repeat Phase 2 until we have 4 Bovines.
* Bovines decrease: Digit from Pen is a Bovine, Digit from Field is a Goat. Swap back to original places and repeat Phase 2
* Bovines same: Digit from Pen is the same type as Digit from Field, but what is it? Swap back to original places, save Pen digit as PenA, and go to Mode 1.

###Phase 2, Mode 1: Multiple unknowns, but one in the Pen is the same as the one in the Field

We have a digit from the Pen (PenA) and the same digit from the Field, and we know they're the same, but which are they?

To find out, swap Field with another unknown digit in the Pen (PenB). Again, one of three things can happen to the Bovine count:

* Bovines increase: PenB is a Goat, Field is a Bovine, PenA is a Bovine. Put the Bovines in the Pen and repeat Phase 2.
* Bovines decrease: PenB is a Bovine, Field is a Goat, PenA is a Goat. Put the Bovines in the Pen and repeat Phase 2.
* Bovines same: PenB, Field, and PenA are the same. Swap back to original places and go to Mode 2.

###Phase 2, Mode 2: Multiple unknowns, but two in the Pen are the same as the one in the Field

We already know that our Pen contains two Bovines. That means that PenA and PenB are either the only Bovines, or the only Goats. To find out, we have to compare against the third digit in the Pen, PenC. Swap the Field digit with PenC.

* Bovines increase:
 * PenC is a Goat
 * Digit from Field is a Bovine
 * PenA and PenB are also Bovines, because they're the same as the Field digit.
* Bovines decrease:
 * PenC is a Bovine
 * Digit from Field is a Goat
 * PenA and PenB are also Goats, because they're the same as the Field digit.
 * PenD is a Bovine, because we know we started with 2 (or 3) Bovines. If PenA and PenB are Goats, PenC and PenD must be Bovines.
* Bovines same:
 * PenC is the same as Field.
 * We already know that Field is the same as PenA and PenB, so PenA, PenB, PenC, and Field are all the same.
 * Since our Pen started out with at least 2 Bovines, PenA, PenB, and PenC could not all be Goats.
 * Therefore, PenA, PenB, PenC, and the Field digit are all Bovines! Go to Phase 3 (have cows, get bulls)

###Phase 2, Mode 3: 1 known Bovine in Field

Once we identify the Bovine in the Field, substitute it for an unknown digit in the Pen.

* Bovines increase: This should get us to 4 Bovines
* Bovines decrease: _This can't happen!_
* Bovines same: Digit in Pen is a Bovine. Replace it and repeat Phase 2.

###Phase 2, Mode 4: 3 known Bovines in Pen

Once we have 3 known Bovines, we know the other is a Goat. Replace it with a digit from the Field until Bovines = 4.

#Phase 3: Arrange Cows to find Bulls

##Tracking Bulls vs. Cows

For each of our Cows, we can use four bits to indicate whether it might be a Bull in a specific position. For example:

    0000 - we don't know where it's a Bull (0 = available, so we can initialize to 0x0)
    1001 - can only be a Bull in the second or third position
    1101 - it's a Bull in the third position

So for each of our Cows, we will track its possible Bull positions.

##Possibilities

We will always have 0, 1, or 2 known Bulls. If we had 3 Bulls, the remaining digit could not be a Cow. If we had 4 Bulls, we would be done!

##Modes

###Phase 3 Mode 0: swap 2 unknown digits

When we swap any 2 unknown digits, a limited number of things can happen:

* Count increases from 0 to 2: both are now Bulls
 * Switch the other two. (Definite Win!)

* Count drops from 2 to 0: both were originally Bulls
 * Flip back, flip the other two. (Definite Win!)

* Count unchanged at 0: both were cows before and after.
 * Swap with the other two. Either they'll both be Bulls, or swapping them will make them both Bulls. (Phase 3 Mode 1, need to figure some more)

* Count increases by 1: one is now a Bull, but we don't know which one. 
 * 0 to 1: keep these and switch the other two
 * 1 to 2: keep these and switch the middle two

* Count drops by 1: one was originally a Bull, but we don't know which one
 * 2 to 1: flip back and switch the other two
 * 1 to 0: flip back and switch the middle two

###Phase 3 Mode X: need to figure out endgames

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

Raw docs for subsequent phases
==============================

    End phase 1, we have a block with 3 cows. (wonder if we ever *don't* get there?)
    We can't get past here with what we have, because our hardcodes don't include all possibilities


    Phase 2
    (future: Order each by likelihood. No order-by right now.)
    Start swapping from 1-cow into 3-cow

    if cows = 4, done

    if cows = 2:
    * swapped-out digit is a cow (definite yes)
    * swapped-in digit is a goat (definite no)
    * Pick next digit from each and repeat

    if cows = 3, swapped-out digit and swapped-in digit are the same type. Go to phase 3.


    Phase 3
    We have a digit in the 3-cow and a digit in the 1-cow that are the same type

    Get next digit from the 1-cow, swap it with current digit from the 3-cow

    if cows = 4, done

    if cows = 3:
    * swapped-out digit is a goat (definite no)
    * old swapped-in digit is a goat (definite no)
    * new swapped-in digit is a goat (definite no)
    * Go to phase 4b

    if cows = 2:
    * swapped-out digit is a cow (definite yes)
    * old swapped-in digit is a cow (definite yes)
    * new swapped-in digit is a goat (definite no)
    * Go to phase 4a


    Phase 4a
    We have a 3-cow, and a known good digit from 1-cow

    Swap known good digit with unknown digit in 3-cow

    if cows = 4, done

    if cows = 3:
    * swapped-out digit is a cow (definite yes)
    * Repeat phase 4a


    Phase 4b
    We have a 3-cow and we know which digit is bad, but we don't know which digit in 1-cow is good
    Only 2 choices at this point, though.

    Swap first unknown. If cows = 4, done, else swap second unknown and that's it.


    Phase 2+ test
    ex: 8B5C

    3-cow: EB85
    1-cow: FC96

    Phase 2
    swap 3/ch1 w 1/ch1: FB85, cows = 3: E & F are the same type

    Phase 3
    swap 3/ch1 w 2/ch2: CB85, cows = 4: done

    Phase 4
    rearrange until we get 4 bulls (should be relatively simple, right?)

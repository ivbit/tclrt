#!/usr/bin/python3

# Do not call the file 'random.py', it will mess the import of module
from random import *

print(random())                          # Random float:  0.0 <= x < 1.0

print(uniform(2.5, 10.0))                # Random float:  2.5 <= x <= 10.0

print(expovariate(1 / 5))                # Interval between arrivals averaging 5 seconds

print(randrange(10))                     # Integer from 0 to 9 inclusive

print(randrange(0, 101, 2))              # Even integer from 0 to 100 inclusive

print(choice(['win', 'lose', 'draw']))   # Single random element from a sequence

deck = 'ace two three four'.split()
shuffle(deck)                            # Shuffle a list
print(deck)

print(sample([10, 20, 30, 40, 50], k=4)) # Four samples without replacement


# Endless Bits

Endless Bits is a library in the Scheme programming language for the computable real numbers.

I wrote the library in Gambit Scheme and I'm sure it has many Gambit-specific "features".  I'm open to packaging it eventually as an R7RS library.

The source files are in `src`.  There are two layers, the base layer is in `exact-reals.scm`, which has some block documentation; this layer is a bit unforgiving.  This layer will change as I get more ideas.

There is a layer with error checking and syntactic sugar in `CReals.scm`. These routines take as arguments either Scheme rational (exact or inexact) numbers and return a representation of a computable real number. To get a result you can read use `CR->string`, which prints a decimal string approximation to a computable real, or `CR->inexact`, which converts a computable real to an inexact number (with or without warnings if it takes too much computation to compute a "correct" answer).  

The library can be viewed as a companion piece to my paper [The Nature of Numbers: Real Computing](https://scholarship.claremont.edu/jhm/vol12/iss1/25/) which discusses my evolving childhood notions of numbers and how the computable real numbers seem a natural culmination of that understanding.  The last section gives a gentle (I hope) introduction to the computable real numbers.

This library is under active development, and in my limited experimentation is much slower than some libraries and much faster than others.  It works fine for single expressions, not so well with iterative computations, etc.

I haven't settled yet on which Open Source license I'll use with the library.
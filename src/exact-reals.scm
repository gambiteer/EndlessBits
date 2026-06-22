(declare (standard-bindings)
         (extended-bindings)
         (block)
         (mostly-fixnum)
         (not inline)
         (inlining-limit 0))

#|

This code implements some ideas from John Harrison's thesis:

@book {MR1666441,
    AUTHOR = {Harrison, John},
     TITLE = {Theorem proving with the real numbers},
    SERIES = {CPHC/BCS Distinguished Dissertations},
 PUBLISHER = {Springer-Verlag London, Ltd., London},
      YEAR = {1998},
     PAGES = {xii+186},
      ISBN = {3-540-76256-6},
   MRCLASS = {68T15 (03B35 68-02 68Q40)},
  MRNUMBER = {1666441},
MRREVIEWER = {Sauro\ Tulipani},
       DOI = {10.1007/978-1-4471-1591-5},
       URL = {https://doi.org/10.1007/978-1-4471-1591-5},
}

In turn, he got ideas from a preprint of:

@article {MR2137733,
    AUTHOR = {M\'enissier-Morain, Val\'erie},
     TITLE = {Arbitrary precision real arithmetic: design and algorithms},
   JOURNAL = {J. Log. Algebr. Program.},
  FJOURNAL = {The Journal of Logic and Algebraic Programming},
    VOLUME = {64},
      YEAR = {2005},
    NUMBER = {1},
     PAGES = {13--39},
      ISSN = {1567-8326},
   MRCLASS = {03F60 (65G99 68N15)},
  MRNUMBER = {2137733},
MRREVIEWER = {V.\ Ya.\ Kreinovich},
       DOI = {10.1016/j.jlap.2004.07.003},
       URL = {https://doi.org/10.1016/j.jlap.2004.07.003},
}

The algorithms start in Section 4.5 of Harrison's thesis.  The basic
idea is that one represents a computable number $x$ by a procedure of a single
nonnegative argument $n$ that returns an integer $x_n$ such that
$$
|x_n-2^nx|<1.
$$

Note that this doesn't mean that $x_n$ is the {\it closest\/} integer to
$2^nx$ unless $2^nx$ is itself an integer.

x_n denotes an approximation with n fracional bits precision.  So if x is an integer then

x_0 = x,

and otherwise x_0 is an integer that satisfies

x - 1 < x_0 < x + 1.

The definition {\it does\/} mean, however, that if $|x_n|>k$ and $k$ is an integer,
then $2^n|x|>k$ also.  We use this below.

Our algorithms for basic aritmetic (+, -, *, /, sqrt) differ little from those
in Harrison's thesis.  We work in base 2, with a single routine to deliver a
correct base 10 result from a correct base 2 result.  Each routine has a proof
of its correctness in a comment.

There is a lot of caching going on, at the bit level and, for the elementary functions,
at the argument level with weak tables.  This makes things go a lot faster.  You can
turn off the caching in basics.scm and see for yourself (although I suspect that this
slowdown is caused mainly by repeated evaluation of Pi at various precisions).

The elementary function implementations are motivated by the classic book

@book{10.5555/1096483,
author = {Cody, William J and Waite, William M},
title = {Software Manual for the Elementary Functions (Prentice-Hall series in computational mathematics)},
year = {1980},
isbn = {0138220646},
publisher = {Prentice-Hall, Inc.},
address = {USA}
}

While a graduate student at the University of Chicago, I was lucky enough to spend the summers of
1979, 1980, and 1981 at Argonne National Laboratory, where I met many numerical people, including
Jim Cody, Vel Kahan, Cleve Moler, Jack Dongarra, and Danny Sorensen.  Jim Cody was kind enough
to give me a pre-publication copy of Software Manual for the Elementary Functions, from which I
learned a lot while having a lot of fun.

The basic idea for each elementary procedure (f x) is to transform the argument x until one arrives
at a small x-bar.  You can then compute the original (f x) from (f x-bar) (or perhaps there are two
related functions, like sine and cosine, and you compute (sin x) from either (sin x-bar) or (cos x-bar),
depending on how you got from x to x-bar).

For each elementary function, Cody and Waite have specific algorithms for the following combination
of cases: fixed-point or floating-point arithmetic; base 2, 10, or 16 floating-point arithmetic;
and various precisions of arithmetic. (Their ideas are easy to adapt---I once wrote a library for
base-100 floating-point arithmetic in UCSD Pascal running on Texas Instruments minicomputers.)

But because, in the end, each algorithm is for a fixed base and precision, Cody and Waite could tailor
(f x-bar) to each circumstance.  They used either polynomial or rational functions in x-bar, with fixed
degrees and coefficients, to compute (f x-bar).

Our circumstances are different: we want to compute correct results to arbitrary precision.

So all of our computations of (f x-bar) use Taylor series of some kind.  When given an x-bar and a precision,
we compute the number of terms in the Taylor series to achieve the needed precision, and compute the
partial sum of that series.

We keep the partial sum that we have computed, so that if later, for some reason, we need more correct bits in
the result than that partial sum can provide, we just add on extra terms to get a longer partial sum.

There is one other small difference.

The argument transformations in Cody and Waite depend on comparing the arguments x to known numbers.  For
example, if x is negative, we have (atan x) = (- (atan (- x))), and now we need to deal only with positive
x-bar = (- x), if x is negative, or just x, otherwise.

Similarly, if x is greater than 1, we have (atan x) = (- pi/2 (atan (/ x))), so now we need to deal
only with 0 <= x-bar <= 1, with x-bar = x if x <= 1, or x-bar = (/ x) if x > 1.

All this is fine and dandy in fixed- or floating-point arithmetic, but knowing whether (< x y) for two
computable real numbers x and y is, in general, undecideable.  The best you can do is compute approximate
values of x and y to an arbitrary, fixed, precision and compare those two approximations.  And if you
can't tell with approximations at that precision you have two choices: compute x and y to higher
precision and try again, or just give up and return a default value.

So you need to be sure that your argument reductions and Taylor series work even when comparing x to
computable zero or computable one gives a (slightly) incorrect answer, and that the algorithm still
returns the result (f x-bar) to the required precision.

It is for this reason that we added another argument reduction to the computation of arcsine: for x
(approximately) between 0.3 and 1/2, we have (asin x)=(+ pi/6 (asin x-bar)), where x-bar is a
suitably complicated function of x.

ERROR CHECKING:

In general, it's impossible (literally) to check for incorrect arguments to
the procedures here.

Only these routines check for and report errors:

1.  (computable-/-by-integer x m), when m is zero.

2.  (computable-expt x n) when x is computable-zero and n is negative.

3. (computable-inverse,x), when
(a) x is computable-zero
(b) A computable (x n) is zero for n > *max-precision* bits.

4. (computable-sqrt x) when a computed a computed (x n) is negative.

5. (computable-log x) when
(a) x is computable-zero or computable-negative-one
(b) A computed (x n) is negative.
(c) A computed (x n) is zero for > *max-parameter* bits.

Other routines can be passed incorrect arguments ((computable-asin (->computable 2)), for example)
but these errors are reported as coming from one of the above procedures.

TESTING:

For testing, Cody and Waite employ identities (like (atan x) = (- (atan (- x))), but more complicated) to
check the internal consistency of routines applied to randomly generated arguments.  While this general
approach has influenced me a lot, we don't use it here.

Instead, we start with a routine computable->inexact (which is also, in general, undecideable, but it is
guaranteed to work with irrational arguments).  For a given rational Scheme number x, we then compare, e.g.,

(computable->inexact (computable-sin (->computable x))) and (sin x)

where (sin x) generally calls the builtin system library routine.

Now the system library for a procedure proc does not always give the correctly rounded result
for (proc x), so we also compare, e.g., (computable->inexact (computable-sin (->computable x)))
to the two floating point numbers adjacent to (sin x).  We're satisfied if

(computable->inexact (computable-sin (->computable x)))

equals either (sin x) or one of the two adjacent floating-point numbers to (sin x).

That's only a rough measure of correctness however, because we can't know whether the result
from the system library or the result from this computable reals library is the correct result
(but so far, followup computations have shown that where results differ, the computational
reals result is the correct one).

We then check internal consistency of the routines, to show that if, e.g.,

y = (computable->inexact (computable-sin (->computable x))),

then computing y to  n = 0, 10, 50, or 100 bits precision, say, is consistent with the value
of y computed to 1000 bits of precision.

We can turn off caching for this part of the test, which tests whether the underlying
algorithms are correct to the tested precisions.

The library defines the following quantities and procedures:

INDEX:

Computable numbers:

computable-one
computable-negative-one
computable-zero
computable-half

computable-sqrt-3
computable-sqrt-3/2
computable-2-sqrt-3

computable-pi
computable-pi/2
computable-pi/6

computable-e
computable-log-2

Procedures:

->computable        (transforms a finite, rational, Scheme number to a computable number)
computable->inexact (with a precision argument, to make it decideable)

computable-negate
computable-abs

computable-max (one or more arguments)
computable-min (one or more arguments)

computable-+ (arbitrary number of arguments)
computable-- (one or two arguments)

computable-*-by-integer
computable-/-by-integer
computable-*-by-rational

computable-*       (two arguments)
computable-square
computable-inverse
computable-/       (two arguments)

computable-sqrt

computable-<  (two arguments, returns 1 (known #t), -1 (known #f), or 0 (don't know),
               with a precision argument, in bits, to make it decideable)

computable-expt ((computable-expt x n) with x computable and n an integer)

computable-sin
computable-cos
computable-tan

computable-exp
computable-log
computable-pow  (implement's Scheme (expt x y) for finite positive x and finite y, not yet tested)

computagle-asin
computable-acos
computable-atan

computable-sinh
computable-cosh
computable-tanh

computable-asinh
computable-acosh
computable-atanh

|#

#|

A very basic inequality that we shall use several times is that for any
integer $x$ and nonnegative $k$

(<= 0
    (- x (* (expt 2 k) (arithmetic-shift x (- k))))
    (- (expt 2 k) 1))

|#

(include "utilities.scm")
(include "basics.scm")
(include "arithmetic.scm")
(include "sqrt.scm")
(include "expt.scm")
(include "transcendentals.scm")
(include "constants.scm")
(include "sin-cos.scm")
(include "exp.scm")
(include "atan.scm")
(include "log.scm")
(include "sinh-cosh.scm")
(include "asin-acos.scm")
(include "pow.scm")
(include "atanh.scm")

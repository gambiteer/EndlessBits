# Endless Bits

Endless Bits is a library in the Scheme programming language for the computable real numbers.

I wrote the library in Gambit Scheme and I'm sure it has many Gambit-specific "features".  I'm open to packaging it eventually as an R7RS library.

The source files are in `src`.  There are two layers, the base layer is in `exact-reals.scm`, which has some block documentation; this layer is a bit unforgiving; the interface is undocumented and will change as I get more ideas.

There is a layer with error checking and syntactic sugar in `CReals.scm`. These routines take as arguments either Scheme rational (exact or inexact) numbers or a computable real returned by a `CR` routine and return a representation of a computable real number.

The library can be viewed as a companion piece to my paper [The Nature of Numbers: Real Computing](https://scholarship.claremont.edu/jhm/vol12/iss1/25/) which discusses my evolving childhood notions of numbers and how the computable real numbers seem a natural culmination of that understanding.  The last section gives a gentle (I hope) introduction to the computable real numbers.

This library is under active development, and in my limited experimentation is slower than some libraries and faster than others.  It works fine for single expressions, not so well with iterative computations, etc.

The library is released under the MIT License.

## Minimal Example

Here's a minimal example for now.  Inside the `src` directory, do
```
[MacBook-Pro:computational-reals/EndlessBits/src] lucier% gsi
Gambit v4.9.7-81-g90510e6d

> (load "CReals")
"/Users/lucier/text/courses/computation/computational-reals/EndlessBits/src/CReals.scm"
> (CR->string (CRsin (CRsqrt 2)))
"#e0.9877659459927355270691340720789426559067931295160371960387636855029137230930116293997622287379559081"
> (CR->string (CRsin (CRsqrt 2)) 1000)
"#e0.9877659459927355270691340720789426559067931295160371960387636855029137230930116293997622287379559081374247769332974942520626131918180644911482365917085015668375295073234530190983132814439429300160888382054448040702227777167890399373838564508447981351650037820859451004681523329453931285597639978503150359443136097807258237426162175019366328980569290101590854680749852183351031258129262636712322471363262616504037657386201627191133350953360598641809305430706515130391628655880382550562094261536987497928319699097466660530619848916087601699670711552246890917452320178690758931433407712809949982093292356060255097644418111283542580734947716580898289910958020910242342370267856380701803161104320396002174722818928177410850460919472304162820164547685864180442404288403022622176271640533274270735366111942776901060822887142060984426082330308440844942414084620440467642127440664802765730396185041646383406574394692133849477216819180223239406953784246955415141727679436570825674698828652731549156837067207629"
```
## Routines in CReals.scm
Routines with names beginning with `CR` generally take as arguments either (exact or inexact) rational Scheme numbers or structs representing computable real numbers that have been returned by previous routines.  These structs are meant to be opaque.

In some circumstances it is necessary to remember that comparisons (`=`, `<`) is, in general, undecidable in the computable reals.  This means that if one is converting a computable real to an inexact floating-point number and one finds that, no matter how many fractional bits precision one computes, the approximation is always halfway between two adjacent floating-point numbers, then in theory the computation can never complete.  In practice, there is an internal parameter `*max-precision*` that represents that maximum number of fractional bits one computes before giving up and either failing or returning a default value.  The boolean parameter `*warn*` determines whether a warning is given when a default value is returned.

#### Converting computable real numbers
##### `(CR->string x #!optional (digits 100))`
Produce a string that represents an approximation to `x` to `digits` fractional decimal digits.  E.g.:
```
(CR->string (CRsqrt 2) 20) => "#e1.41421356237309504880"
```
##### `(CR->inexact x)`
Produce a double-precision approximation to `x`.  E.g.:
```
(CR->inexact (CRsqrt 3/7)) => .6546536707079772
```
##### `(CR+ x)`
There is no explicit routine for converting a finite, real Scheme number to a computable real, but one can use `CR+`.  E.g.:
```
(CR->string (CR+ 3/7) 20) => "#e0.42857142857142857143"
```
#### Constants
##### `Pi`, `E`
Predefined constants. E.g.:
```
> (define Ramanujan (CRexp (CR* Pi (CRsqrt 163))))
> (CR->inexact Ramanujan)
2.6253741264076874e17
> (CR->string Ramanujan 10)
"#e262537412640768744.0000000000"
> (CR->string Ramanujan 20)
"#e262537412640768743.99999999999925007260"
```
#### Routines corresponding to Scheme routines
##### CR+, CR*
Routines that take zero or more arguments.  E.g.:
```
> (CR->inexact (CR+))
0.
> (CR->inexact (CR+ 3/7))
.42857142857142855
> (CR->inexact (CR*))
1.
> (CR->inexact (CR* 3/7))
.42857142857142855
```
##### CR-, CR/, CRmax, CRmin
Routines that take 1 or more arguments.  E.g.:
```
> (CR->inexact (CR- 3/7))
-.42857142857142855
> (CR->inexact (CR- 3/7 1/7))
.2857142857142857
> (CR->inexact (CR/ 3/7))
2.3333333333333335
> (CR->inexact (CR/ 3/7 1/7))
3.
> (CR->inexact (CRmax 4/7 1/7))
.5714285714285714
> (CR->inexact (CRmin 4/7 1/7))
.14285714285714285
```
##### CRsquare, CRexp, CRsin, CRcos, CRatan, CRsinh, CRcosh, CRtanh, CRasinh
Single argument functions whose domain consists of all computable real numbers.  E.g.:
```
> (map (lambda (op)
         (CR->inexact (op 3/7)))
       (list CRsquare CRexp CRsin CRcos CRatan CRsinh CRcosh CRtanh CRasinh)
(.1836734693877551
 1.53506300925521
 .415571854993052
 .9095603516741667
 .40489178628508343
 .44181197586207716
 1.0932510333931327
 .4041267397578592
 .41643077489991215)
```
##### CRsqrt, CRlog, CRtan, CRasin, CRacos, CRacosh, CRatanh
Single argument routines with domains that are not all computable real numbers.

Errors are caught at different times---computability is a process. If given Scheme numbers outside the domain as arguments then the errors are caught immediately; if the arguments are computable real numbers then the errors are caught when they are notices.  E.g.:
```
> (CR->string (CRsqrt #e-1e-10000) 0)
*** ERROR IN (stdin)@33.13-33.33 -- (Argument 1) Out of range
(CRsqrt
 -1/10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000... #62
)
1>
;;; The same argument, only obscured.
> (CR->string (CRsqrt (CR- 0 #e1e-10000)) 0)
"#e0."
> (CR->string (CRsqrt (CR- 0 #e1e-10000)) 5)
"#e0.00000"
> (CR->string (CRsqrt (CR- 0 #e1e-10000)) 10)
"#e0.0000000000"
> (CR->string (CRsqrt (CR- 0 #e1e-10000)) 1000)
"#e0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
> (CR->string (CRsqrt (CR- 0 #e1e-10000)) 100000)
*** ERROR IN loop, "basics.scm"@107.1 -- computable-sqrt: argument is negative:  #<procedure #61>
   ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ basics.scm ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ┃⋯
106┃
107┃(setup-primitives)
108┃
   ┃⋯
1>
```
##### CRexpt
Requires that the first argument is not negative
```
> (CR->inexact (CRexpt 3/7 1/2))
.6546536707079772
> (CR->inexact (CRexpt 3/7 -1/2))
1.5275252316519468
> (CR->inexact (CRexpt -3/7 1/2))
*** ERROR IN CRexpt, "CReals.scm"@164.10-172.53 -- (Argument 1) Out of range
(CRexpt -3/7 1/2)
   ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ CReals.scm ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ┃⋯
163┃  (let ((args
164┃         (with-exception-catcher
165┃          (lambda (index)
166┃            (##raise-range-exception index CRexpt x y))
   ┃⋯
170┃                        (lambda (arg index)
171┃                          (not (and (= index 1)
172┃                                    (<= arg 0)))))))))
173┃    (make-CR
   ┃⋯
1>
```

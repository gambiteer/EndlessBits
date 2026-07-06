;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;
(define *max-precision*
  (make-parameter
   16496    ;; will be overridden when *testing* is #t
   (lambda (n)
     (if (and (exact-integer? n)
              (not (negative? n)))
         n
         (error "The parameter *max-precision* must be a nonnegative exact integer: " n)))))

(define *warn*
  (make-parameter
   #f    ; don't warn on conversion from computable to inexact by default
   (lambda (obj)
     (if (boolean? obj)
         obj
         (error "The paramater *warn* must be a boolean: " obj)))))

(define *debug*
  (make-parameter
   #f    ; don't print debugging information in elementary functions
   (lambda (obj)
     (if (boolean? obj)
         obj
         (error "The paramater *debug* must be a boolean: " obj)))))

(define-macro (setup-primitives)

  (define strict? #f)

  (if strict?

      '(begin

         (define *strict-testing* #t)

         ;; when testing, we don't memoize anything so there are no
         ;; extra-precision results hanging around from previous
         ;; computations.

         (define (k->k* k) k)

         ;; reduce the number of bits to compute before returning +0. in
         ;; computable->inexact.

         (*max-precision* 1100)

         (define (computable-memoize x)
           x)

         (define (table-memoize x)
           x))

      `(begin

         (define *strict-testing* #f)

         ;; When not testing, we memoize the crap out of everything

         (define (k->k* k)
           (+ k (integer-length k)))

         (define (computable-memoize x)
           #|
           Assume
           $$
           |x_n-2^n x|<1;
           $$
           if $k\leq n$ and $x_k$ is $x_n$ shifted right by $n-k$, so that
           $$
           |2^{n-k}x_k-x_n|\leq 2^{n-k}-1,
           $$
           then
           $$
           |2^{n-k}x_k-2^nx|\leq |2^{n-k}x_k-x_n|+|x_n-2^nx|< 2^{n-k}-1 + 1=2^{n-k}.
           $$
           Divide by $2^{n-k}$ to see that $|x_k-2^kx|<1$.
           |#
           (let ((result-so-far #f))
             (lambda (k)
               (let loop ()
                 (if (and result-so-far
                          (<= k (car result-so-far)))
                     (arithmetic-shift  (cdr result-so-far) (- k (car result-so-far)))
                     ;; Here we need to compute a result with more digits than in result-so-far.
                     ;; Experiments have shown that adding log_2(k) more digits
                     ;; speeds algorithms. log_2(k) is about (integer-length k).
                     (let* ((k* (+ k (integer-length k)))
                            (result (x k*)))
                       (set! result-so-far (cons k* result))
                       (loop)))))))

         (define (table-memoize x)
           (let ((table (make-table weak-keys: #t
                                    weak-values: #t
                                    test: eqv?)))
             (lambda (y)
               (cond ((table-ref table y #f))
                     (else
                      (let ((result (x y)))
                        (table-set! table y result)
                        result)))))))
      ))

(setup-primitives)

(define (computable->inexact x #!optional (precision (*max-precision*)) (warn? (*warn*)))

  ;; correctly rounding a number that is exactly zero or halfway between two
  ;; representable floating-point numbers is not computable, and
  ;; this procedure may give a warning if perhaps given such a number

  (define (two^p p)
    (arithmetic-shift 1 p))

  (define (maybe-warn-zero)
    (if warn?
        (pp "computable->inexact: May be trying to convert computable exact 0 to inexact; arbitrarily returning +0.0, not -0.0.")))

  (define (maybe-warn-half)
    (if warn?
        (pp (string-append
             "computable->inexact: May be trying to convert to inexact a computable number halfway between two adjacent double-precision "
             "floating-point numbers; arbitrarily rounding to even."))))

  (define (maybe-warn-small)
    (if warn?
        (pp (string-append
             "computable->inexact: May be trying to convert a computable number halfway between zero and the first nonzero floating-point-number; "
             "arbitrarily returning a zero with the correct sign."))))

  (define (maybe-warn-infinity)
    (if warn?
        (pp (string-append
             "computable->inexact: May be trying to convert to inexact a computable number exactly at the cutoff to round to infinity; "
             "arbitrarily returning an infinity with the correct sign."))))

  (if (<= precision 1075)
      (error "computable->inexact: The precision argument must be at least 1076 bits:" precision))

  (cond
   ((eq? x computable-zero)          0.)
   ((eq? x computable-one)           1.)
   ((eq? x computable-negative-one) -1.)
   (else
    (let loop1 ((p 0))
      (let ((x_p (x p)))
        (if (<= (abs x_p) 1)
            (cond
             ((and (< 1075 p) ;; (expt -1075) is the largest number rounding to zero
                   (= (abs x_p) 1))
              ;; we know x rounds to zero, and we know its sign
              (* 0.0 x_p))
             ((< precision p)

              ;; Because precision >= 1076 and the previous
              ;; condition was negative, we know x_p=0
              ;; We've computed at least precision bits to the right of the
              ;; binary point, and haven't found any significant bits.

              ;; We warn and arbitrarily return +0.

              (maybe-warn-zero)
              +0.)
             (else
              (loop1 (+ (* 2 p) 1))))
            (let ((p (+ p 52)))
              (let* ((x_p
                      (x p))
                     (abs-x_p
                      (abs x_p))
                     (abs-x_p/2^p
                      (/ abs-x_p (two^p p)))
                     (inexact-abs-x_p/2^p            ;; possible answer
                      (exact->inexact abs-x_p/2^p)))
                (cond
                 ((flinfinite? inexact-abs-x_p/2^p)
                  (case (computable-< (computable-abs x)
                                      ;; smallest number that rounds to +inf.0
                                      (->computable (* (expt 2 1023) (- 2 (* 1/2 (expt 2 -52))))))
                    ((1)
                     ;; we're sure that (abs x) is < rounding cutoff
                     (* (if (negative? x_p) -1.0 +1.0)
                        ;; largest finite inexact
                        (inexact (* (expt 2 1023) (- 2 (expt 2 -52))))))
                    ((-1)
                     ;; we're sure that (abs x) is > rounding cutoff
                     (* x_p +inf.0))
                    (else ;; (0)
                     ;; We may be trying to round a number at the rounding cutoff
                     (maybe-warn-infinity)
                     (* x_p +inf.0))))
                 ((flzero? inexact-abs-x_p/2^p)
                  (case (computable-<
                         ;; smallest positive number that rounds to zero
                         (->computable (expt 2 -1075))
                         (computable-abs x))
                    ((1)
                     ;; we're sure that (abs x) is above the cutoff
                     (if (negative? x_p) -5e-324 5e-324))
                    ((-1)
                     ;; we're sure that (abs x) is below the cutoff
                     (if (negative? x_p) -0.0 +0.0))
                    (else ;; (0)
                     (maybe-warn-small)
                     (* x_p +0.0))))
                 (else
                  (let ((abs-result
                         (let ((exact-inexact-abs-x_p/2^p
                                (exact inexact-abs-x_p/2^p))
                               (abs-x
                                (computable-abs x)))

                           (define (choose-simpler-adjacent-exact-double low high)
                             ;; low and high are both dyadic rationals, i.e,
                             ;; their denominators are powers of two
                             (cond ((= (integer-length (denominator low))
                                       (integer-length (denominator high)))
                                    ;; both denominators are 1
                                    (if (< (- (integer-length low)
                                              (first-set-bit low))
                                           (- (integer-length high)
                                              (first-set-bit high)))
                                        (inexact low)
                                        (inexact high)))
                                   ((< (integer-length (denominator low))
                                       (integer-length (denominator high)))
                                    (inexact low))
                                   (else
                                    (inexact high))))

                           ;; (trace choose-simpler-adjacent-exact-double)

                           (call-with-values

                               (lambda ()
                                 (if (<= inexact-abs-x_p/2^p (flexpt 2. -1022.))
                                     ;; <= smallest positive normal number
                                     (values
                                      (expt 2 -1075)
                                      (expt 2 -1075))
                                     ;; > smallest positive normal number
                                     (values
                                      (expt 2 (- (integer-length (numerator   exact-inexact-abs-x_p/2^p))
                                                 (integer-length (denominator exact-inexact-abs-x_p/2^p))
                                                 53))
                                      (expt 2 (- (integer-length (numerator   exact-inexact-abs-x_p/2^p))
                                                 (integer-length (denominator exact-inexact-abs-x_p/2^p))
                                                 (if (= (numerator exact-inexact-abs-x_p/2^p) 1)
                                                     ;; the lower eps is 1/2 the upper eps
                                                     54
                                                     ;; the lower eps equals the upper eps
                                                     53))))))

                             (lambda (high-epsilon low-epsilon)
                               (case (computable-< (->computable (+ exact-inexact-abs-x_p/2^p high-epsilon))
                                                   abs-x)
                                 ((1)
                                  ;; you're sure that (abs x) is > half an epsilon higher
                                  (inexact (+ exact-inexact-abs-x_p/2^p (* 2 high-epsilon))))
                                 ((0)
                                  ;; To precision bits to the right of the binary point,
                                  ;; (abs x) is halway between two adjacent doubles.
                                  (maybe-warn-half)
                                  (choose-simpler-adjacent-exact-double
                                   exact-inexact-abs-x_p/2^p
                                   (+ exact-inexact-abs-x_p/2^p (* 2 high-epsilon))))
                                 (else ;; (-1)
                                  ;; you're sure that (abs x) is < than the upper round point
                                  (case (computable-< abs-x
                                                      (->computable (- exact-inexact-abs-x_p/2^p low-epsilon)))
                                    ((1)
                                     ;; you're positive that abs-x is less than the round value
                                     (inexact (- exact-inexact-abs-x_p/2^p (* 2 low-epsilon))))
                                    ((-1)
                                     ;; you're sure that abs x is > the round value
                                     ;; so you've correctly rounded already
                                     inexact-abs-x_p/2^p)
                                    (else ;; (0)
                                     ;; To precision bits to the right of the binary point,
                                     ;; (abs x) is halway between two adjacent doubles.
                                     (maybe-warn-half)
                                     (choose-simpler-adjacent-exact-double
                                      exact-inexact-abs-x_p/2^p
                                      (- exact-inexact-abs-x_p/2^p (* 2 low-epsilon))))))))))))
                    (if (negative? x_p)
                        (- abs-result)
                        abs-result))))))))))))

#|
Let's say that we can know
$$
|x_k - 2^k x|<1,
$$
and we want to find an integer that satisfies
$$
|X_m - 10^m x| < 1.
$$
So we have
$$
|10^m2^{-k}x_k - 10^m x| < 10^m/2^k.
$$
We'd like the right-hand side to be less than or equal $1/2$, so then
$$
|\round(10^m 2^{-k} x_k)-10^mx|<1.
$$
Taking logs base 2 we want
$$
m\log_2 10 - k \leq -1
$$
or
$$
k \geq m\log_2 10 + 1.
$$
We're going to add two more bits, though, to make it more
likely that the digital value is correctly rounded.
|#

(define (compute-decimal-digits x m)
  ;; (log 10 2) = 3.321928094887362
  (let ((k (exact (ceiling (+ (* m 3.321928094887362) 3)))))
    (NDIV-2^p (* (expt 10 m) (x k))
              k)))

#|

We're going to employ power series in x for some functions, and
(approximately) how big x is determines how many terms how many terms
we're going to need.

Here we know that |x|<2^{-l}.

|#

(define (abs-x<2^-l x)

  ;; we need to assume that |x| will be
  ;; noticeably less than 1, so the result
  ;; will be nonzero.

  (let* ((p 40) ;; the precision of the number of bits to compute
         (abs-x_p (abs (x p))))
    (- p (log (+ abs-x_p 1) 2))))

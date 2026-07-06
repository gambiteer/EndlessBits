;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;
(define computable-asin-reduced-arg

  ;; (asin x) where it's called with |x|<1/2

  (letrec* ((common-factor-ratio
             (lambda (x)
               (lambda (m n)
                 (computable-*-by-rational (computable-expt x (* 2 (- n m)))
                                           (/ (partial-factorial (* 2 m) (* 2 n))
                                              (* (square (partial-factorial m n))
                                                 (expt 4 (- n m))))))))
            (partial-term
             (lambda (x)
               (let ((common-factor-ratio
                      (common-factor-ratio x)))
                 (lambda (m n)
                   (computable-/-by-integer (common-factor-ratio m n)
                                            ( + (* 2 n) 1))))))
            (k*->terms
             (lambda (x)
               (let ((ell (abs-x<2^-l x)))
                 (lambda (k*)
                   (exact (ceiling (/ (+ 1 k*) ell 2))))))))
    (make-incremental-power-series partial-term
                                   common-factor-ratio
                                   k*->terms
                                   #t
                                   asin:)))

(define computable-.3
  (->computable 2457/8192)) ;; a dyadic rational .2999267578125

(define computable-sqrt-3/2
  (computable-/-by-integer computable-sqrt-3 2))

(define computable-asin
  (table-memoize
    (lambda (x)

      (define (asin1 x)
        ;; x is not too negative
        (if (positive? (computable-< computable-half x 10))
            ;; x is > 1/2
            (computable--
             computable-pi/2
             (computable-*-by-integer
              (asin2
               ;; if x > 1, the error will be thrown by the square root
               (computable-sqrt
                (computable-/-by-integer
                 (computable-- computable-one x)
                 2)))
              2))
            (asin2 x)))

      (define (asin2 x)

        ;; x is not too much > 1/2

        #|

        This next transformation is not in Cody & Waite.

        If $X$ is near $1/2$ and
        $$
        g(X)=\frac
        {\left(X-\dfrac12\right)\left(X+\dfrac12\right)}
        {\dfrac{\sqrt 3} 2X+\sqrt{\left(\dfrac{\sqrt 3}2X\right)^2-\left(X-\dfrac12\right)\left(X+\dfrac12\right)}},
        $$
        then
        $$
        \asin(X)=\frac\pi 6+\asin(g(X)).
        $$
        Now if $X$ is {\it really\/} close to $1/2$, then $g(X)$ will be really close
        to zero, so the power series for $\asin$, which has radius of convergence 1,
        will require many fewer terms to compute $\asin(g(X))$ than it will take to
        compute $\asin(X)$.

        If
        $$
        \tilde x=\frac{\sqrt{2-\sqrt 3}} 2\approx 0.2588190451025207623\ldots,
        $$
        then $|g(\tilde x)|=\tilde x$, so we shouldn't use the transformation $g(X)$
        for $X<\tilde x$.

        On the other hand, a power series in $g(X)$ will cost more instructions
        per term than a power series in $X$, because $g(X)$ costs more to compute,
        it's a complicated expression.

        We've found by experiment that the $g(X)$ transformation is worthwhile if
        $x$ is greater than about $0.3$.

        |#

        (if (positive? (computable-< computable-.3 x))
            (let* ((g-numerator
                    (computable-* (computable-- x computable-half)
                                  (computable-+ x computable-half)))
                   (sqrt-3/2*x
                    (computable-* computable-sqrt-3/2 x))
                   (g
                    (computable-/
                     g-numerator
                     (computable-+
                      sqrt-3/2*x
                      (computable-sqrt
                       (computable-- (computable-square sqrt-3/2*x)
                                     g-numerator))))))
              (computable-+ computable-pi/6 (asin3 g)))
            (asin3 x)))

      (define (asin3 x)
        (if (eq? x computable-zero)
            computable-zero
            (computable-asin-reduced-arg x)))

      (if (positive? (computable-< x computable-zero 10))
          ;; we don't need much precision here because the power series works
          ;; for negative x near zero
          (computable-negate (asin1 (computable-negate x)))
          (asin1 x)))))

(define (computable-acos x)
  (computable-- computable-pi/2 (computable-asin x)))

;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;
(define (computable-binary-splitting-partial-sum m n
                                                 partial-term
                                                 common-factor-ratio)
  ;; sums (partial) terms from m to n-1
  ;; (partial-term m n) is the term at n with the common factors of terms >= m removed
  ;; (common-factor-ratio m n) is the ratio of the common factor of terms >= n divided by
  ;; the common factors of terms >= m.
  ;; we actual write (common-factor-ratio m n) as
  ;; (/ (rest-of-common-factor-ratio m n)
  ;;    (common-factor-ratio-exact-denominator m n))
  ;; to speed things up

  (if (< (- n m) 10)
      (apply computable-+ (map (lambda (i) (partial-term m i)) (iota (- n m) m)))
      (computable-+ (computable-binary-splitting-partial-sum m
                                                             (quotient (+ m n) 2)
                                                             partial-term
                                                             common-factor-ratio)
                    (computable-* (computable-binary-splitting-partial-sum (quotient (+ m n) 2)
                                                                           n
                                                                           partial-term
                                                                           common-factor-ratio)
                                  (common-factor-ratio m (quotient (+ m n) 2))))))

#|
If
$$
\pi_n=\frac{2(a_{n+1})^2}{1-\sum_{j=0}^n 2^jc_j^2}
$$
then
$$
0<\pi-\pi_n<\frac {\pi^2 2^{n+4}e^{-\pi 2^{n+1}}}{(\operatorname{AGM}(1/\sqrt{2}))^2}.
$$
We shall attempt to estimate that bound accurately.  The $\log_2$
of the error is thus bounded by
$$
\log_2(\pi^2\times 16/(\operatorname{AGM}(1/\sqrt{2}))^2)+n
-\pi2^{n+1}\log_2 e.
$$
|#

(define (brent-salamin-iters k)

  ;; returns the number of brent-salamin iterations to give k bits of accuracy

  (define (log_2 x)
    (/ (log x) (log 2)))

  (define (AGM a)
    (let loop ((a a)
               (b 1))
      (if (< (/ (abs (- a b)) a)
             (expt 10. -10))
          (/ (+ a b)
             2.)
          (loop (/ (+ a b)
                   2.)
                (sqrt (* a b))))))

  (define pi (* (atan 1) 4))

  (define e (exp 1))

  (define (square x) (* x x))

  (let ((const (log_2 (* pi pi 16
                         (/ (square (AGM (/ (sqrt 2))))))))
        (log_2-e (log_2 e)))
    (let loop ((n 1))
      (if (< (+ k 1)
             (- (+ const
                n
                (- (* pi (expt 2 (+ n 1)) log_2-e)))))
          n
          (loop (+ n 1))))))

(define computable-pi

  ;; The Brent Salamin algorithm is not really suited
  ;; for incremental increases in precision, so we manage
  ;; the increased need of precision manually and either
  ;; double the existing precision or use (+ k (integer-length k)),
  ;; whichever is bigger.

  (let ((k* 0)
        (value 3))

    (define (reset-k*)
      (if *strict-testing*
          (begin
            (set! k* 0)        ;; the integer part of pi is 3
            (set! value 3))))

    (lambda (k)
      (if (<= k k*)
          (let ((answer
                 (arithmetic-shift value (- k k*))))
            (reset-k*)
            answer)
          (let ((new-k* (max (* 2 k*) (+ k (integer-length k)))))
            (let ((n (brent-salamin-iters new-k*)))
              (do ((i 0 (+ i 1))
                   (a computable-one
                      (computable-/-by-integer (computable-+ a b) 2))
                   (b (computable-sqrt (->computable 1/2))
                      (computable-sqrt (computable-* a b)))
                   (t (->computable 1/4)
                      (computable-- t
                                    (computable-* (->computable x)
                                                  (computable-square (computable-- b a)))))
                   (x 1/4 (* 2 x)))
                  ((= i n)
                   (let ((final-result (computable-/ (computable-square (computable-+ a b))
                                                     (computable-*-by-integer t 4))))
                     (set! value (balanced-quotient (final-result (+ new-k* 1)) 2))
                     (set! k* new-k*)
                     (computable-pi k))))))))))

(define computable-pi/2
  (computable-/-by-integer computable-pi 2))

(define computable-pi/6
  (computable-/-by-integer computable-pi 6))

(define computable-sqrt-3
  (computable-sqrt (->computable 3)))

(define computable-sqrt-3/2
  (computable-/-by-integer computable-sqrt-3 2))

(define computable-2-sqrt-3
  (computable-- (->computable 2)
                computable-sqrt-3))

#|
We're going to use the naive series
$$
\log(2)=\sum_{k=1}^\infy \frac 1{k2^k}
$$
and compute for $a<b$
$$
S(a,b)
=
2^b\sum_{a\leq k<b}\frac1{k2^k}
=
\sum_{a\leq k<b}\frac{2^{b-k}}k
=
\frac{P(a,b)}{Q(a,b)},
$$
where $P(a,b)$ and $Q(a,b)$ are integers.  So
$$
S(1,N)
=
2^N\sum_{1\leq k<N}\frac 1{k2^k}
$$
and if $N$ is greater than 3,
(balanced-quotient $P(1,N)$ $Q(1,N)$) is $\log(2)_N$.

So
$$
S(a,a+1)=\frac 2 a,\quad P(a,a+1)=2,\quad Q(a,a+1)=a,
$$
and if $a<m<b$, then
$$
S(a,b)
=
2^b\left(\sum_{a\leq k<m}\frac 1{k2^k} + \sum_{m\leq k<b}\frac 1{k2^k}\right)
=
2^{b-m}\left(2^m\sum_{a\leq k<m}\frac 1{k2^k}\right)
+
2^b \sum_{m\leq k<b}\frac 1{k2^k}
=
2^{b-m}S(a,m)+S(m,b)
=
\frac{2^{b-m}P(a,m)}{Q(a,m)}+\frac{P(m,b)}{Q(m,b)}
=
\frac
{2^{b-m}\left(Q(m,b)\times P(a,m)\right) + Q(a,m)\times P(m,b)}
{Q(a,m)\times Q(m,b)}.
$$

The question is how many terms we need.  Basically, to get $N$ bits
correct we need roughly $N-\log_2(N)$ terms.  But even for moderately large $N$
the second term is not that important, and it's going to be tricky to get it right.

So we're just going to take $N-1$ terms, which works for $N>3$.
|#

(define computable-log-2

  (let ((P-stored 32)
        (Q-stored 3)
        (N 4)
        (value 11))

    (lambda (k)

      (define (return P Q)
        (values P Q))

      (define (combine P_am Q_am P_mb Q_mb m b)
        (return (+ (arithmetic-shift (* Q_mb P_am) (- b m))
                   (* Q_am P_mb))
                (* Q_am Q_mb)))

      (define (P+Q a b)
        (if (= b (+ a 1))
            (return 2 a)
            (let ((m (quotient (+ a b) 2)))
              (call-with-values
                  (lambda ()
                    (P+Q a m))
                (lambda (P_am Q_am)
                  (call-with-values
                      (lambda ()
                        (P+Q m b))
                    (lambda (P_mb Q_mb)
                      (combine P_am Q_am P_mb Q_mb m b))))))))

      (define (shift-P+Q P Q)
        ;; calculate P and Q and remove common powers of 2
        (let ((shift (min (first-set-bit P) (first-set-bit Q))))
          (return (arithmetic-shift P (- shift))
                  (arithmetic-shift Q (- shift)))))

      (if (<= k N)
          ;; The precomputed value has enough bits for us to use.
          (NDIV-2^p value (- N k))
          ;; We take the stored values, add enough terms to compute
          ;; a few more bits than we need, call procedure again.
          (let ((k* (k->k* k)))
            (call-with-values
                (lambda ()
                  (P+Q N k*))
              (lambda (P Q)
                (call-with-values
                    (lambda ()
                      (shift-P+Q P Q))
                  (lambda (P Q)
                    (call-with-values
                        (lambda ()
                          (combine P-stored Q-stored P Q N k*))
                      (lambda (P Q)
                        (call-with-values
                            (lambda ()
                              (shift-P+Q P Q))
                          (lambda (P Q)
                            (set! P-stored P)
                            (set! Q-stored Q)
                            (set! N k*)
                            (set! value (balanced-quotient P Q))
                            (computable-log-2 k))))))))))))))

(define (make-incremental-power-series partial-term          ;; (lambda (x) (lambda (m n) ...))
                                       common-factor-ratio   ;; (lambda (x) (lambda (m n) ...))
                                       k*->terms             ;; (lambda (x) (lambda (k*) ...))
                                       multiply-series-by-x? ;; if #f, multiply by computable-one
                                       debug-name            ;; name to print in debug messages
                                       )
  (table-memoize
    (lambda (x)
      (let ((partial-term
             (partial-term x))
            (common-factor-ratio
             (common-factor-ratio x))
            (k*->terms
             (k*->terms x))
            (number-of-terms #f)
            (sum-of-terms #f)
            (k* #f)
            (v* #f))

        (define (reset-k*)
          (if *strict-testing* (set! k* #f)))

        (define (result k)
          (cond ((not k*)
                 (if (*debug*) (pp (list debug-name new-power-series: arg: x k: k)))
                 (set! k*
                       (k->k* k))
                 (set! number-of-terms
                       (k*->terms k*))
                 (set! sum-of-terms
                       (computable-* (if multiply-series-by-x? x computable-one)
                                     (computable-binary-splitting-partial-sum
                                      0
                                      number-of-terms
                                      partial-term
                                      common-factor-ratio)))
                 (set! v*
                       (sum-of-terms k*))
                 (result k))
                ((<= k k*)
                 (if (*debug*) (pp (list debug-name found-existing-value: arg: x k*: k* k: k number-of-terms: number-of-terms)))
                 (let ((result
                        (arithmetic-shift v* (- k k*))))
                   (reset-k*)
                   result))
                (else
                 (if (*debug*) (pp (list debug-name extending-power-series: arg: x k*: k* k: k)))
                 (let* ((new-k*
                         (k->k* k))
                        (new-number-of-terms
                         (max
                          number-of-terms
                          (k*->terms new-k*)))
                        (new-sum-of-terms
                         (computable-+
                          sum-of-terms
                          (computable-*
                           (if multiply-series-by-x? x computable-one)
                           (computable-*
                            (computable-binary-splitting-partial-sum
                             number-of-terms
                             new-number-of-terms
                             partial-term
                             common-factor-ratio)
                            (common-factor-ratio 0 number-of-terms)))))
                        (new-v*
                         (new-sum-of-terms new-k*)))
                   (set! k* new-k*)
                   (set! v* new-v*)
                   (set! number-of-terms new-number-of-terms)
                   (set! sum-of-terms new-sum-of-terms)
                   (result k)))))

        result))))

;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;
(define reduce-x-by-pi/2
  (table-memoize
    (lambda (x)
      (let* ((n   ;; nearest multiple of pi/2; doesn't need to be exact, just that $|reduced-x|<1$
              (round-quotient
               ((computable-/ x computable-pi/2) 10) ;; compute (/ x pi/2) to 10 bits
               1024))
             (reduced-x
              (computable-- x (computable-*-by-integer computable-pi/2 n))))
        (values n reduced-x)))))  ;; a definite Gambitism, builds a values object that is stored in a table

(define computable-sin-reduced-arg
  (letrec* ((common-factor-ratio
             (lambda (x)
               (lambda (m n)
                 (computable-/-by-integer (computable-expt x (* 2 (- n m)))
                              (partial-factorial (+ (* 2 m) 1)
                                                 (+ (* 2 n) 1))))))
            (partial-term
             (lambda (x)
               (let ((common-factor-ratio
                      (common-factor-ratio x)))
                 (lambda (m n)
                   (if (odd? n)
                       (computable-negate (common-factor-ratio m n))
                       (common-factor-ratio m n))))))
            (k*->terms
             (lambda (x)
               (let ((ell (abs-x<2^-l x)))
                 (lambda (k*)
                   (+ 1 (exact (ceiling (/ (m!2^ml>2^k ell (+ k* 1)) 2)))))))))
    (make-incremental-power-series partial-term
                                   common-factor-ratio
                                   k*->terms
                                   #t
                                   sin:)))

(define computable-cos-reduced-arg
  (letrec* ((common-factor-ratio
             (lambda (x)
               (lambda (m n)
                 (computable-/-by-integer (computable-expt x (* 2 (- n m)))
                                          (partial-factorial (* 2 m)
                                                             (* 2 n))))))
            (partial-term
             (lambda (x)
               (let ((common-factor-ratio
                      (common-factor-ratio x)))
                 (lambda (m n)
                   (if (odd? n)
                       (computable-negate (common-factor-ratio m n))
                       (common-factor-ratio m n))))))
            (k*->terms
             (lambda (x)
               (let ((ell (abs-x<2^-l x)))
                 (lambda (k*)
                   (+ 1 (exact (ceiling (/ (m!2^ml>2^k ell (+ k* 1)) 2)))))))))
    (make-incremental-power-series partial-term
                                   common-factor-ratio
                                   k*->terms
                                   #f
                                   cos:)))

(define computable-sin
  (table-memoize
    (lambda (x)
      (if (eq? x computable-zero)
          computable-zero
          (call-with-values
              (lambda ()
                (reduce-x-by-pi/2 x))
            (lambda (n reduced-x)
              (if (even? n)
                  (if (even? (quotient n 2))
                      (computable-sin-reduced-arg reduced-x)
                      (computable-negate (computable-sin-reduced-arg reduced-x)))
                  (if (even? (quotient (- n 1) 2))
                      (computable-cos-reduced-arg reduced-x)
                      (computable-negate (computable-cos-reduced-arg reduced-x))))))))))

(define computable-cos
  (table-memoize
    (lambda (x)
      (if (eq? x computable-zero)
          computable-one
          (call-with-values
              (lambda ()
                (reduce-x-by-pi/2 x))
            (lambda (n reduced-x)
              (if (even? n)
                  (if (even? (quotient n 2))
                      (computable-cos-reduced-arg reduced-x)
                      (computable-negate (computable-cos-reduced-arg reduced-x)))
                  (if (even? (quotient (- n 1) 2))
                      (computable-negate (computable-sin-reduced-arg reduced-x))
                      (computable-sin-reduced-arg reduced-x)))))))))

(define computable-tan
  ;; I can't think of a better way of doing this, so ...
  (table-memoize
    (lambda (x)
      (call-with-values
          (lambda ()
            (reduce-x-by-pi/2 x))
        (lambda (n reduced-x)
          (if (even? n)
              (computable-/ (computable-sin reduced-x)
                            (computable-cos reduced-x))
              (computable-negate
               (computable-/ (computable-cos reduced-x)
                             (computable-sin reduced-x)))))))))

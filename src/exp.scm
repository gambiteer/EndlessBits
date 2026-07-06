;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;
(define reduce-x-by-log-2
  (table-memoize
    (lambda (x)
      (let* ((n   ;; nearest multiple of (log 2); doesn't need to be exact
              (round-quotient
               ((computable-/ x computable-log-2) 10) ;; compute (/ x (log 2)) to 10 bits
               1024))
             (reduced-x
              (computable-- x (computable-*-by-integer computable-log-2 n))))
        (values n reduced-x)))))  ;; a definite Gambitism, builds a values object

(define computable-exp-reduced-arg
  (letrec* ((partial-term
             (lambda (x)
               (lambda (m n)
                 (computable-/-by-integer (computable-expt x (- n m))
                                          (partial-factorial m n)))))
            (common-factor-ratio
             partial-term)
            (k*->terms
             (lambda (x)
               (let ((ell (abs-x<2^-l x)))
                 (lambda (k*)
                   (+ 1 (exact (ceiling (m!2^ml>2^k ell (+ k* 1))))))))))
    (make-incremental-power-series partial-term
                                   common-factor-ratio
                                   k*->terms
                                   #f
                                   exp:)))
(define computable-exp
  (table-memoize
    (lambda (x)
      (if (eq? x computable-zero)
          computable-one
          (call-with-values
              (lambda ()
                (reduce-x-by-log-2 x))
            (lambda (n reduced-x)
              (computable-*-by-rational
               (computable-exp-reduced-arg reduced-x)
               (expt 2 n))))))))

(define computable-e
  (computable-exp computable-one))

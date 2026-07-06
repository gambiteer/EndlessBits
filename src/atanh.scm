;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;
(define computable-atanh-reduced-arg
  ;; assumes |x|<= 1/4 (approximately) when called from computable-atanh
  ;; and     |x| <= (- (sqrt 2) 1) (+ (sqrt 2) 1)) \approx .17157287525380996
  ;; when called from log.

  (letrec* ((common-factor-ratio
             (lambda (x)
               (lambda (m n)
                 (computable-expt x (* 2 (- n m))))))
            (partial-term
             (lambda (x)
               (let ((common-factor-ratio (common-factor-ratio x)))
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
                                   atanh:)))

(define (computable-atanh x)
  ;; I used to use computable-atanh-reduced-arg for small
  ;; arguments, but every time you use a power series you
  ;; have to add in all the special cases by hand, so I'll
  ;; just let computable-log call computable-atanh-reduced-arg
  (computable-/-by-integer
   (computable-log
    (computable-/ (computable-+ computable-one x)
                  (computable-- computable-one x)))
   2))

(define (computable-asinh x)
  (computable-log
   (computable-+ x
                 (computable-sqrt
                  (computable-+ (computable-square x)
                                computable-one)))))

(define (computable-acosh x)
  ;; computable-sqrt will thrown the error if |x|>1
  (computable-log
   (computable-+ x
                 (computable-sqrt
                  (computable-- (computable-square x)
                                computable-one)))))

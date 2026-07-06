;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;
(define computable-atan-reduced-arg
  (letrec* ((common-factor-ratio
             (lambda (x)
               (lambda (m n)
                 (computable-expt x (* 2 (- n m))))))
            (partial-term
             (lambda (x)
               (let ((common-factor-ratio
                      (common-factor-ratio x)))
                 (lambda (m n)
                   (computable-/-by-integer (common-factor-ratio m n)
                                            (* (if (odd? n) -1 1)
                                               ( + (* 2 n) 1)))))))
            (k*->terms
             (lambda (x)
               (let ((ell (abs-x<2^-l x)))
                 (lambda (k*)
                   (exact (ceiling (/ (+ k* 1) (* 2 ell)))))))))
    (make-incremental-power-series partial-term
                                   common-factor-ratio
                                   k*->terms
                                   #t
                                   atan:)))

(define (computable-atan x)
  (cond ((eq? x computable-zero)
         computable-zero)
        ((positive? (computable-< x computable-zero 10))
         (computable-negate
          (computable-atan (computable-negate x))))
        ((positive? (computable-< computable-one x 10))
         (computable--
          computable-pi/2
          (computable-atan (computable-inverse x))))
        ((positive? (computable-< computable-2-sqrt-3 x 20))
         (computable-+
          computable-pi/6
          (computable-atan
           (computable-/ (computable-- (computable-* x computable-sqrt-3)
                                       computable-one)
                         (computable-+ computable-sqrt-3
                                       x)))))
        (else
         (computable-atan-reduced-arg x))))


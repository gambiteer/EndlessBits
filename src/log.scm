;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;

(define reduce-by-power-of-two
  (case-lambda
   ((x)
    (reduce-by-power-of-two x (*max-precision*)))
   ((x precision)
    ;; return n and x-reduced with
    ;; \sqrt{1/2} <= x <= \sqrt 2
    ;; (approximately) and
    ;; x = x-reduced * 2^n
    (let loop ((p 0))
      ;; first we find at least the top 20 bits of x
      (let ((x_p (x p)))
        (cond ((negative? x_p)
               (error "computable-log: argument is negative: " x))
              ((> x_p 1)
               (let* ((p  ;; get at least 20 significant bits
                       (+ p (max 0 (- 21 (integer-length x_p)))))
                      (x_p
                       (x p))
                      (x_p-length
                       (integer-length x_p))
                      (possible-x
                       (inexact (/ x_p (expt 2 x_p-length))))
                      (adjustment
                       (if (< possible-x (sqrt 1/2))
                           (- p x_p-length -1)
                           (- p x_p-length)))
                      (x-reduced
                       (if (negative? adjustment)
                           (computable-/-by-integer x (expt 2 (- adjustment)))
                           (computable-*-by-integer x (expt 2 adjustment)))))
                 (values (- adjustment) x-reduced)))
              ((> p precision)
               (if (zero? x_p)
                   (error "computable-log: x is zero to \"precision\" bits: " x)
                   (error "computable-log: positive x is zero to \"precision\" bits: " x precision)))
              (else
               (loop (+ 1 (* 2 p))))))))))

(define (computable-log x)
  (cond ((eq? x computable-one)
         computable-zero)
        ((eq? x computable-zero)
         (error "computable-log: x is zero."))
        (else
         (call-with-values
             (lambda ()
               (reduce-by-power-of-two x))
           (lambda (n x-reduced)
             (let ((g (computable-/ (computable-- x-reduced computable-one)
                                    (computable-+ x-reduced computable-one))))
               (computable-+
                (computable-*-by-integer (computable-atanh-reduced-arg g) 2)
                (computable-*-by-integer computable-log-2 n))))))))


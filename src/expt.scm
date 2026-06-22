(define basic-expt
  (table-memoize
    (lambda (x)
      (cond ((eq? x computable-one)
             computable-one)
            ((eq? x computable-negative-one)
             (lambda (n)
               (if (odd? n)
                   computable-negative-one
                   computable-one)))
            ((eq? x computable-zero)
             (lambda (n)
               (cond ((positive? n)
                      computable-zero)
                     ((zero? n)
                      computable-one)
                     (else
                      ;; (negative? n)
                      (error "(computable-expt computable-zero negative-number): " n)))))
            ;; general case
            (else
             (table-memoize
               (lambda (n)
                 (cond ((eqv? 0 n)
                        computable-one)
                       ((= n 1)
                        x)
                       ;; general case
                       ;; compute one step of the exponential computation
                       ;; calling the result for this x when needed
                       ((negative? n)
                        (computable-inverse ((basic-expt x) (- n))))
                       ((even? n)
                        (computable-square ((basic-expt x) (quotient n 2))))
                       (else
                        (computable-* x (computable-square ((basic-expt x) (quotient n 2)))))))))))))

(define (computable-expt x n)
  ((basic-expt x) n))

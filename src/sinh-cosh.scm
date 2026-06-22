(define computable-sinh-reduced-arg

  ;; (sinh x) where $|x|\leq 1$, so $|sin(x)|<(e-e^{-1])/2$

  ;; This series has half as many terms as computable-exp
  ;; and it replaces two calls to computable-exp, so it should
  ;; be about four times as fast as the naive formula.

  (letrec* ((partial-term
             (lambda (x)
               (lambda (m n)
                 (computable-/-by-integer (computable-expt x (* 2 (- n m)))
                                          (partial-factorial (+ (* 2 m) 1)
                                                             (+ (* 2 n) 1))))))
            (common-factor-ratio
             (lambda (x)
               (let ((partial-term (partial-term x)))
                 partial-term)))
            (k*->terms
             (lambda (x)
               (let ((ell (abs-x<2^-l x)))
                 (lambda (k*)
                   (+ 1 (exact (ceiling (/ (m!2^ml>2^k ell (+ k* 1)) 2)))))))))
    (make-incremental-power-series partial-term
                                   common-factor-ratio
                                   k*->terms
                                   #t
                                   sinh:)))

(define computable-cosh-reduced-arg

  ;; (cosh x) where $|x|\leq 1$, so $1\leq cosh(x)\leq (e+e^{-1})/2$

  ;; This series has half as many terms as computable-exp
  ;; and it replaces two calls to computable-exp, so it should
  ;; be about four times as fast as the naive formula.

  (letrec* ((partial-term
             (lambda (x)
               (lambda (m n)
                 (computable-/-by-integer (computable-expt x (* 2 (- n m)))
                                          (partial-factorial (* 2 m)
                                                             (* 2 n))))))
            (common-factor-ratio
             (lambda (x)
               (let ((partial-term (partial-term x)))
                 partial-term)))
            (k*->terms
             (lambda (x)
               (let ((ell (abs-x<2^-l x)))
                 (lambda (k*)
                   (+ 1 (exact (ceiling (/ (m!2^ml>2^k ell (+ k* 1)) 2)))))))))
    (make-incremental-power-series partial-term
                                   common-factor-ratio
                                   k*->terms
                                   #f
                                   cosh:)))

(define computable-sinh
  (table-memoize
    (lambda (x)
      (cond ((eq? x computable-zero)
             computable-zero)
            ((positive? (computable-< (computable-abs x) computable-one 10))
             (computable-sinh-reduced-arg x))
            (else
             (computable-/-by-integer
              (computable-- (computable-exp x)
                            (computable-exp (computable-- x)))
              2))))))

(define computable-cosh
  (table-memoize
    (lambda (x)
      (cond ((eq? x computable-zero)
             computable-one)
            ((positive? (computable-< (computable-abs x) computable-one 10))
             (computable-cosh-reduced-arg x))
            (else
             (computable-/-by-integer
              (computable-+ (computable-exp x)
                            (computable-exp (computable-- x)))
              2))))))

(define computable-tanh
  (table-memoize
    (lambda (x)
      (cond ((positive? (computable-< (computable-abs x) computable-one 10))
             (computable-/ (computable-sinh x)
                           (computable-cosh x)))
            ((positive? (computable-< x computable-zero 10))
             ;; doesn't need to be accurate, first case deals with x near 0
             (computable-negate (computable-tanh (computable-negate x))))
            (else
             (let ((e^-2x
                    (computable-exp (computable-negate (computable-*-by-integer x 2)))))
               (computable-- computable-one
                             (computable-/ (computable-*-by-integer e^-2x 2)
                                           (computable-+ computable-one e^-2x)))))))))

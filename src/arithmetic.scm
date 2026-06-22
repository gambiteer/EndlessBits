;;; some special cases

(define computable-one
  (lambda (n) (arithmetic-shift 1 n)))

(define computable-negative-one
  (lambda (n) (arithmetic-shift -1 n)))

(define computable-zero
  (lambda (n) 0))

(define computable-half
  (lambda (n)
    (arithmetic-shift 1 (- n 1))))

;;; going from rationals to computable numbers

(define (->computable r)
  (if (not (rational? r))
      (error "->computable: argument is not rational: " r)
      (let ((r (exact r)))
        (cond ((integer? r)
               (case r
                 ((0) computable-zero)
                 ((1) computable-one)
                 ((-1) computable-negative-one)
                 (else
                  (lambda (n) (arithmetic-shift r n)))))
              ((power-of-two? (denominator r))
               (let ((num
                      (numerator r))
                     (log_2-den
                      (first-set-bit (denominator r))))
                 (lambda (n)
                   (arithmetic-shift num (- n log_2-den)))))
              (else
               (computable-memoize
                 (lambda (n)
                   ((case (random-integer 6)
                      ((0) round-quotient)
                      ((1) floor-quotient)
                      ((2) ceiling-quotient)
                      ((3) truncate-quotient)
                      ((4) euclidean-quotient)
                      ((5) balanced-quotient))
                    (arithmetic-shift (numerator r) n)
                    (denominator n)))))))))

;;; Some simple functions
;;; There has to be some trade-off between computation time and space.
;;; We'll try not to memoize these functions.

;;; the proofs for the following functions are trivial

(define (computable-negate r)
  (cond ((eq? r computable-one)
         computable-negative-one)
        ((eq? r computable-negative-one)
         computable-one)
        ((eq? r computable-zero)
         computable-zero)
        (else
         (computable-memoize
           (lambda (n)
             (- (r n)))))))

(define (computable-abs r)
  (cond ((or (eq? r computable-one)
             (eq? r computable-negative-one))
         computable-one)
        ((eq? r computable-zero)
         computable-zero)
        (else
         (computable-memoize
           (lambda (n)
             (abs (r n)))))))

(define (computable-max x . ys)
  (computable-memoize
    (lambda (k)
      (apply max (x k) (map (lambda (y) (y k)) ys)))))

(define (computable-min x . ys)
  (computable-memoize
    (lambda (k)
      (apply min (x k) (map (lambda (y) (y k)) ys)))))

;;; Nontrivial functions.

(define (computable-+ . xs)
  (let* ((xs (remq computable-zero xs)) ;; remove computable-zero
         (p (two^p>=abs_m (length xs))))
    #|
    In the following formula we have
    $$
    |x[i]_{n+p+1}-2^{n+p+1}x[i]|<1,
    $$
    so add and subtract $\sum_i x[i]_{n+p+1}$ to see
    $$
    |2^{p+1} (NDIV-2^p (\sum_i x[i]_{n+p+1}) (p+1)) - 2^{n+p+1}\sum_i x[i]|
    \leq
    2^p + |\sum_i x[i]_{n+p+1}-2^{n+p+1}\sum_i x[i]|
    <
    2^p + m
    \leq
    2^{p+1}.
    $$
    So divide by $2^{p+1}$ to see we get what we want.
    |#
    (cond
     ((null? xs)
      computable-zero)
     ((null? (cdr xs))
      (car xs))
     ((and (null? (cddr xs))
           (or (and (eq? (car xs) computable-one)
                    (eq? (cadr xs) computable-negative-one))
               (and (eq? (cadr xs) computable-one)
                    (eq? (car xs) computable-negative-one))))
      computable-zero)
     (else
      (computable-memoize
        (lambda (n)
          (NDIV-2^p (apply + (map-left-to-right (lambda (x) (x (+ n p 1))) xs))
                    (+ p 1))))))))

(define computable--
  (case-lambda
   ((x)
    (computable-negate x))
   ((x y)
    (if (eq? x y)
        computable-zero
        (computable-+ x (computable-negate y))))
   ((x . ys)
    (computable-- x (apply computable-+ ys)))))

(define (computable-*-by-integer x m)
  (cond ((= m 0)
         computable-zero)
        ((= m 1)
         x)
        ((= m -1)
         (computable-negate x))
        ((eq? x computable-zero)
         computable-zero)
        ((eq? x computable-one)
         (->computable m))
        ((eq? x computable-negative-one)
         (->computable (- m)))
        ((power-of-two? m)
         (let ((log_2-m (first-set-bit m)))
           (lambda (n) (x (+ n log_2-m)))))
        (else
         (let ((p (two^p>=abs_m m)))
           ;; see proof for computable-summation
           (computable-memoize
             (lambda (n)
               (NDIV-2^p (* m (x (+ n p 1)))
                         (+ p 1))))))))

(define (computable-/-by-integer x m)
  (cond ((= m 0)
         (error 'computable-/-by-integer x m))
        ((= m 1)
         x)
        ((= m -1)
         (computable-negate x))
        ((eq? x computable-zero)
         computable-zero)
        ((power-of-two? m)
         (let ((log_2-m (first-set-bit m)))
           (lambda (k)
             (if (< k log_2-m)
                 (arithmetic-shift (x 0) (- k log_2-m))
                 (x (- k log_2-m))))))
        (else
         (let ((p (two^p<=abs_m m)))
           (computable-memoize
             (lambda (n)
               (let ((p (min p (+ n 1))))
                 #|
                 We have $2^p\leq |m|$ and $p\leq n+1$, so if
                 $$
                 |x_{n-p+1}-2^{n-p+1}x|<1,
                 $$
                 then
                 $$
                 |2^{p-1}x_{n-p+1}-2^nx|<2^{p-1}.
                 $$
                 Since
                 $$
                 |m\times (NDIV (2^{p-1}x_{n-p+1}) m) - 2^{p-1}x_{n-p+1}|\leq |m|/2,
                 $$
                 so add and subtract $2^{p-1}x_{n-p+1}$ in the following to see that
                 $$
                 |m\times (NDIV (2^{p-1}x_{n-p+1}) m) - 2^n x|
                 <
                 2^{p-1}+|m|/2
                 \leq
                 |m|/2+|m|/2=|m|.
                 $$
                 Divide by |m| to get the inequality we need.
                 |#
                 (NDIV (arithmetic-shift (x (+ n (- p) 1))
                                         (- p 1))
                       m))))))))

(define (computable-*-by-rational x r)
  (let ((r (inexact->exact r)))
    (cond ((= r 0) computable-zero)
          ((= r 1) x)
          ((= r -1) (computable-negate x))
          ((eq? x computable-zero) x)
          ((eq? x computable-one) (->computable r))
          ((eq? x computable-negative-one) (->computable (- r)))
          (else
           (let ((p (numerator r))
                 (q (denominator r)))
             (computable-*-by-integer (computable-/-by-integer x q) p))))))

(define (computable-inverse x #!optional (precision (*max-precision*)))
  (cond
   ((or (eq? x computable-one)
        (eq? x computable-negative-one))
    x)
   ((eq? x computable-zero)
    (error 'computable-inverse x))
   (else
    (let loop ((p 0))
      (let ((abs_x_p (abs (x p))))
        (cond
         ((< 1 abs_x_p)
          (let ((r (two^p<abs_m abs_x_p)))
              #|
              We have $|x_p|>2^r$ so $2^p|x|>2^r$ or $|x|>2^{r-p}$.
              Thus
              $$
              2^k|x|>2^{r-p+k}
              $$
              and
              $$
              |x_k|\geq 2^{r-p+k}.
              $$
              Now
              $$
              |(NDIV 2^{k+n} x_k) - 2^{k+n}/x_k| \leq 1/2.
              $$
              $$
              I want to choose $n$ that
              $$
              |2^{k+n}/x_k-2^n/x|<1/2,
              $$
              or
              $$
              |2^{k+n}x-2^nx_k|<|xx_k|/2,
              $$
              or
              $$
              |2^kx-x_k|<|xx_k|/2^{n+1}.
              $$

              The left hand side is $<1$, so we need
              $$
              |xx_k|/2^{n+1}\geq 1,
              $$
              or
              $$
              |xx_k|\geq 2^{n+1}.
              $$
              But
              $$
              |xx_k|> 2^{r-p}  2^{r-p+k}=2^{2r-2p+k}
              $$
              so we need
              $$
              2r-2p+k \geq n+1
              $$
              or $k\geq n+1-2r+2p$.

              Then
              $$
              |(NDIV 2^{k+n} x_k) - 2^n/x| < 1.
              $$

              |#
            (computable-memoize
              (lambda (n)
                (let ((k (max 0 (+ n 1 (* 2 (- p r))))))
                  (NDIV (arithmetic-shift 1 (+ k n))
                        (x k)))))))
         ((<= precision p)
          (if (zero? abs_x_p)
              (error "computable-inverse: argument is zero to many bits: " p)
              (error "computable-inverse: nonzero argument is zero to many bits: " p)))
         (else
          (loop (+ (* 2 p) 1)))))))))

(define (computable-*2 x y)
  (cond ((or (eq? x computable-zero)
             (eq? y computable-zero))
         computable-zero)
        ((eq? x computable-one)
         y)
        ((eq? y computable-one)
         x)
        ((eq? x computable-negative-one)
         (computable-negate y))
        ((eq? y computable-negative-one)
         (computable-negate x))
        (else
         (computable-memoize
           (lambda (k)
             #|
             Let
             $$
             k^*=\lfloor \frac{k+1}2\rfloor.
             $$
             Find the least $s$ such that
             $$
             2^s>|x_{k^*}|,
             $$
             so $s\geq 0$ and
             $$
             2^s>2^{k^*}|x|,
             $$
             or
             $$
             2^{s-k^*}>|x|.
             $$
             Let $p=s-k^*$; compute a similar $q$ for $y$.

             So $|x|<2^p$ and $|y|<2^q$, and $p,q\geq -k^*\geq -k$.

             Let $m=q+k+2\geq 2$ and $n=p+k+2\geq 2$.

             Then
             $$
             2^m|x|<2^{m+p},
             $$
             so
             $$
             |x_m|\leq 2^{m+p};
             $$
             if we set $X_m=x_m/2^m$ then
             $$
             |X_m|\leq 2^p
             $$
             and
             $$
             |x-X_m|<2^{-m}.
             $$
             Similarly, $|Y_n|\leq 2^q$ and $|y-Y_m|< 2^{-n}$.

             Then
             $$
             |X_m Y_n - xy|
             =
             |X_m Y_n - x Y_n + x Y_n -xy|
             <=
             |Y_n| |X_m-x| +|x| |Y_n - y|
             <
             2^q / 2^m + 2^p / 2^n
             =
             2^{-k-2}+2^{-k-2}
             =
             2^{-k-1}.
             $$

             Thus
             $$
             |2^k X_m Y_n-2^k xy|< 1/2,
             $$
             or
             $$
             |\frac{x_m y_n}{2^{m+n-k}} -xy|<1/2.
             $$

             Since $\round(x_m y_n/2^{m+n-k})$ satisfies
             $$
             |\round(x_m y_n/2^{m+n-k})-(x_m y_n/2^{m+n-k})|\leq 1/2,
             $$
             so
             |\round(x_m y_n/2^{m+n-k})-xy|< 1.
             $$
             |#
             (let ((k^* (quotient (+ k 1) 2)))
               (let ((p (let ((s (two^p>abs_m (x k^*))))
                          (- s k^*)))
                     (q (let ((s (two^p>abs_m (y k^*))))
                          (- s k^*))))
                 (let ((m (+ k q 2))
                       (n (+ k p 2)))
                   (NDIV-2^p (* (x m)
                                (y n))
                             (+ m n (- k)))))))))))

(define (computable-* . xs)
  ;; computable-*2 handles computable-one and computable-zero
  ;; efficiently, but doesn't handle
  ;; (* x computable-minus-one y computable-minus-one)
  ;; efficiently, so we handle that here.
  (let* ((new-xs
          (remq computable-negative-one xs))
         (partial-result
          (fold computable-*2 computable-one new-xs)))
    (if (even? (- (length xs) (length new-xs)))
        partial-result
        (computable-negate partial-result))))

(define (computable-/ x . ys)
  (if (null? ys)
      (computable-inverse x)
      (computable-*2 x
                     (computable-inverse
                      (apply computable-* ys)))))

(define (computable-square x)
  (cond ((eq? x computable-zero)
         computable-zero)
        ((or (eq? x computable-one)
             (eq? x computable-negative-one))
         computable-one)
        (else
         (computable-memoize
           (lambda (k)
             ;; see proof for computable-*
             (let* ((k^* (quotient (+ k 1) 2))
                    (p (- (two^p>abs_m (abs (x k^*)))
                          k^*))
                    (m (+ k p 2)))
               (NDIV-2^p (square (x m))
                         (- (* 2 m) k))))))))

(define (computable-< x y #!optional (precision (*max-precision*)))
  ;; (positive? (computable-< x y)) means that you're sure that x < y
  ;; (negative? (computable-< x y)) means that you're sure that y < x
  ;; (zero? (computable-< x y)) means that you don't know, to precision bits
  (if (eq? x y)
      0
      (let ((y-x (computable-- y x)))
        (let loop ((p 0))
          (let ((y-x_p (y-x p)))
            (cond ((negative? y-x_p) -1)
                  ((positive? y-x_p) +1)
                  ((< precision p)    0)
                  (else
                   (loop (min (+ precision 1)
                              (+ (* 2 p) 1))))))))))

;;; Some utility functions

(define (negative-abs m)
  ;; m can be big, so we'll try to be nice here
  (if (<= m 0)
      m
      (- m)))

;;; It's not clear that these need to be absolutely the biggest
;;; or smallest p that satisfies these conditions, but we'll
;;; leave it for now.

(define (two^p>abs_m m)
  ;; returns smallest p
  (integer-length (abs m)))

(define (two^p>=abs_m m)
  ;; returns smallest p
  (integer-length (negative-abs m)))

(define (two^p<abs_m m)
  ;; returns largest p, assumes (abs m) > 1
  (- (integer-length (negative-abs m)) 1))

(define (two^p<=abs_m m)
  ;; returns largest p
  (- (integer-length (abs m)) 1))

;;; Two functions used a lot

(define (NDIV x p)

  ;; Returns an integer $y$ such that $|py-x|\leq p/2$.

  (balanced-quotient x p))

(define (NDIV-2^p x p)

  ;; Returns an integer $y$ such that $|2^py-x|\leq 2^{p-1}$.

  (let ((possible-answer (arithmetic-shift x (- p))))
    (if (and (> p 0)
             (bit-set? (- p 1) x))
        (+ possible-answer 1)
        possible-answer)))

;;; It's likely that the computable components of a leftmost term of
;;; a power series will need the most precision, which the later terms
;;; can then use, so we define a map with given application order.

(define (map-left-to-right f l)
  (if (null? l)
      l
      (let ((item (f (car l))))
        (cons item (map-left-to-right f (cdr l))))))

;;; We're going to need some bounds on factorials

(define two-pi (* 8 (atan 1)))

(define (m!2^ml>2^k l k)

  #|
  In power series for $\exp$, $\sin$, $\cos$, there are terms with absolute value
  $$
  \frac {|x|^m}{m!},
  $$
  which we're going to require to be $< 2^{-k}$ for a given $k$.  So
  we're going to assume some bound on $|x|<2^{-l}$ and estimate how
  large $m$ needs to be.

  If $|x|<2^{-l}$, $l\geq 0$, given $k$ we want to find $m$ such that
  $$
  \frac{|x|^m}{m!}<\frac 1 {2^k},
  $$
  or
  $$
  2^k<m!|x|^{-m},
  $$
  which will be true if
  $$
  2^k<m! 2^{ml}.
  $$
  So we'll use Stirling's formula
  $$
  m!\approx \sqrt{2\pi m}\frac{m^m}{e^m},
  $$
  so
  $$
  \log(2^{ml}m!)\approx ml\log 2+m\log m-m +\frac 12(\log(2\pi)+\log m),
  $$
  which we'll define as $F(m)$.  Then
  $$
  F'(m)=l\log2+\log m+1-1+\frac1/{2m}.
  $$
  We'll use Newton's method to find an approximate m,
  then do a linear search.
  |#

  (define (stirling n)
    (+ (* (+ n 1/2) (log n))
       (- n)
       (* 1/2 (log two-pi))))

  (define (F n)
    (- (+ (stirling n)
          (* n l (log 2)))
       (* k (log 2))))

  (define (F-prime n)
    (+ (* l (log 2))
       (log n)
       (/ (* 2 n))))

  (define (Newton-step F F-prime x_k)
    (- x_k (/ (F x_k) (F-prime x_k))))

  (define (Newton-solve F F-prime m_0 tolerance)
    (let newton-loop ((m_k m_0))
      (let ((m_k+1 (Newton-step F F-prime m_k)))
        (if (> (abs (- m_k+1 m_k)) tolerance)
            (newton-loop m_k+1)
            m_k+1))))
  (case k
    ;; for very small k we're going to
    ;; ignore l and return quickly
    ((0) 2)
    ((1) 3)
    (else
     (let* ((m (max (exact (round (Newton-solve F F-prime 3 #i1/16))) 2))
            (two^k (expt 2 k)))
       ;; We don't worry if $m$ is a bit too big, we just
       ;; need to ensure that it isn't too small.
       (let too-low?-loop ((m m))
         (let ((two^lmxm! (* (expt 2 (exact (floor (* l m))))
                             (partial-factorial 0 m))))
           (if (<= two^lmxm! two^k)
               (too-low?-loop (+ m 1))
               m)))))))

(define (partial-factorial m n)
  ;; computes the product (m+1) * ... * (n-1) * n
  (if (< (- n m) 5)
      (do ((m m (+ m 1))
           (product 1 (* product (+ m 1))))
          ((= m n) product))
      (* (partial-factorial m (quotient (+ m n) 2))
         (partial-factorial (quotient (+ m n) 2) n))))

(define (power-of-two? x)
  (= (integer-length x)
     (+ (first-set-bit x) 1)))

(define (display-binary x #!key (port #f))
  (let ((port (or (and port
                       (output-port? port)
                       port)
                  (current-output-port))))
    (and (or (exact? x)
             (error "binary-display: argument is not exact: " x))
         (or (power-of-two? (denominator x))
             (error "binary-display: argument is not a dyadic rational: " x))
         (let ((num (numerator x))
               (den (denominator x)))
           (let ((significant-bits (- (integer-length den) 1)))
             (display (list (number->string (quotient num den) 2)
                            "."
                            (let ((nonzero-bits (number->string (remainder num den) 2)))
                              (list (make-string (max 0 (- significant-bits (string-length nonzero-bits))) #\0)
                                    nonzero-bits)))
                      port))))))

;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;
(define computable-sqrt
  (table-memoize
    (lambda (x)

      (define (int-sqrt x_2n)
        ;; result is within 1/2 of \sqrt(x_2n), x_2n a nonnegative integer
        (call-with-values
            (lambda ()
              (##exact-int.sqrt x_2n))
          (lambda (y r)
            ;; y^2 <= (x_2n = y^2+r) < (y+1)^2
            ;; now either y^2 <= y^2 + r < (y+1/2)^2= y^2+y + 1/4 or y^2+y+1/4 < y^2+r < (y+1)^2
            ;; so either |y-\sqrt(x_2n)|< 1/2 or |(y+1)-\sqrt(x_2n)| < 1/2
            (if (<= r y)
                y
                (+ y 1)))))

      (if (or (eq? x computable-zero)
              (eq? x computable-one))
          x
          (let ((x_0 (x 0)))
            (cond
             ((negative? x_0)
              (error "computable-sqrt: argument is negative: " x))
             ((> x_0 1)
              (let ((s (two^p<abs_m x_0)))
                (computable-memoize
                  (lambda (k)
                    ;; x_0>2^s, so x> 2^s
                    (if (<= (* 2 k) s)
                        ;; |x_0 - x| < 1
                        ;; |2^{2k}x_0 - 2^{2k}x| < 2^{2k}
                        ;; |\sqrt{2^{2k}x_0}-2^k\sqrt{x}| < 2^{2k}/|\sqrt{2^{2k}x_0}+2^k\sqrt{x}|
                        ;;                                <= 2^{2k}/(2^k2^{s/2}+2^k2^{s/2})
                        ;;                                = 2^k/(2*2^{s/2})
                        ;;                                = 1/2
                        (int-sqrt (* (expt 2 (* 2 k))
                                     x_0))
                        ;; x_0 > 2^s, so x_n >= 2^{n+s}
                        ;; |x_n - 2^nx| < 1
                        ;; |2^{2k-n}x_n - 2^{2k}x| < 2^{2k-n}
                        ;; |\sqrt{2^{2k-n}x_n} - 2^k\sqrt{x}| < 2^{2k-n}/|2^{k-n/2}\sqrt{x_n}+2^k\sqrt{x}|
                        ;;                                    <=2^{2k-n}/|2^{k-n/2+(s+n)/2} + 2^{k+s/2}|
                        ;;                                    <=2^{2k-n}/|2\times2^{k+s/2}|
                        ;;                                    <= 2^{2k - n - k - s/2}/2
                        ;;                                    <= 1/2
                        ;; if   k - n - s/2 <= 0, i.e., n >= k - s/2
                        (let ((n (- k (quotient s 2))))
                          (int-sqrt (* (expt 2 (- (* 2 k) n))
                                       (x n)))))))))
             (else
              (computable-memoize
                (lambda (k)
                  ;; let's say that x_k>2^s, so 2^k x>2^s or x>2^{s-k} or \sqrt{x}>2^{(s-k)/2}
                  ;; so if n >= k, we have 2^n x > 2^{s+n-k}, so x_n >= 2^{s+n-k} or \sqrt(x_n)>= 2^{(s+n-k)/2}
                  ;; |x_n - 2^nx| < 1
                  ;; |2^{2k-n}x_n - 2^{2k}x| < 2^{2k-n}
                  ;; |\sqrt{2^{2k-n}x_n} - 2^k\sqrt{x}| < 2^{2k-n}/|2^{k-n/2}\sqrt{x_n}+2^k\sqrt{x}|
                  ;;                                    <=2^{2k-n}/|2^{k-n/2+(s+n-k)/2} + 2^{(s+k)/2}|
                  ;;                                    <=2^{2k-n}/|2\times2^{(k+s)/2}|
                  ;;                                    <= 2^{2k - n - k/2 - s/2}/2
                  ;;                                    <= 1/2
                  ;; if   3/2 k - n - s/2 <= 0, i.e., n >= 3/2 k - s/2 = k + (k-s)/2
                  (let ((x_k (x k)))
                    (cond ((negative? x_k)
                           (error "computable-sqrt: argument is negative: " x))
                          ((< 1 x_k)
                           (let ((s (two^p<abs_m x_k)))
                             (let ((n (quotient (- (* 3 k) s) 2)))
                               (int-sqrt (* (expt 2 (- (* 2 k) n))
                                            (x n))))))
                          (else
                           ;; let's punt --- it would be nice to be able to find out whether
                           ;; some x has x_k > 2^s for any pair k, s without actually having to
                           ;; guess a k for which such an s exists.
                           (let ((x_2k (x (* 2 k))))
                             (if (negative? x_2k)
                                 (error "computable-sqrt: argument is negative: " x)
                                 ;; If x_2k=0 then |2^{2k}x|<1 so |2^k\sqrt x|<1 so return 0

                                 ;; If x_2k=1 then x>0 so
                                 ;; |1-2^{2k}x|<1 so |1-2^k\sqrt x|<1/|1+2^k\sqrt x|<1 so return 1

                                 ;; If x_2k>1 then 2^{2k}x>1 and 2^k\sqrt{x}>1 and
                                 ;; |x_2k-2^{2k}x|<1
                                 ;; so
                                 ;; |\sqrt{x_2k}-2^k\sqrt x|<1/|\sqrt{x_2k}+2^k\sqrt x|<1/2
                                 ;; and |\sqrt {x_2k}-int-sqrt(x_2k)|<1/2, so
                                 ;; |int-sqrt(x_2k)-2^k\sqrt x|<1
                                 (int-sqrt x_2k)))))))))))))))

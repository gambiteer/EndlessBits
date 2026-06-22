;; You *must* load a compiled version of nextafter.scm for this to work.

#|

When running tests, setting *testing* to #t in basics.scm disables any
caching of results, to require that a cached result at a higher precision
is not used to quickly (and accurately!) compute a result at a lower
precision.

When asked to compute a result to k bits precision, if a cached result of
at least k bits precision is not available, a new result of k* bits is
computed.  When *testing* is #f (the usual case) k*=k+(integer-length k),
because algorithms, after requiring an intermediate result to k bits,
often find they require the same result to k+2 bits precision, say,
and if k*>=k+2, those bits are available.  When testing is #t, then
k*=k, so all results are computed to precisely the precision required.


Setting *testing* to #t doesn't test the code that (a) uses a cached
numerical result at a higher precision to return an accurate result at a
lower precision and (b) takes the partial sum of a Maclaurin series with
M terms and adds only the next N-M terms to compute a partial sum with
N>M terms.

Setting *strict-testing* to #f restores caching, but I'm not yet sure if it
tests the Maclaurin series extension.

The tests are organized as follows:

1.  There are a set of arguments to which each test is applied.  For each
procedure these arguments should be chosen to at least to test every
branch in each algorithm.

2.  The result of the computable function is compared to the result of
the corresponding library procedure.

2 (a).  In the usual case, *loose-comparison* is true, and the computable
result is compared to the library procedure result, and to the flonums above
and below it.  This is the usual case, where this test is used coarsely to
see that the computable result is reasonably correct.

2 (b).  Otherwise, we set *loose-comparison* to #f, and the computable
result is compared only to the library procedure result, and any
anomalies are reported.  Using the test package in this way tests
the accuracy of the *library* routines, because see 3.

3.  After passing 2, the coarse comparison test, we compute the
computable result to a "large" number of bits and then check
that the results of computing the result to a sequence of a smaller
number of bits are consistent with the higher-precion result.  This
tests the internal consistency of the results, adding confidence that
the results computed in 2(a) are correct.

4.  Test (op (inverse-op arg)) = arg to double precision for extreme
values: half the smallest positive fixnum, halfway between 1, and
(nextafter 1. 0.); and halfway between the largest positive finite double
and the next-lower double.

|#

(*warn* #f) ;; warn when making arbitrary decisions in computable->inexact

(define *loose-comparison* #t) ;; requires to define and load nextafter

(pp "**************************")
(pp (list "*loose-comparison* is " *loose-comparison*))
(pp (list "*strict-testing* is" *strict-testing*))
(pp (list "*warn* is " (*warn*)))
(pp "**************************")

(define (test-one-arg-procedure computable-procedure
                                library-procedure
                                procedure-name
                                arguments)
  (pp (list Testing: procedure-name))

  (for-each (lambda (argument)
              ;;(display argument) (display #\space)
              (let ((computable-argument (->computable argument)))

                ;; First test that the result matches the library
                ;; (which it will not always do, because the library
                ;; is not always right

                (let* ((computable-result
                       (computable-procedure computable-argument))
                      (inexact-computable-result
                       (computable->inexact computable-result))
                      (computable-inexact-computable-result
                       (->computable inexact-computable-result))
                      (library-result
                       (library-procedure argument)))
                  (if (not (or (= inexact-computable-result library-result)
                               (and *loose-comparison*
                                    (if (positive? (computable-< computable-result
                                                                 computable-inexact-computable-result))
                                        (= library-result (nextafter inexact-computable-result -inf.0))
                                        (= library-result (nextafter inexact-computable-result +inf.0))))))
                      (pp (list
                           compare-computable-to-library-anomaly:
                           procedure: procedure-name
                           argument: argument
                           computable-result: inexact-computable-result
                           library-result: library-result))))

                ;; Next, we'll test the accuracy of results for
                ;; various precisions

                (call-with-values
                    (lambda ()
                      (if *strict-testing*
                          (values 100  '(0 10 50))
                          (values 1000 '(0 10 50 500))))
                  (lambda (max-precision precisions)
                    (let* ((computable-result (computable-procedure computable-argument))
                           (result_max (computable-result max-precision)))
                      (for-each
                       (lambda (p)
                         ;; For each precision, we compute the result,
                         ;; then shift it to compare to the result at the
                         ;; highest precision.
                         (let* ((x_p (computable-result p))
                                (precision-shift (- max-precision p))
                                (x_p-max (arithmetic-shift x_p precision-shift)))
                           (if (not (cond ((= x_p-max result_max))
                                          ((< x_p-max result_max)
                                           (< result_max
                                              (arithmetic-shift (+ x_p 1) precision-shift)))
                                          (else
                                           ;; (< result_max x_p-max)
                                           (< (arithmetic-shift (- x_p 1) precision-shift)
                                              result_max))))
                               (pp (list
                                    compare-low-to-high-precision:
                                    precision: p
                                    max-precision: max-precision
                                    procedure: procedure-name
                                    argument: argument)))))
                       precisions))))))
            arguments)
  (newline))

(test-one-arg-procedure computable-asin asin 'asin (map (lambda (n) (/ n 10.)) (iota 21 -10)))
(test-one-arg-procedure computable-acos acos 'acos (map (lambda (n) (/ n 10.)) (iota 20 -10)))
(test-one-arg-procedure computable-atan atan 'atan (map (lambda (n) (/ n 10.)) (iota 1001 -500)))

(test-one-arg-procedure computable-exp exp 'exp (map (lambda (n) (/ n 10.)) (iota 101 -50)))
(test-one-arg-procedure computable-log log 'log (map (lambda (n) (/ n 10.)) (iota 101   1)))

(test-one-arg-procedure computable-sinh sinh 'sinh (map (lambda (n) (/ n 10.)) (iota 1001 -500)))
(test-one-arg-procedure computable-cosh cosh 'cosh (map (lambda (n) (/ n 10.)) (iota 1001 -500)))
(test-one-arg-procedure computable-tanh tanh 'tanh (map (lambda (n) (/ n 10.)) (iota 1001 -500)))

(test-one-arg-procedure computable-asinh asinh 'asinh (map (lambda (n) (/ n 10.)) (iota 1001 -500)))
(test-one-arg-procedure computable-acosh acosh 'acosh (map (lambda (n) (/ n 10.)) (iota 1001 10)))
(test-one-arg-procedure computable-atanh atanh 'atanh (map (lambda (n) (/ n 1000.)) (iota  1999 -999)))

(test-one-arg-procedure computable-sin sin 'sin (map (lambda (n) (/ n 1.)) (iota 21 -10)))
(test-one-arg-procedure computable-cos cos 'cos (map (lambda (n) (/ n 1.)) (iota 21 -10)))
(test-one-arg-procedure computable-tan tan 'tan (map (lambda (n) (/ n 1.)) (iota 21 -10)))

(test-one-arg-procedure computable-sqrt sqrt 'sqrt (map (lambda (n) (/ n 10.)) (iota 101  0)))

(define exact-large-numbers
  (list (* (expt 2 1023) (- 2 (* 3/2 (expt 2 -52))))
        (* (expt 2 1023) (- 2 (* 5/2 (expt 2 -52))))
        (* (expt 2 1023) (- 2 (* 7/2 (expt 2 -52))))
        (* (expt 2 1023) (- 2 (* 9/2 (expt 2 -52))))))

(define large-numbers
  (map ->computable exact-large-numbers))

(define inexact-large-numbers
  (map inexact exact-large-numbers))

(define exact-small-numbers
  (list (* 1/2 (expt 2 -1074))
        (* 3/2 (expt 2 -1074))
        (* 5/2 (expt 2 -1074))
        (* 7/2 (expt 2 -1074))))

(define small-numbers
  (map ->computable exact-small-numbers))

(define inexact-small-numbers
  (map inexact exact-small-numbers))

(define exact-almost-one
  (/ (+ 1 (exact (nextafter 1. 0.))) 2))

(define almost-one
  (->computable exact-almost-one))

(define inexact-almost-one
  (inexact exact-almost-one))


(if (not *strict-testing*)
    (begin
      ;; they take impossibly long with *strict-testing*
      (let ((procs   ;; (list-ref proc k) is the inverse of (list-ref (reverse proc) k)
             (list computable-square
                   computable-sin
                   computable-cos
                   computable-tan
                   computable-exp
                   computable-tanh
                   computable-sinh
                   ;; computable-cosh    ;; can't take acosh of small or almost-one
                   ;; computable-acosh
                   computable-asinh
                   computable-atanh
                   computable-log
                   computable-atan
                   computable-acos
                   computable-asin
                   computable-sqrt))
            (names
             '(computable-square
               computable-sin
               computable-cos
               computable-tan
               computable-exp
               computable-tanh
               computable-sinh
               ;; computable-cosh
               ;; computable-acosh
               computable-asinh
               computable-atanh
               computable-log
               computable-atan
               computable-acos
               computable-asin
               computable-sqrt))
            (no-big-arg-procs
             (list computable-asin
                   computable-acos
                   computable-atan
                   computable-exp     ;; we can't take the exp, sinh, or cosh of the largest positive number
                   computable-tanh
                   computable-sinh
                   computable-cosh)))

        (for-each (lambda (name proc inverse-proc)

                    (define (test arg inexact-arg)
                      (if (not (= (computable->inexact (proc (inverse-proc arg)))
                                  (computable->inexact (inverse-proc (proc arg)))
                                  inexact-arg))
                          (pp (list arg: inexact-arg
                                    proc-inverse: (computable->inexact (proc (inverse-proc arg)))
                                    inverse-proc: (computable->inexact (inverse-proc (proc arg)))))))
                    (newline)
                    (pp name)

                    (pp small:)
                    (for-each test small-numbers inexact-small-numbers)

                    (pp almost-one:)
                    (test almost-one inexact-almost-one)

                    (if (not (or (memq proc no-big-arg-procs)
                                 (memq inverse-proc no-big-arg-procs)))
                        (begin
                          (pp large:)
                          (for-each test large-numbers inexact-large-numbers))))
                  names
                  (take procs           (quotient (length procs) 2))
                  (take (reverse procs) (quotient (length procs) 2))))

      (newline)
      (pp "testing exp, cosh, and sinh on small arguments")

      (for-each (lambda (name proc inverse-proc)

                  (define (test arg inexact-arg)
                    (let ((computable-result
                           (computable->inexact (inverse-proc (proc arg)))))
                      (if (not (= computable-result inexact-arg))
                          (pp (list arg: inexact-arg
                                    should-be-arg: inexact-arg)))))

                  (newline) (pp name)
                  (pp almost-one:)
                  (test almost-one inexact-almost-one)
                  (pp small-numbers:)
                  (for-each test small-numbers inexact-small-numbers))
                '(exp cosh sinh)
                (list computable-exp computable-cosh computable-sinh)
                (list computable-log computable-acosh computable-asinh))

      (newline)
      (pp "testing log, acosh, and asinh on large argument")

      (for-each (lambda (name proc inverse-proc)
                  (newline) (pp name)
                  (for-each (lambda (arg inexact-arg)
                              (let ((computable-result
                                     (computable->inexact (inverse-proc (proc arg)))))
                                (if (not (= computable-result inexact-arg))
                                    (pp (list arg: inexact-arg
                                              should-be-arg: computable-result)))))
                            large-numbers
                            inexact-large-numbers))
                '(log acosh asinh)
                (list computable-log computable-acosh computable-asinh)
                (list computable-exp computable-cosh computable-sinh))))

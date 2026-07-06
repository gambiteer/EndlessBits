;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;
(include "exact-reals.scm")

(*warn* #f)

(define-type CR
  copier: #f
  no-functional-setter:
  (proc read-only:))

(define check-args
  (let ((arg-indices
         (list->vector
          (map (lambda (n)
                 (iota n 1))
               (iota 11)))))

    (define (index-args len)
      (if (<= len 10)
          (vector-ref arg-indices len)
          (iota len 1)))

    (lambda (name
             args
             #!optional
             (arg-ok? (lambda (arg index) #t))) ;; a check on numbers beyond real? and finite?
      (map (lambda (arg index)
             #; (if (real? arg) (pp (arg-ok? arg index)))
             (cond ((CR? arg)
                    (CR-proc arg))
                   ((and (real? arg)
                         (finite? arg)
                         (arg-ok? arg index))
                    (if (and (not (= arg
                                     (string->number
                                      (string-append
                                       "#e"
                                       (number->string arg)))))
                             (*warn*))
                        (let ((number-representation
                               (number->string arg)))
                          (display (string-append
                                    (symbol->string name)
                                    ": Converting inexact argument "
                                    (number->string index)
                                    ", written as "
                                    number-representation
                                    ", to a computable real number "
                                    "with value "
                                    (number->string (exact arg))
                                    ".")
                                   (current-error-port))
                          (newline (current-error-port))
                          (display (string-append
                                    "If you really meant the argument to have the exact value "
                                    number-representation
                                    ", write it as \"#e"
                                    number-representation
                                    "\".")
                                   (current-error-port))
                          (newline (current-error-port))))
                    (->computable arg))
                   (else
                    (raise index))))
           args
           (index-args (length args))))))

(define (CR->string x #!optional (digits 100))
  (let* ((args (check-args 'CR->string (list x)))
         (x (car args))
         (x_p (compute-decimal-digits x digits))
         (abs-x_p (abs x_p))
         (digit-string (number->string abs-x_p))
         (digit-string-length (string-length digit-string))
         (abs-digit-string
          (if (<= digit-string-length digits)
              (string-append "0."
                             (make-string (- digits digit-string-length) #\0)
                             digit-string)
              (string-append (substring digit-string 0 (- digit-string-length digits))
                             "."
                             (substring digit-string (- digit-string-length digits) digit-string-length)))))
    (string-append (if (negative? x_p) "#e-" "#e")
                   abs-digit-string)))

(define (CR->inexact x)
  (let ((args (check-args 'CR->inexact (list x))))
    (computable->inexact (car args))))

(define Pi (make-CR computable-pi))
(define E  (make-CR computable-e))

(define-macro (setup-zero-or-more-arg-procedures)

  (define (cat-symbols . args)
    (string->symbol
     (apply string-append (map (lambda (x)
                                 (cond ((symbol? x)
                                        (symbol->string x))
                                       ((string? x)
                                        x)
                                       ((number? x)
                                        (number->string x))))
                               args))))

  (let ((result
         `(begin
            ,@(map (lambda (name)
                     `(define (,(cat-symbols 'CR name) . args)
                        (let ((new-args
                               (with-exception-catcher
                                (lambda (index)
                                  (apply ##raise-range-exception index ,(cat-symbols 'CR name) args))
                                (lambda ()(check-args ',(cat-symbols 'CR name) args)))))
                          (make-CR (apply ,(cat-symbols 'computable- name) new-args)))))
                   '(+
                     ;; -
                     *
                     ;; /
                     ;; max
                     ;; min
                     ;; expt
                     )))))
    ;; (pp result)
    result))

(setup-zero-or-more-arg-procedures)

(define-macro (setup-one-or-more-arg-procedures)

  (define (cat-symbols . args)
    (string->symbol
     (apply string-append (map (lambda (x)
                                 (cond ((symbol? x)
                                        (symbol->string x))
                                       ((string? x)
                                        x)
                                       ((number? x)
                                        (number->string x))))
                               args))))

  (let ((result
         `(begin
            ,@(map (lambda (name)
                     `(define (,(cat-symbols 'CR name) arg1 . args)
                        (with-exception-catcher
                         (lambda (index)
                           (apply ##raise-range-exception index ,(cat-symbols 'CR name) arg1 args))
                         (lambda ()
                           (let ((new-args (check-args ',(cat-symbols 'CR name) (cons arg1 args))))
                             (make-CR (apply ,(cat-symbols 'computable- name) new-args)))))))
                   '(;; +
                     -
                     ;; *
                     ;; /
                     max
                     min
                     ;; expt
                     )))))
    ;; (pp result)
    result))

(setup-one-or-more-arg-procedures)



(define (CRexpt x y)
  (let ((args
         (with-exception-catcher
          (lambda (index)
            (##raise-range-exception index CRexpt x y))
          (lambda ()
            (check-args 'CRexpt
                        (list x y)
                        (lambda (arg index)
                          (not (and (= index 1)
                                    (<= arg 0)))))))))
    (make-CR
     (with-exception-catcher
      (lambda (err)
        (##raise-range-exception 1 CRexpt x y))
      (lambda ()
        (apply computable-pow args))))))

(define (CR/ arg1 . args)
  (let ((args
         (with-exception-catcher
          (lambda (index)
            (apply ##raise-range-exception index CR/ arg1 args))
          (lambda ()
            (check-args 'CR/
                        (cons arg1 args)
                        (lambda (arg index)
                          (if (null? args)
                              (not (zero? arg))
                              (not (and (< 1 index)
                                        (zero? arg))))))))))
    (make-CR (apply computable-/ args))))


#;
(define (CR+ . args)
  (let ((args (check-args 'CR+ args)))
    (make-CR (apply computable-+ args))))
#;
(define (CR- arg1 . args)
  (let ((args (check-args 'CR- (cons arg1 args))))
    (make-CR (apply computable-- args))))
#;
(define (CR* . args)
  (let ((args (check-args 'CR* args)))
    (make-CR (apply computable-* args))))

#;
(define (CR/ arg1 . args)
  (let ((args (check-args 'CR/ (cons arg1 args))))
    (make-CR (apply computable-/ args))))
#;
(define (CRmax arg . args)
  (let ((args (check-args 'CRmax (cons arg args))))
    (make-CR (apply computable-max args))))
#;
(define (CRmin arg . args)
  (let ((args (check-args 'CRmin (cons arg args))))
    (make-CR (apply computable-min args))))


(define-macro (setup-single-arg-functions-no-trapping)

  (define (cat-symbols . args)
    (string->symbol
     (apply string-append (map (lambda (x)
                                 (cond ((symbol? x)
                                        (symbol->string x))
                                       ((string? x)
                                        x)
                                       ((number? x)
                                        (number->string x))))
                               args))))

  (let ((result
         `(begin
            ,@(map (lambda (name)
                     `(define (,(cat-symbols 'CR name) x)
                        (with-exception-catcher
                         (lambda (index)
                           (##raise-range-exception index ,(cat-symbols 'CR name) x))
                         (lambda ()
                           (let ((args (check-args ',(cat-symbols 'CR name) (list x))))
                             (make-CR (,(cat-symbols 'computable- name) (car args))))))))
                   '(square
                     ;; sqrt
                     abs

                     ;; log
                     exp

                     sin
                     cos
                     ;; tan

                     ;; asin
                     ;; acos
                     atan

                     sinh
                     cosh
                     tanh

                     asinh
                     ;; acosh
                     ;; atanh
                     )))))
    ;; (pp result)
    result))

(setup-single-arg-functions-no-trapping)

(define-macro (setup-single-arg-functions-trapping)

  (define (cat-symbols . args)
    (string->symbol
     (apply string-append (map (lambda (x)
                                 (cond ((symbol? x)
                                        (symbol->string x))
                                       ((string? x)
                                        x)
                                       ((number? x)
                                        (number->string x))))
                               args))))

  (let ((result
         `(begin
            ,@(map (lambda (name)
                     `(define (,(cat-symbols 'CR name) x)
                          (with-exception-catcher
                           (lambda (index)
                             (##raise-range-exception 1 ,(cat-symbols 'CR name) x))
                           (lambda ()
                             (let ((args (check-args ',(cat-symbols 'CR name) (list x))))
                               (make-CR (,(cat-symbols 'computable- name) (car args))))))))
                   '(;; square
                     sqrt
                     ;; abs

                     log
                     ;; exp

                     ;; sin
                     ;; cos
                     tan

                     asin
                     acos
                     ;; atan

                     ;; sinh
                     ;; cosh
                     ;; tanh

                     ;; asinh
                     acosh
                     atanh
                     )))))
    #;
    (pp result)
    result))

#;
(setup-single-arg-functions-trapping)


(begin
  (define (CRsqrt x)
    (with-exception-catcher
     (lambda (index) (##raise-range-exception 1 CRsqrt x))
     (lambda ()
       (let ((args (check-args 'CRsqrt (list x) (lambda (x index) (<= 0 x)))))
         (make-CR (computable-sqrt (car args)))))))
  (define (CRlog x)
    (with-exception-catcher
     (lambda (index) (##raise-range-exception 1 CRlog x))
     (lambda ()
       (let ((args (check-args 'CRlog (list x) (lambda (arg index) (positive? arg)))))
         (make-CR (computable-log (car args)))))))
  (define (CRtan x)
    (with-exception-catcher
     (lambda (index) (##raise-range-exception 1 CRtan x))
     (lambda ()
       (let ((args (check-args 'CRtan (list x))))
         (make-CR (computable-tan (car args)))))))
  (define (CRasin x)
    (with-exception-catcher
     (lambda (index) (##raise-range-exception 1 CRasin x))
     (lambda ()
       (let ((args (check-args 'CRasin (list x) (lambda (x index) (<= (abs x) 1)))))
         (make-CR (computable-asin (car args)))))))
  (define (CRacos x)
    (with-exception-catcher
     (lambda (index) (##raise-range-exception 1 CRacos x))
     (lambda ()
       (let ((args (check-args 'CRacos (list x) (lambda (x index) (<= (abs x) 1)))))
         (make-CR (computable-acos (car args)))))))
  (define (CRacosh x)
    (with-exception-catcher
     (lambda (index) (##raise-range-exception 1 CRacosh x))
     (lambda ()
       (let ((args (check-args 'CRacosh (list x) (lambda (x index) (<= 1 x)))))
         (make-CR (computable-acosh (car args)))))))
  (define (CRatanh x)
    (with-exception-catcher
     (lambda (index) (##raise-range-exception 1 CRatanh x))
     (lambda ()
       (let ((args (check-args 'CRatanh (list x) (lambda (x index) (< (abs x) 1)))))
         (make-CR (computable-atanh (car args))))))))

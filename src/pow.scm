;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;
(define (computable-pow x y)
  ;; The naive definition seems perfectly usable
  (computable-exp
   (computable-* (computable-log x) y)))

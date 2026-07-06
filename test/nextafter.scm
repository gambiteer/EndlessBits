;;; SPDX-FileCopyrightText: 2026 Braadley J Lucier
;;; SPDX-License-Identifier: MIT
;;;
(define nextafter
    (c-lambda (double double) double "nextafter"))

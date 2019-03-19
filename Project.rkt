; amb macros from 'Teach Yourself Scheme in Fixnum Days', by Dorai Sitaram
; available from the plt-scheme helpdesk

;;;; use the language Pretty Big -- r5rs will not permit 'require'

;;; Created by Andrew Truett and Vagan Grigoryan
;;; Spring 2018
;;; CSC 335

(require compatibility/defmacro)

(define (driver action exp) ;;;;;;;;;;;;;;;;;; D R I V E R

  ;; Helper Functions
  (define amb-fail '*)

  (define initialize-amb-fail
    (lambda ()
      (set! amb-fail
            (lambda ()
              symbol-null-result))))

  (initialize-amb-fail)

  (define-macro amb
    (lambda alts...
      `(let ((+prev-amb-fail amb-fail))
         (call/cc
          (lambda (+sk)
            ,@(map (lambda (alt)
                     `(call/cc
                       (lambda (+fk)
                         (set! amb-fail
                               (lambda ()
                                 (set! amb-fail +prev-amb-fail)
                                 (+fk 'fail)))
                         (+sk ,alt))))
                   alts...)
            (+prev-amb-fail))))))
  
  (define assert
    (lambda (pred)
      (if (not pred) (amb))))

  
  
  (define-macro bag-of
    (lambda (e)
      `(let ((+prev-amb-fail amb-fail)
             (+results '()))
         (if (call/cc
              (lambda (+k)
                (set! amb-fail (lambda () (+k #f)))
                (let ((+v ,e))
                  (set! +results (cons +v +results))
                  (+k #t))))
             (amb-fail))
         (set! amb-fail +prev-amb-fail)
         (reverse! +results))))
  


  ; Our original idea was to create a satisfiable? function that chained asserts together, but we have realized that is not what we want.
  ; The issue with chaining asserts together can be shown using an expression such as (NOT (NOT a)). This expression is clearly satisfiable (a is true). But if we
  ; chain asserts, it would look like this (assert (not (assert (not a))) which is clearly a contradiction. We are asserting that an assert must be false, which is guarenteed to fail.

  ; The correct thing we need to assert is (using the same expression) (assert (not (not a))). Here we are saying we don't care what needs to be true within the arguments of the expression,
  ; the only thing that needs to be true is the expression itself.

  (define symbol-null-result 'NO_RESULT)
  (define symbol-and 'AND)
  (define symbol-or 'OR)
  (define symbol-not 'NOT)
  (define symbol-xor 'XOR)
  (define symbol-if '->)
  (define symbol-nand 'NAND)

  
  (define (get-value) (amb #t #f))
  
  (define var?
    (lambda(x) (and (not (pair? x)) (not (null? x)))))

  (define (make-and l1 l2) (list l1 symbol-and l2))
  (define (make-or l1 l2) (list l1 symbol-or l2))
  (define (make-not l1) (list symbol-not l1))
  (define (make-xor l1 l2) (list l1 symbol-xor l1))
  (define (make-if l1 l2) (list l1 symbol-if l1))
  (define (make-nand l1 l2) (list l1 symbol-nand l1))





  (define (first-arg exp) (car exp))
  (define (operator exp) (car (cdr exp)))
  (define (second-arg exp) (car (cdr (cdr exp))))
  (define not-arg operator)


  (define (and-exp? exp) (eq? symbol-and (operator exp)))
  (define (or-exp? exp) (eq? symbol-or (operator exp)))
  (define (not-exp? exp) (eq? symbol-not (first-arg exp)))
  (define (xor-exp? exp) (eq? symbol-xor (operator exp)))
  (define (if-exp? exp) (eq? symbol-if (operator exp)))
  (define (nand-exp? exp) (eq? symbol-nand (operator exp)))

  ; Returns alist
  (define (assign-vals vars)
    (cond ((null? vars) '())
          (else (cons (list (car vars) (get-value)) (assign-vals (cdr vars))))))


  (define (lookup target alist)
    (cond ((eq? (caar alist) target) (cadar alist))
          (else (lookup target (cdr alist)))))

  (define (collect-elements exp)
    (define (flatten exp)
      (cond ((null? exp) '())
            ((pair? exp) (append (flatten (car exp)) (flatten (cdr exp))))
            (else (list exp))))
    
    (define (filter-duplicates lat list-so-far)
      (cond ((null? lat) list-so-far)
            ((not (member~ (car lat) list-so-far)) (filter-duplicates (cdr lat) (append list-so-far (list (car lat)))))
            (else (filter-duplicates (cdr lat) list-so-far))))
    
    (define (operator? a)
      (and
       (not (eq? symbol-and a))
       (not (eq? symbol-or a))
       (not (eq? symbol-not a))
       (not (eq? symbol-xor a))
       (not (eq? symbol-if a))
       (not (eq? symbol-nand a))))
    
    (define (filter-operators lat)
      (filter operator? lat))
    
    (filter-operators (filter-duplicates (flatten exp) '())))
  
  (define (evaluate exp al)
    (cond ((var? exp) (lookup exp al))
          ((or-exp? exp) (or (evaluate (first-arg exp) al) (evaluate (second-arg exp) al)))
          ((xor-exp? exp) (and (or (evaluate (first-arg exp) al) (evaluate (second-arg exp) al))
                               (not (and (evaluate (first-arg exp) al) (evaluate (second-arg exp) al)))))
          ((and-exp? exp) (and (evaluate (first-arg exp) al) (evaluate (second-arg exp) al)))
          ((if-exp? exp) (or (not (evaluate (first-arg exp) al)) (evaluate (second-arg exp) al)))
          ((nand-exp? exp) (not (and (evaluate (first-arg exp) al) (evaluate (second-arg exp) al))))
          ((not-exp? exp) (not (evaluate (not-arg exp) al)))))
  
  (define (get-solution exp)
    (let ((vars (collect-elements exp)))
      (let ((al (assign-vals vars)))
        (cond ((var? exp) (list(list exp #t))))
        (assert (evaluate exp al))
        (cond ((eq? symbol-null-result (lookup (car vars) al)) '())
              (else al)))))

  (define (member~ e s)
    (cond ((null? s) #f)
          ((equal? e (car s)) #t)
          (else (member~ e (cdr s)))))

  (define (distinct~ items)
    (cond ((null? items) #t)
          ((null? (cdr items)) #t)
          ((member~ (car items) (cdr items)) #f)
          (else (distinct~ (cdr items)))))

  ;; MAIN PROCEDURES
  (define (satisfiable? exp)
    (let ((vars (collect-elements exp)))
      (let ((al (assign-vals vars)))
        (cond ((var? exp) #t))
        (assert (evaluate exp al))
        (not (eq? 'NO_RESULT (lookup (car vars) al))))))

  (define (list-solutions exp)
    (define solutions-length (expt 2 (length (collect-elements exp))))
    (define no-solution 'NO_RESULT)
    (define solutions (make-vector solutions-length no-solution))
    
    (define (solution-already-exists? sol)
      (define (iter i)
        (cond ((equal? (vector-ref solutions i) sol) #t)
              ((= i (- solutions-length 1)) #f)
              (else (iter (+ i 1)))))
      (iter 0))
    
    (define (add-solution sol)
      (define (iter i)
        (cond ((= i (- solutions-length 1)) (display "Big error.") (newline))
              ((equal? (vector-ref solutions i) no-solution) (vector-set! solutions i sol))
              (else (iter (+ i 1)))))
      (iter 0))
    
    (define (main-loop new-sol)
      (let ((new-sol (get-solution exp)))
        (cond ((null? new-sol) (result))
              ((solution-already-exists? new-sol)
               (assert (not (solution-already-exists? new-sol)))
               (main-loop new-sol))
              (else
               (add-solution new-sol)
               (main-loop new-sol)))))
    
    (define (result)
      (define (iter i list-so-far)
        (cond ((= i (- solutions-length 1)) (display "Solutions for: ") (display exp) (newline) list-so-far)
              ((not (equal? (vector-ref solutions i) symbol-null-result)) (iter (+ i 1) (append list-so-far (list (vector-ref solutions i)))))
              (else (iter (+ i 1) list-so-far))))
      (iter 0 '()))
    
      (main-loop (get-solution exp)))

  (cond ((equal? action 'list-solutions) (list-solutions exp))
        ((equal? action 'satisfiable?) (satisfiable? exp))
        (else (display "Select either 'satisfiable?' or 'list-solutions' as your desired action.") (newline)))
  )

;(driver 'satisfiable? '(a OR b))
;(driver 'list-solutions '(a OR b))

;(newline)

;(driver 'satisfiable? '(a AND (NOT a)))
(driver 'list-solutions '(a AND (NOT a)))

(driver 'list-solutions '(a NAND b))

(driver 'list-solutions '((b -> c) OR a))

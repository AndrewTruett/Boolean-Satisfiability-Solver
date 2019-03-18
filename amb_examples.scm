


; amb macros from 'Teach Yourself Scheme in Fixnum Days', by Dorai Sitaram
; available from the plt-scheme helpdesk


(require compatibility/defmacro)

(define amb-fail '*)

(define initialize-amb-fail
  (lambda ()
    (set! amb-fail
          (lambda ()
            (error "amb tree exhausted")))))


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


(define (an-element-of items)
  (assert (not (null? items)))
  (amb (car items) (an-element-of (cdr items))))


(define number-between
  (lambda (lo hi)
    (let loop ((i lo))
      (if (> i hi) (amb)
          (amb i (loop (+ i 1)))))))


; example

(define (a-pythagorean-triple-between low high)
  (let ((i (number-between low high)))
    (let ((j (number-between i high)))
      (let ((k (number-between j high)))
        (assert (= (+ (* i i) (* j j)) (* k k)))
        (list i j k)))))



; support code for puzzle, presented below

(define (member? e s)
  (cond ((null? s) #f)
        ((eq? e (car s)) #t)
        (else (member? e (cdr s)))))

(define (distinct? items)
  (cond ((null? items) #t)
        ((null? (cdr items)) #t)
        ((member? (car items) (cdr items)) #f)
        (else (distinct? (cdr items)))))


; puzzle from Abelson and Sussman

; Baker, Cooper, Fletcher, Miller and Smith live on different floors
; of an apartment house that contains only five floors.  Baker does 
; not live on the top floor.  Cooper does not live on the bottom floor.
; Fletcher does not live on either the top or the bottom floor.  Miller
; lives on a higher floor than does Cooper.  Smith does not live on a
; floor adjacent to Fletcher's.  Fletcher does not live on a floor adja-
; cent to Cooper's.  Where does everyone live?



(define (multiple-dwelling)
  (let ((baker (an-element-of '(1 2 3 4 5)))
        (cooper (an-element-of '(1 2 3 4 5)))
        (fletcher (an-element-of '(1 2 3 4 5)))
        (miller (an-element-of '(1 2 3 4 5)))
        (smith (an-element-of '(1 2 3 4 5))))
    (assert 
     (distinct? (list baker cooper fletcher miller smith)))
    (assert (not (= baker 5)))
    (assert (not (= cooper 1)))
    (assert (not (= fletcher 5)))
    (assert (not (= fletcher 1)))
    (assert (> miller cooper))
    (assert (not (= (abs (- smith fletcher)) 1)))
    (assert (not (= (abs (- fletcher cooper)) 1)))
    (list (list 'baker baker)
          (list 'cooper cooper)
          (list 'fletcher fletcher)
          (list 'miller miller)
          (list 'smith smith))))




(define (test1)
  (let ((a (amb 1 2 3))
        (b (amb 1 2 3))
        (c (amb 1 2 3)))
    (assert
     (distinct? (list a b c)))
    (assert (not (= a 1)))
    (assert (not (= b 2)))
    (assert (not (= c 3)))
    (assert (not (= a 2)))
    (list a b c)))
(test1)

(define (make-and a b)
  (list a 'AND b))

(define (make-or a b)
  (list a 'or b))

(define (eval lat)

(make-and 'c 'd)


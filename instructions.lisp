;;;; Defines the hash-table containing all standard instructions.
;;;; Each instruction is a function, which is passed a single
;;;; argument; the ip that is executing it

(in-package :puffball)

(defvar *funge-98-instructions* (make-hash-table)
  "Standard instruction set for Funge-98")

(defmacro define-funge-instruction (name &body body)
  "Defines a funge instruction corresponding to the character NAME.
   Instructions have two arguments: IP, which is bound to the ip executing the
   instruction, and F-SPACE, which is bound to the funge-space that the ip
   executing the instruction is within. The return value of the function is
   assigned to the ip that executed it, so destructively modifying the ip passed
   in is perfectly acceptable"
  `(setf (gethash ,name *funge-98-instructions*)
         (lambda (ip f-space)
           ,@(if (stringp (car body)) ; Put docstrings first
               `(,(car body)
                  (declare (ignorable f-space))
                 ,@(cdr body))
               `((declare (ignorable f-space))
                 ,@body)))))

;;; Instructions "0" through "9"
;;; The more natural DOTIMES or LOOP doesn't work here, as it closes over the
;;; same integer 10 times, and causes all 10 instructions to push 10 onto
;;; the stack
(mapc
  (lambda (n)
    (setf (gethash (digit-char n) *funge-98-instructions*) 
          (lambda (ip f-space)
            (declare (ignore f-space))
            (push n (top-stack ip))
            ip)))
  (loop for x from 0 to 9 collecting x))

;;; String stuff
(define-funge-instruction #\'
  "Push the next character in funge-space onto the stack, and jump over it"
  (setf (ip-location ip)
        (vector-+ (ip-location ip)
                  (ip-delta    ip)))
  (push (char-at f-space (ip-location ip))
        (top-stack ip))
  ip)

;;; Arithmetic
(define-funge-instruction #\+
  "Pop the top two stack values and add them together"
  (push (+ (pop (top-stack ip))
           (pop (top-stack ip)))
        (top-stack ip))
  ip)

(define-funge-instruction #\-
  "Pop the top two stack values and subtract the first from the second"
  (push (- (- (pop (top-stack ip))
              (pop (top-stack ip))))
        (top-stack ip))
  ip)

(define-funge-instruction #\*
  "Pop the top two stack values and multiply them together"
  (push (* (pop (top-stack ip))
           (pop (top-stack ip)))
        (top-stack ip))
  ip)

(define-funge-instruction #\/
  "Pop the top two stack values and divide the second by the first"
  (let ((a (pop (top-stack ip)))
        (b (pop (top-stack ip))))
    (push (floor b a) (top-stack ip))
    ip))

(define-funge-instruction #\%
  "Pop the top two stack values and find the remainder of dividing the second
   by the first"
  (let ((a (pop (top-stack ip)))
        (b (pop (top-stack ip))))
    (push (mod b a) (top-stack ip))
    ip))

;;; Control flow
(define-funge-instruction #\@
  "Kill the current IP"
  (declare (ignore ip))
  nil)

(define-funge-instruction #\Space
  "NOP"
  ;; TODO: Implement backtrack wrapping; " " shouldn't be a NOP, as it should
  ;; execute in "no time at all", as far as concurrency is concerned
  ip)

(define-funge-instruction #\<
  "Change the DELTA of the IP to point to the left"
  (setf (ip-delta ip)
        #(-1 0))
  ip)

(define-funge-instruction #\v
  "Change the DELTA of the IP to point down"
  (setf (ip-delta ip)
        #(0 1))
  ip)

(define-funge-instruction #\^
  "Change the DELTA of the IP to point up"
  (setf (ip-delta ip)
        #(0 -1))
  ip)

(define-funge-instruction #\>
  "Change the DELTA of the IP to point to the right"
  (setf (ip-delta ip)
        #(1 0))
  ip)

(define-funge-instruction #\,
  "Pop the top value off the stack, and print it as a character"
  (princ (pop (top-stack ip)))
  ip)

(define-funge-instruction #\#
  "`Tramponline' instruction; jump over one cell"
  (setf (ip-location ip)
        (vector-+ (ip-location ip)
                  (ip-delta ip)))
  ip)

(define-funge-instruction #\r
  "Reverse the direction of travel"
  (setf (ip-delta ip)
        (map 'vector
             (lambda (x) (* x -1))
             (ip-delta ip)))
  ip)

;;; Stack manipulation
(define-funge-instruction #\$
  "Pops and discards the top element off the stack"
  (pop (top-stack ip))
  ip)

(define-funge-instruction #\:
  "Duplicates the top stack element, pushing a copy of it onto the stack"
  (push (car (top-stack ip))
        (top-stack ip))
  ip)

(define-funge-instruction #\\
  "Swaps the top two stack elements"
  (let ((a (pop (top-stack ip)))
        (b (pop (top-stack ip))))
    (push a (top-stack ip))
    (push b (top-stack ip))
    ip))

(define-funge-instruction #\n
  "Clears the stack"
  (setf (top-stack ip)
        ())
  ip)

;;; Conditionals
(define-funge-instruction #\!
  "Pop a value and push one it it's zero, and zero if it's non-zero"
  (push (if (zerop (pop (top-stack ip)))
          1
          0)
        (top-stack ip))
  ip)

(define-funge-instruction #\`
  "Pop two values and push 1 if the second is larger than the first"
  (push (if (< (pop (top-stack ip))
               (pop (top-stack ip)))
          1
          0)
        (top-stack ip))
  ip)

(define-funge-instruction #\_
  "Pop a value and go right if it's zero, or left if it's non-zero"
  (setf (ip-delta ip)
        (if (zerop (pop (top-stack ip)))
          #( 1 0)
          #(-1 0)))
  ip)

(define-funge-instruction #\|
  "Pop a value and go down if it's zero, or up if it's non-zero"
  (setf (ip-delta ip)
        (if (zerop (pop (top-stack ip)))
          #(0  1)
          #(0 -1)))
  ip)

;;;; Defines the hash-table containing all standard instructions.
;;;; Each instruction is a function, which is passed a single
;;;; argument; the ip that is executing it

(in-package :puffball)

(defvar *funge-98-instructions* (make-hash-table)
  "Standard instruction set for Funge-98")

(defmacro define-funge-instruction (name &body body)
  "Defines a funge instruction corresponding to the character NAME.
   Instructions have one, implicit argument: IP, which is bound to the ip
   executing the instruction. The return value of the function is assigned to
   the ip that executed it, so destructively modifying the ip passed in is
   perfectly acceptable"
  `(setf (gethash ,name *funge-98-instructions*)
         (lambda (ip)
           ,@body)))

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
  (princ (pop (car (ip-stack-stack ip))))
  ip)

(in-package #:org.shirakumo.fraf.kandria)

(defclass module-v0 (version) ())
(defclass module-v1 (version) ())

(defmethod supported-p ((_ module-v0)) T)

(define-decoder (module module-v0) (initargs depot)
  (load-source-file (depot:entry "setup.lisp" depot))
  (let* ((name (find-symbol (string (getf initargs :name)) '#:org.shirakumo.fraf.kandria.mod))
         (class (find-class name NIL)))
    (when (or (null name) (null class) (not (c2mop:subclassp class 'module)))
      (error "Mod ~a does not define a class named ~a" depot (getf initargs :name)))
    (load-module (apply #'ensure-instance (find-module name) class initargs))))
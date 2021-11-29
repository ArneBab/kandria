(in-package #:org.shirakumo.fraf.kandria)

(defclass medium ()
  ())

(defgeneric gravity (medium))
(defgeneric drag (medium))
(defgeneric submerged (thing medium))

(defmethod (setf medium) :around (new object)
  (let ((old (medium object)))
    (unless (eq new old)
      (leave object old)
      (call-next-method)
      (enter object new))
    new))

(defmethod submerged ((entity entity) (medium medium)))
(defmethod enter (object (medium medium)))
(defmethod leave (object (medium medium)))

(defclass air (medium)
  ())

(defmethod drag ((air air))
  1.0)

(defmethod gravity ((air air))
  (vec 0 -15))

(in-package #:org.shirakumo.fraf.kandria)

(defclass save-icon (alloy:layout-element alloy:renderable)
  ((clock :initform 0.0 :accessor clock)
   (presentations:rotation :initform 0.0 :accessor presentations:rotation)))

(defmethod alloy:render :around ((renderer ui) (icon save-icon))
  (simple:with-pushed-transforms (renderer)
    (simple:translate renderer (alloy:bounds icon))
    (simple:rotate renderer (presentations:rotation icon))
    (simple:translate renderer (alloy:px-point (- (alloy:pxx (alloy:bounds icon)))
                                               (- (alloy:pxy (alloy:bounds icon)))))
    (call-next-method)))

;; KLUDGE: ugly.
(defmethod (setf presentations:rotation) :after (value (icon save-icon))
  (when (<= (* PI 6) value)
    (hide-panel 'save-done)))

(presentations:define-realization (ui save-icon)
  ((:b1 simple:polygon)
   (list (alloy:point (alloy:pw -5) (alloy:ph +2))
         (alloy:point (alloy:pw -1) (alloy:ph +3))
         (alloy:point (alloy:pw +1) (alloy:ph +1)))
   :rotation (* PI 2/3)
   :scale (alloy:size 1.1 1.1)
   :pattern colors:black)
  ((:b2 simple:polygon)
   (list (alloy:point (alloy:pw -5) (alloy:ph +2))
         (alloy:point (alloy:pw -1) (alloy:ph +3))
         (alloy:point (alloy:pw +1) (alloy:ph +1)))
   :rotation (* PI 4/3)
   :scale (alloy:size 1.1 1.1)
   :pattern colors:black)
  ((:b3 simple:polygon)
   (list (alloy:point (alloy:pw -5) (alloy:ph +2))
         (alloy:point (alloy:pw -1) (alloy:ph +3))
         (alloy:point (alloy:pw +1) (alloy:ph +1)))
   :rotation (* PI 6/3)
   :scale (alloy:size 1.1 1.1)
   :pattern colors:black)
  ((:1 simple:polygon)
   (list (alloy:point (alloy:pw -5) (alloy:ph +2))
         (alloy:point (alloy:pw -1) (alloy:ph +3))
         (alloy:point (alloy:pw +1) (alloy:ph +1)))
   :rotation (* PI 2/3)
   :pattern colors:white)
  ((:2 simple:polygon)
   (list (alloy:point (alloy:pw -5) (alloy:ph +2))
         (alloy:point (alloy:pw -1) (alloy:ph +3))
         (alloy:point (alloy:pw +1) (alloy:ph +1)))
   :rotation (* PI 4/3)
   :pattern colors:white)
  ((:3 simple:polygon)
   (list (alloy:point (alloy:pw -5) (alloy:ph +2))
         (alloy:point (alloy:pw -1) (alloy:ph +3))
         (alloy:point (alloy:pw +1) (alloy:ph +1)))
   :rotation (* PI 6/3)
   :pattern colors:white))

(animation:define-animation spin
  0.0 ((setf presentations:rotation) 0.0)
  2.0 ((setf presentations:rotation) (float (* PI 6) 0f0) :easing :cubic-in-out))

(defclass save-done (panel)
  ())

(defmethod initialize-instance :after ((panel save-done) &key)
  (let ((layout (make-instance 'org.shirakumo.alloy.layouts.constraint:layout))
        (icon (make-instance 'save-icon)))
    (alloy:enter icon layout :constraints `((:right 60) (:bottom 50) (:size 6 6)))
    (alloy:enter (make-instance 'label :value (@ saving-in-progress)) layout :constraints `((:right 100) (:bottom 35) (:size 120 30)))
    (animation:apply-animation 'spin icon)
    (alloy:finish-structure panel layout NIL)))

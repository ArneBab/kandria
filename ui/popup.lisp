(in-package #:org.shirakumo.fraf.kandria)

(defclass popup-layout (alloy:fixed-layout)
  ())

(presentations:define-realization (ui popup-layout)
  ((:bg simple:rectangle)
   (alloy:extent (alloy:vw -1) (alloy:vh -1) (alloy:vw 2) (alloy:vh 2))
   :pattern (colored:color 0.05 0 0 0.2)))

(defmethod alloy:handle ((ev alloy:pointer-event) (focus popup-layout))
  (restart-case
      (call-next-method)
    (alloy:decline ()
      T)))

(defclass popup-button (button)
  ())

(presentations:define-update (ui popup-button)
  (:label
   :pattern (if alloy:focus colors:white colors:black)
   :size (alloy:un 15))
  (:background
   :pattern (if alloy:focus colors:black (colored:color 0.9 0.9 0.9))))

(defclass popup-label (label)
  ())

(presentations:define-update (ui popup-label)
  (:label
   :pattern colors:black
   :size (alloy:un 15)))

(defclass popup-panel (menuing-panel pausing-panel)
  ((source :initform NIL :initarg :source :accessor source)))

(defmethod initialize-instance :around ((panel popup-panel) &key)
  (call-next-method)
  (let ((popup (make-instance 'popup-layout)))
    (alloy:enter (alloy:layout-element panel) popup)
    (setf (slot-value panel 'alloy:layout-element) popup)))

(defmethod show :after ((panel popup-panel) &key (width (alloy:un 300)) (height (alloy:un 120)))
  (alloy:with-unit-parent (or (source panel) (unit 'ui-pass +world+))
    (let ((bounds (if (source panel)
                      (alloy:bounds (source panel))
                      (alloy:extent (alloy:u- (alloy:vw 0.5) (alloy:u/ width 2))
                                    (alloy:u- (alloy:vh 0.5) (alloy:u/ height 2))
                                    width 0))))
      (alloy:update (alloy:index-element 0 (alloy:layout-element panel))
                    (alloy:layout-element panel)
                    :x (+ (alloy:pxx bounds)
                          (- (alloy:pxw bounds) (alloy:to-px width)))
                    :y (alloy:pxy bounds)
                    :w width
                    :h height))))

(defmethod hide :after ((panel popup-panel))
  (when (source panel)
    (setf (alloy:focus (source panel)) :strong)))

(defclass info-label (label)
  ())

(presentations:define-update (ui info-label)
  (:label
   :pattern colors:black
   :size (alloy:un 14)
   :valign :top
   :halign :start
   :wrap T))

(defclass info-panel (popup-panel)
  ())

(defmethod initialize-instance :after ((panel info-panel) &key text)
  (let* ((layout (make-instance 'alloy:grid-layout :col-sizes '(T) :row-sizes '(T 40)
                                                   :shapes (list (simple:rectangle (unit 'ui-pass T) (alloy:margins) :pattern colors:white))))
         (label (make-instance 'info-label :value text :layout-parent layout))
         (button (make-instance 'popup-button :value #@dismiss-info-panel :layout-parent layout
                                              :on-activate (lambda () (hide panel)))))
    (alloy:finish-structure panel layout button)))

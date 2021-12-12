(in-package #:org.shirakumo.fraf.kandria)

(defclass station-button (alloy:direct-value-component alloy:button)
  ((source :initarg :source :accessor source)
   (target :initarg :target :accessor target)))

(defmethod alloy:text ((button station-button))
  (language-string (name (alloy:value button))))

(defmethod (setf alloy:focus) :after (focus (button station-button))
  (when focus
    ;; FIXME: Show preview
    ))

(defmethod alloy:activate ((button station-button))
  (unless (eq (alloy:value button) (source button))
    (trigger (alloy:value button) (source button)))
  (hide-panel 'fast-travel-menu))

(presentations:define-realization (ui station-button)
  ((:background simple:rectangle)
   (alloy:margins)
   :pattern colors:black)
  ((:label simple:text)
   (alloy:margins 5)
   alloy:text
   :size (alloy:un 15)
   :font (setting :display :font)
   :pattern colors:white
   :valign :middle
   :halign :start)
  ((:current-bg simple:polygon)
   (list (alloy:point (alloy:pw 1.0) (alloy:ph 0.2))
         (alloy:point (alloy:pw 0.7) (alloy:ph 0.2))
         (alloy:point (alloy:pw 0.7) (alloy:ph 0.4))
         (alloy:point (alloy:pw 0.68) (alloy:ph 0.5))
         (alloy:point (alloy:pw 0.7) (alloy:ph 0.6))
         (alloy:point (alloy:pw 0.7) (alloy:ph 0.8))
         (alloy:point (alloy:pw 1.0) (alloy:ph 0.8)))
   :pattern colors:red
   :hidden-p (not (eq (source alloy:renderable) alloy:value)))
  ((:current-text simple:text)
   (alloy:extent (alloy:pw 0.72) (alloy:ph 0.3) (alloy:pw 0.3) (alloy:ph 0.4))
   "You are here"
   :size (alloy:un 12)
   :font (setting :display :font)
   :pattern colors:white
   :valign :middle
   :halign :start
   :hidden-p (not (eq (source alloy:renderable) alloy:value))))

(presentations:define-update (ui station-button)
  (:background
   :pattern (if alloy:focus colors:white colors:black))
  (:label
   :pattern (if alloy:focus colors:black colors:white)))

(defclass fast-travel-menu (menuing-panel pausing-panel)
  ())

(defmethod initialize-instance :after ((panel fast-travel-menu) &key current-station)
  (let* ((layout (make-instance 'eating-constraint-layout
                                :shapes (list (simple:rectangle (unit 'ui-pass T) (alloy:margins) :pattern (colored:color 0 0 0 0.5)))))
         (clipper (make-instance 'alloy:clip-view :limit :x))
         (scroll (alloy:represent-with 'alloy:y-scrollbar clipper))
         (focus (make-instance 'alloy:focus-list))
         (list (make-instance 'alloy:vertical-linear-layout
                              :shapes (list (simple:rectangle (unit 'ui-pass T) (alloy:margins) :pattern (colored:color 0 0 0 0.5)))
                              :min-size (alloy:size 100 50))))
    (alloy:enter list clipper)
    (alloy:enter clipper layout :constraints `((:width 500) (:right 70) (:bottom 100) (:top 100)))
    (alloy:enter scroll layout :constraints `((:width 20) (:right 50) (:bottom 100) (:top 100)))
    (alloy:enter (make-instance 'label :value (@ station-pick-destination)) layout :constraints `((:left 50) (:above ,clipper 10) (:size 500 50)))
    (dolist (station (list-stations))
      (make-instance 'station-button :value station :source current-station :target panel
                                     :layout-parent list :focus-parent focus))
    (let ((back (make-instance 'button :value (@ go-backwards-in-ui) :on-activate (lambda () (hide panel)))))
      (alloy:enter back layout :constraints `((:left 50) (:below ,clipper 10) (:size 200 50)))
      (alloy:enter back focus)
      (alloy:on alloy:exit (focus)
        (setf (alloy:focus back) :strong)))
    (alloy:finish-structure panel layout focus)))

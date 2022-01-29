(in-package #:org.shirakumo.fraf.kandria)

(defclass camera (trial:2d-camera unpausable)
  ((flare:name :initform :camera)
   (scale :initform 1.0 :accessor view-scale)
   (target-size :initarg :target-size :accessor target-size)
   (target :initarg :target :initform NIL :accessor target)
   (intended-location :initform (vec2 0 0) :accessor intended-location)
   (zoom :initarg :zoom :initform 1.0 :accessor zoom)
   (intended-zoom :initform 1.0 :accessor intended-zoom)
   (chunk :initform NIL :accessor chunk)
   (shake-timer :initform 0f0 :accessor shake-timer)
   (shake-intensity :initform 3 :accessor shake-intensity)
   (shake-unique :initform 0 :accessor shake-unique)
   (rumble-intensity :initform 1.0 :accessor rumble-intensity)
   (offset :initform (vec 0 0) :accessor offset))
  (:default-initargs
   :location (vec 0 0)
   :target-size (v* +tiles-in-view+ +tile-size+ .5)))

(defmethod reset ((camera camera))
  (setf (target camera) NIL)
  (setf (chunk camera) NIL)
  (setf (location camera) (vec 0 0))
  (setf (intended-location camera) (vec 0 0))
  (setf (zoom camera) 1.0)
  (setf (intended-zoom camera) 1.0)
  (setf (shake-timer camera) 0.0)
  (setf (offset camera) (vec 0 0)))

(defmethod enter :after ((camera camera) (scene scene))
  (setf (target camera) (unit 'player scene))
  (when (target camera)
    (setf (location camera) (vcopy (location (target camera))))))

(defun clamp-camera-target (camera target)
  (let ((chunk (chunk camera))
        (zoom (max (zoom camera) (intended-zoom camera))))
    (when chunk
      (let ((lx (vx2 (location chunk)))
            (ly (vy2 (location chunk)))
            (lw (vx2 (bsize chunk)))
            (lh (vy2 (bsize chunk)))
            (cw (/ (vx2 (target-size camera)) zoom))
            (ch (/ (vy2 (target-size camera)) zoom)))
        (setf (vx target) (clamp (+ lx cw (- lw))
                                 (vx target)
                                 (+ lx (- cw) lw)))
        (setf (vy target) (clamp (+ ly ch (- lh))
                                 (vy target)
                                 (+ ly (- ch) lh)))))))

(defmethod handle :before ((ev tick) (camera camera))
  (unless (find-panel 'editor)
    (let ((loc (location camera))
          (dt (dt ev)))
      ;; Camera movement
      (let ((int (intended-location camera)))
        (when (target camera)
          (let ((tar (location (target camera))))
            (vsetf int (vx tar) (vy tar))))
        (clamp-camera-target camera int)
        (let* ((dir (v- int loc))
               (len (max 1 (vlength dir)))
               (ease (clamp 0 (+ 0.2 (/ (expt len 1.5) 100)) 20)))
          (nv* dir (/ ease len))
          (nv+ loc dir)))
      ;; Camera zoom
      (let* ((z (zoom camera))
             (int (intended-zoom camera))
             (dir (/ (- (log int) (log z)) 10)))
        (cond ((< (abs dir) 0.001)
               (setf (zoom camera) int))
              (T
               (incf (zoom camera) dir)
               (clamp-camera-target camera loc))))
      ;; Camera shake
      (when (< 0 (shake-timer camera))
        (decf (shake-timer camera) dt)
        (when (typep +input-source+ 'gamepad:device)
          (gamepad:rumble +input-source+ (if (< 0 (shake-timer camera))
                                             (rumble-intensity camera)
                                             0.0)))
        ;; Deterministic shake so that we can slow it down properly.
        (when (< 0 (shake-intensity camera))
          (let ((frame-id (sxhash (+ (shake-unique camera) (mod (floor (* (shake-timer camera) 100)) 100)))))
            (nv+ loc (vcartesian (vec (* (logand #xFF (1+ frame-id)) (shake-intensity camera) 0.001)
                                      (* (logand #xFF frame-id) (/ (* 2 PI) #xFF))))))
          (clamp-camera-target camera loc)))
      (let ((off (offset camera)))
        (when (v/= 0 off)
          (vsetf loc
                 (+ (vx (intended-location camera)) (vx off))
                 (+ (vy (intended-location camera)) (vy off)))
          (nv* off 0.98)
          (when (<= (abs (vx off)) 0.1) (setf (vx off) 0.0))
          (when (<= (abs (vy off)) 0.1) (setf (vy off) 0.0))
          (clamp-camera-target camera loc))))))

(defmethod snap-to-target ((camera camera) target)
  (setf (target camera) target)
  (v<- (location camera) (location target))
  (v<- (intended-location camera) (location target))
  (clamp-camera-target camera (location camera)))

(defmethod (setf target) :after ((target located-entity) (camera camera))
  (when (region +world+)
    (setf (chunk camera) (find-chunk target))))

(defmethod handle :before ((ev resize) (camera camera))
  ;; Adjust max width based on aspect ratio to ensure ultrawides still get to see something.
  (let ((aspect (/ (width ev) (max 1 (height ev)))))
    (setf (vx (target-size camera))
          (cond ((<= aspect 2.1)
                 (* (vx +tiles-in-view+) +tile-size+ .5))
                ((<= aspect 2.6)
                 (* (vx +tiles-in-view+) +tile-size+ .75))
                (T
                 (* (vx +tiles-in-view+) +tile-size+)))))
  ;; Ensure we scale to fit width as much as possible without showing space
  ;; outside the chunk.
  (let* ((optimal-scale (float (/ (width ev) (* 2 (vx (target-size camera))))))
         (max-fit-scale (if (chunk camera) (/ (height ev) (vy (bsize (chunk camera))) 2) optimal-scale))
         (scale (max 0.0001 optimal-scale max-fit-scale)))
    (setf (view-scale camera) scale)
    (setf (vy (target-size camera)) (/ (height ev) scale 2))))

(defmethod (setf chunk) :after (chunk (camera camera))
  ;; Optimal bounds might have changed, update.
  (handle (make-instance 'resize :width (width *context*) :height (height *context*)) camera))

(defmethod handle ((ev switch-chunk) (camera camera))
  (setf (chunk camera) (chunk ev)))

(defmethod handle ((ev switch-region) (camera camera))
  (setf (target camera) (unit 'player T)))

(defmethod handle ((ev window-shown) (camera camera))
  (if (target camera)
      (snap-to-target camera (target camera))
      (vsetf (location camera) 0 0)))

(defmethod project-view ((camera camera))
  (let* ((z (max 0.0001 (* (view-scale camera) (zoom camera))))
         (v (nv- (v/ (target-size camera) (zoom camera)) (location camera))))
    (reset-matrix *view-matrix*)
    (scale-by z z z *view-matrix*)
    (translate-by (vx v) (vy v) 100 *view-matrix*)))

(defun shake-camera (&key (duration 0.2) (intensity 3) (rumble-intensity 1.0))
  (let ((camera (unit :camera +world+)))
    (setf (shake-unique camera) (random 100))
    (setf (shake-timer camera) duration)
    (setf (shake-intensity camera) (* (setting :gameplay :screen-shake) intensity))
    (setf (rumble-intensity camera) (* (setting :gameplay :rumble) rumble-intensity))
    (when (= 0 duration)
      (gamepad:call-with-devices (lambda (d) (gamepad:rumble d 0.0))))))

(defun rumble (&key (duration 0.3) (intensity 1.0))
  (let ((camera (unit :camera +world+)))
    (setf (shake-timer camera) duration)
    (setf (rumble-intensity camera) (* (setting :gameplay :rumble) intensity))
    (when (= 0 duration)
      (gamepad:call-with-devices (lambda (d) (gamepad:rumble d 0.0))))))

(defun duck-camera (x y)
  (let ((off (offset (unit :camera +world+))))
    (vsetf off
           (+ (vx off) (* 0.1 (- x (vx off))))
           (+ (vy off) (* 0.1 (- y (vy off)))))))

(defmethod bsize ((camera camera))
  (let* ((context (context +main+))
         (zoom (the single-float (zoom camera)))
         (vscale (the single-float (view-scale camera))))
    (tvec (/ (the (unsigned-byte 32) (width context)) (* zoom 2 vscale))
          (/ (the (unsigned-byte 32) (height context)) (* zoom 2 vscale)))))

(defun in-view-p (loc bsize)
  (declare (optimize speed))
  (let* ((camera (unit :camera +world+))
         (context (context +main+))
         (zoom (the single-float (zoom camera)))
         (vscale (the single-float (view-scale camera)))
         (siz (target-size camera))
         (- (tvec 0 0))
         (+ (tvec (/ (the (unsigned-byte 32) (width context)) (* zoom vscale))
                  (/ (the (unsigned-byte 32) (height context)) (* zoom vscale))))
         (off (tvec (/ (vx2 siz) zoom)
                    (/ (vy2 siz) zoom))))
    (nv- (nv+ - (location camera)) off)
    (nv- (nv+ + (location camera)) off)
    (and (< (vx2 -) (+ (vx2 loc) (vx2 bsize)))
         (< (- (vx2 loc) (vx2 bsize)) (vx2 +))
         (< (- (vy2 loc) (vy2 bsize)) (vy2 +))
         (< (vy2 -) (+ (vy2 loc) (vy2 bsize))))))

(in-package #:org.shirakumo.fraf.kandria)

(define-global +max-stun+ 3d0)
(define-global +hard-hit+ 20)

(define-shader-entity animatable (movable lit-animated-sprite)
  ((health :initarg :health :initform 1000 :accessor health)
   (stun-time :initform 0d0 :accessor stun-time)
   (idle-time :initform 0f0 :accessor idle-time)
   (iframes :initform 0 :accessor iframes)))

(defmethod initialize-instance :after ((animatable animatable) &key)
  (setf (idle-time animatable) (minimum-idle-time animatable)))

(defgeneric minimum-idle-time (animatable))
(defgeneric kill (animatable))
(defgeneric die (animatable))
(defgeneric interrupt (animatable))
(defgeneric hurt (animatable damage))
(defgeneric stun (animatable stun))
(defgeneric start-animation (name animatable))
(defgeneric in-danger-p (animatable))

(defmethod minimum-idle-time ((animatable animatable)) 10)

(defmethod apply-transforms progn ((animatable animatable))
  (let ((frame (frame animatable)))
    (translate-by (vx (offset frame))
                  (vy (offset frame))
                  0)))

(defmethod hurtbox ((animatable animatable))
  (let* ((location (location animatable))
         (direction (direction animatable))
         (frame (frame animatable))
         (hurtbox (hurtbox frame)))
    (vec4 (+ (vx location) (* (vx hurtbox) direction))
          (+ (vy location) (vy hurtbox))
          (vz hurtbox)
          (vw hurtbox))))

(defmethod attacking-p ((animatable animatable))
  (let ((idx (frame-idx animatable))
        (end (end (animation animatable)))
        (frames (frames animatable))
        (precognition-frames 3))
    (loop for i from idx below (min end (+ precognition-frames idx))
          thereis (< 0 (vw (hurtbox (svref frames i)))))))

(defmethod in-danger-p ((animatable animatable))
  (for:for ((entity over (region +world+)))
    (when (and (typep entity 'animatable)
               (not (eql animatable entity))
               (attacking-p entity)
               ;; KLUDGE: this sucks
               (< (vdistance (location entity) (location animatable)) (* 2 +tile-size+)))
      (return entity))))

(defmethod hurt :around ((animatable animatable) damage)
  (when (and (< 0 (health animatable))
             (not (invincible-p (frame animatable)))
             (<= (iframes animatable) 0))
    ;; I don't like this very much. We need a better way to distinguish individual "attacks"
    (setf (iframes animatable) 60)
    (call-next-method)))

(defmethod hurt ((animatable animatable) damage)
  (when (interrupt animatable)
    (when (<= +hard-hit+ damage)
      (setf (animation animatable) 'hard-hit)))
  (decf (health animatable) damage)
  (when (<= (health animatable) 0)
    (kill animatable)))

(defmethod kill :around ((animatable animatable))
  (unless (eql :dying (state animatable))
    (call-next-method)))

(defmethod kill ((animatable animatable))
  (setf (health animatable) 0)
  (setf (state animatable) :dying)
  (setf (animation animatable) 'die))

(defmethod die ((animatable animatable))
  (leave animatable T)
  (remove-from-pass animatable +world+))

(defmethod switch-animation :before ((animatable animatable) next)
  ;; Remove selves when death animation completes
  (when (eql (name (animation animatable)) 'die)
    (die animatable)))

(defmethod (setf frame-idx) :before (idx (animatable animatable))
  (let ((previous-idx (frame-idx animatable)))
    (when (/= idx previous-idx)
      (let ((effect (effect (svref (frames animatable) idx))))
        (when effect
          (trigger effect animatable))))))

(defmethod interrupt ((animatable animatable))
  (when (interruptable-p (frame animatable))
    (unless (eql :stunned (state animatable))
      (setf (animation animatable) 'light-hit)
      (setf (state animatable) :animated))))

(defmethod stun ((animatable animatable) stun)
  (when (and (< 0 stun)
             (interruptable-p (frame animatable)))
    (setf (stun-time animatable) (min +max-stun+ (+ (stun-time animatable) stun)))
    (setf (animation animatable) 'light-hit)
    (setf (state animatable) :stunned)))

(defmethod start-animation (name (animatable animatable))
  (when (or (not (eql :animating (state animatable)))
            (cancelable-p (frame animatable)))
    (setf (animation animatable) name)
    (setf (state animatable) :animated)))

(defmethod handle-animation-states ((animatable animatable) ev)
  (let ((vel (frame-velocity animatable))
        (frame (frame animatable)))
    (case (state animatable)
      (:animated
       (when (/= 0 (vz (hurtbox frame)) (vw (hurtbox frame)))
         (let ((hurtbox (hurtbox animatable)))
           (for:for ((entity over (region +world+)))
             (when (and (typep entity 'animatable)
                        (not (eql animatable entity))
                        (< 0 (vz hurtbox))
                        (< 0 (vw hurtbox))
                        (contained-p hurtbox entity))
               (when (interruptable-p (frame entity))
                 (setf (direction entity) (- (direction animatable)))
                 (incf (vx (velocity entity)) (* (direction animatable) (vx (knockback frame))))
                 (incf (vy (velocity entity)) (vy (knockback frame)))
                 (stun entity (stun-time frame)))
               (hurt entity (damage frame))))))
       (when (eql 'stand (name (animation animatable)))
         (setf (state animatable) :normal)))
      (:stunned
       (nv* vel 0)
       (decf (stun-time animatable) (dt ev))
       (when (<= (stun-time animatable) 0)
         (setf (state animatable) :normal)))
      (:dying))
    (nv* (velocity animatable) (multiplier frame))
    (incf (vx vel) (* (direction animatable) (vx (velocity frame))))
    (incf (vy vel) (vy (velocity frame)))))

(defmethod handle :before ((ev tick) (animatable animatable))
  (when (< 0 (iframes animatable))
    (decf (iframes animatable)))
  (case (state animatable)
    (:normal
     (when (= 0 (vx (velocity animatable)))
       (decf (idle-time animatable) (dt ev))
       (when (<= (idle-time animatable) 0.0)
         (setf (idle-time animatable) (+ (minimum-idle-time animatable) (random 8.0)))
         (start-animation 'idle animatable))))))

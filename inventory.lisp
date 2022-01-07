(in-package #:org.shirakumo.fraf.kandria)

(defgeneric item-order (item))

(defclass inventory ()
  ((storage :initform (make-hash-table :test 'eq) :accessor storage)
   (unlock-table :initform (make-hash-table :test 'eq) :accessor unlock-table)))

(defmethod have ((item symbol) (inventory inventory))
  (< 0 (gethash item (storage inventory) 0)))

(defmethod item-count ((item symbol) (inventory inventory))
  (gethash item (storage inventory) 0))

(defmethod item-count ((item (eql T)) (inventory inventory))
  (hash-table-count (storage inventory)))

(defmethod store ((item symbol) (inventory inventory) &optional (count 1))
  (when (subtypep item 'unlock-item)
    (setf (gethash item (unlock-table inventory)) T))
  (incf (gethash item (storage inventory) 0) count))

(defmethod item-unlocked-p ((item symbol) (inventory inventory))
  (gethash item (unlock-table inventory)))

(defmethod retrieve ((item symbol) (inventory inventory) &optional (count 1))
  (let* ((have (gethash item (storage inventory) 0))
         (count (etypecase count
                  ((eql T) (setf count have))
                  (integer count))))
    (cond ((< count have)
           (setf (gethash item (storage inventory) 0) (- have count)))
          ((= count have)
           (remhash item (storage inventory)))
          (T
           (error "Can't remove ~s, don't have enough in inventory." item)))))

(defmethod clear ((inventory inventory))
  (clrhash (storage inventory)))

(defgeneric list-items (from kind))

(defmethod list-items ((inventory inventory) (type symbol))
  (sort (loop for item being the hash-keys of (storage inventory)
              for prototype = (make-instance item)
              when (typep prototype type)
              collect prototype)
        #'item<))

(define-shader-entity item (lit-sprite game-entity interactable)
  ((texture :initform (// 'kandria 'items))
   (size :initform (vec 8 8))
   (bsize :initform (vec 5 5))
   (layer-index :initform +base-layer+)
   (velocity :initform (vec 0 0))
   (light :initform NIL :accessor light)
   (medium :initform +default-medium+ :accessor medium)))

(defun item< (a b)
  (let ((a-order (item-order a))
        (b-order (item-order b)))
    (if (= a-order b-order)
        (string< (title a) (title b))
        (< a-order b-order))))

(defmethod experience-reward ((item item))
  10)

(defmethod enter :after ((entity item) (magma magma))
  (kill entity))

(defmethod description ((item item))
  (language-string 'item))

(defmethod title ((item item))
  (language-string (type-of item)))

(defmethod price ((item item))
  0)

(defmethod item-description ((item item))
  (language-string (intern (format NIL "~a/DESCRIPTION" (string (type-of item)))
                           (symbol-package (class-name (class-of item))))))

(defmethod item-lore ((item item))
  (or (language-string (intern (format NIL "~a/LORE" (string (type-of item)))
                               (symbol-package (class-name (class-of item))))
                       NIL)
      "<?>"))

(defmethod item-unlocked-p ((item item) (inventory inventory))
  (item-unlocked-p (type-of item) inventory))

(defmethod kill ((item item))
  (leave* item T))

(defmethod spawn :before ((region region) (item item) &key)
  (vsetf (velocity item)
         (* (- (* 2 (random 2)) 1) (random* 2 1))
         (random* 4 2)))

(defmethod item-order ((_ item)) 0)

(defmethod collides-p ((item item) thing hit) NIL)
(defmethod collides-p ((item item) (block block) hit) T)
(defmethod collides-p (thing (item item) hit) NIL)
(defmethod collides-p ((moving moving) (item item) hit) NIL)
(defmethod collides-p ((block block) (item item) hit) T)
(defmethod collides-p ((block stopper) (item item) hit) NIL)
(defmethod collide (thing (item item) hit) NIL)

(defmethod interactable-p ((item item))
  (let ((vel (velocity item)))
    (and (= 0 (vx vel)) (= 0 (vy vel)))))

(defmethod handle :before ((ev tick) (item item))
  (when (v/= 0 (velocity item))
    (nv+ (velocity item) (v* (gravity (medium item)) (dt ev)))
    (nv+ (frame-velocity item) (velocity item))
    (handle-collisions +world+ item))
  (when (light item)
    (vsetf (location (light item))
           (vx (location item))
           (+ 12 (vy (location item))))
    (when (= 0 (mod (fc ev) 10))
      (setf (multiplier (light item)) (random* 1.0 0.2)))))

(defmethod collide ((item item) (block block) hit)
  (let ((vel (frame-velocity item))
        (normal (hit-normal hit)))
    (nv* (velocity item) 0.9)
    (nv+ (location item) (v* vel (hit-time hit)))
    (nv- vel (v* normal (v. vel normal)))
    (when (= 1 (vy normal))
      (setf (vx (velocity item)) 0))
    (when (< 0 (vy normal))
      (setf (vy (velocity item)) 0))
    (when (<= (abs (vx (velocity item))) 0.1)
      (setf (vx (velocity item)) 0))
    (unless (light item)
      (let ((light (make-instance 'textured-light :location (nv+ (vec 0 16) (location item))
                                                  :multiplier 1.0
                                                  :bsize (vec 32 32)
                                                  :size (vec 64 64)
                                                  :offset (vec 0 144))))
        (setf (light item) light)
        (setf (container light) +world+)
        (compile-into-pass light NIL (unit 'lighting-pass +world+))))))

(defmethod collides-p ((moving item) (block slope) hit)
  (ignore-errors
   (let ((tt (slope (location moving) (frame-velocity moving) (bsize moving) block (hit-location hit))))
     (when tt
       (setf (hit-time hit) tt)
       (setf (hit-normal hit) (nvunit (vec2 (- (vy2 (slope-l block)) (vy2 (slope-r block)))
                                            (- (vx2 (slope-r block)) (vx2 (slope-l block))))))))))

(defmethod interact ((item item) (inventory inventory))
  (store item inventory)
  (status (@formats 'new-item-in-inventory (language-string (type-of item))))
  (leave* item T))

(defmethod leave* :after ((item item) thing)
  (when (light item)
    (remove-from-pass (light item) (unit 'lighting-pass +world+))
    (setf (light item) NIL)))

(defmethod have ((item item) (inventory inventory))
  (have (type-of item) inventory))

(defmethod item-count ((item item) (inventory inventory))
  (item-count (type-of item) inventory))

(defmethod store ((item item) (inventory inventory) &optional (count 1))
  (store (type-of item) inventory count))

(defmethod retrieve ((item item) (inventory inventory) &optional (count 1))
  (retrieve (type-of item) inventory count)
  item)

(defmethod use ((item symbol) on)
  (use (make-instance (find-class item)) on))

(defmethod use ((item item) on))

(defclass item-category ()
  ())

(defun list-item-categories ()
  (mapcar #'class-name (c2mop:class-direct-subclasses (find-class 'item-category))))

(defmethod list-items ((inventory inventory) (category item-category))
  (list-items inventory (item-category category)))

(defmethod list-items ((category item-category) type)
  (sort (loop for class in (c2mop:class-direct-subclasses (class-of category))
              for prototype = (make-instance (c2mop:ensure-finalized class))
              when (typep prototype type)
              collect prototype)
        #'item<))

(defmacro define-item-category (name &optional superclasses slots)
  `(progn
     (defclass ,name (,@superclasses item-category) ,slots)

     (defmethod item-category ((item ,name)) ',name)))

(define-item-category consumable-item)

(defmethod use :before ((item consumable-item) (inventory inventory))
  (retrieve item inventory))

(define-item-category quest-item)
(define-item-category value-item)
(define-item-category special-item)
(define-item-category unlock-item)
(define-item-category lore-item (unlock-item))

(defmacro define-item ((name &rest superclasses) x y w h &rest default-initargs &key price &allow-other-keys)
  (let ((name (intern (string name) '#:org.shirakumo.fraf.kandria.item)))
    (remf default-initargs :price)
    (export name (symbol-package name))
    `(progn
       (export ',name (symbol-package ',name))
       ,(emit-export '#:org.shirakumo.fraf.kandria.item name '/description)
       ,(emit-export '#:org.shirakumo.fraf.kandria.item name '/lore)
       (define-shader-entity ,name (,@superclasses item)
         ((size :initform ,(vec w h))
          (offset :initform ,(vec x y)))
         (:default-initargs
          ,@default-initargs))
       ,(when price
          `(defmethod price ((_ ,name)) ,price)))))

(define-shader-entity health-pack (item consumable-item value-item) ())
(define-shader-entity value-quest-item (item quest-item value-item) ())

(defmethod use ((item health-pack) (animatable animatable))
  (let ((buff (ceiling (* (health item) 0.01 (maximum-health animatable)))))
    (incf (health animatable) buff)
    (trigger (make-instance 'text-effect) animatable
             :text (format NIL "+~d" buff)
             :location (vec (+ (vx (location animatable)))
                            (+ (vy (location animatable)) 8 (vy (bsize animatable)))))))

(define-item (small-health-pack health-pack) 0 0 8 8
  :price 100)
(defmethod health ((_ item:small-health-pack)) 10)
(defmethod item-order ((_ item:small-health-pack)) 0)

(define-item (medium-health-pack health-pack) 0 0 8 8
  :price 250)
(defmethod health ((_ item:medium-health-pack)) 25)
(defmethod item-order ((_ item:medium-health-pack)) 1)

(define-item (large-health-pack health-pack) 0 0 8 8
  :price 500)
(defmethod health ((_ item:large-health-pack)) 50)
(defmethod item-order ((_ item:large-health-pack)) 2)

(define-item-category active-effect-item (consumable-item)
  ((clock :initform 30.0 :initarg :duration :accessor clock)))

(defmethod use ((item active-effect-item) (animatable animatable))
  (push item (active-effects animatable)))

(define-item (damage-shield active-effect-item value-item) 48 0 8 8
  :price 200)

(defmethod apply-effect ((effect item:damage-shield) (animatable animatable))
  (decf (damage-input-scale animatable) 0.2))

(define-item (combat-booster active-effect-item value-item) 40 0 8 8
  :price 200)

(defmethod apply-effect ((effect item:combat-booster) (animatable animatable))
  (incf (damage-output-scale animatable) 0.2))

(define-item (nanomachine-salve active-effect-item value-item) 32 0 8 8
  :price 200 :duration 10.0)

(defmethod apply-effect ((effect item:nanomachine-salve) (animatable animatable))
  ;; We want to buff 25% by the end of the 10s.
  (incf (health animatable) (* (maximum-health animatable) (/ 0.25 1000))))

;; VALUE ITEMS
(define-item (parts value-item) 8 16 8 8
  :price 1)

(defclass scrap () ()) (defmethod item-order ((_ scrap)) 1)
(define-item (heavy-spring scrap value-item) 8 16 8 8
  :price 10)
(define-item (satchel scrap value-item) 16 16 8 8
  :price 30)
(define-item (screw scrap value-item) 24 16 8 8
  :price 10)
(define-item (bolt scrap value-item) 32 16 8 8
  :price 10)
(define-item (nut scrap value-item) 40 16 8 8
  :price 10)
(define-item (gear scrap value-item) 48 16 8 8
  :price 10)
(define-item (bent-rod scrap value-item) 56 16 8 8
  :price 10)
(define-item (large-gear scrap value-item) 64 16 8 8
  :price 10)
(define-item (copper-ring scrap value-item) 72 16 8 8
  :price 10)
(define-item (metal-ring scrap value-item) 80 16 8 8
  :price 10)
(define-item (broken-ring scrap value-item) 88 16 8 8
  :price 10)
(define-item (heavy-rod scrap value-item) 96 16 8 8
  :price 10)
(define-item (light-rod scrap value-item) 104 16 8 8
  :price 10)
(define-item (simple-gadget scrap value-item) 112 16 8 8
  :price 10)
(define-item (dented-plate scrap value-item) 120 16 8 8
  :price 10)

(defclass electronics () ()) (defmethod item-order ((_ electronics)) 2)
(define-item (simple-circuit electronics value-item) 8 24 8 8
  :price 20)
(define-item (complex-circuit electronics value-item) 16 24 8 8
  :price 30)
(define-item (broken-circuit electronics value-item) 24 24 8 8
  :price 10)
(define-item (large-battery electronics value-item) 32 24 8 8
  :price 30)
(define-item (small-battery electronics value-item) 40 24 8 8
  :price 20)
(define-item (coin electronics value-item) 48 24 8 8
  :price 10)
(define-item (controller electronics value-item) 56 24 8 8
  :price 10)
(define-item (connector electronics value-item) 64 24 8 8
  :price 10)
(define-item (cable electronics value-item) 72 24 8 8
  :price 10)
(define-item (memory electronics value-item) 80 24 8 8
  :price 10)
(define-item (genera-core electronics value-item) 88 24 8 8
  :price 20)
(define-item (rusted-key electronics value-item) 96 24 8 8
  :price 10)

(defclass ores () ()) (defmethod item-order ((_ ores)) 3)
(define-item (clay-clump ores value-item) 0 32 8 8
  :price 20)
(define-item (gold-nugget ores value-item) 8 32 8 8
  :price 1000)
(define-item (silver-ore ores value-item) 16 32 8 8
  :price 600)
(define-item (bronze-clump ores value-item) 24 32 8 8
  :price 300)
(define-item (rich-soil ores value-item) 32 32 8 8
  :price 50)
(define-item (meteorite-fragment ores value-item) 40 32 8 8
  :price 40)
(define-item (hardened-alloy ores value-item) 48 32 8 8
  :price 30)
(define-item (quartz-crystal ores value-item) 56 32 8 8
  :price 50)
(define-item (rusted-clump ores value-item) 64 32 8 8
  :price 10)
(define-item (pearl ores value-item) 72 32 8 8
  :price 50)
(define-item (dirt-clump ores value-item) 80 32 8 8
  :price 10)

(defclass liquids () ()) (defmethod item-order ((_ liquids)) 4)
(define-item (coolant liquids value-item) 0 40 8 8
  :price 30)
(define-item (pure-water liquids value-item) 8 40 8 8
  :price 100)
(define-item (crude-oil liquids value-item) 16 40 8 8
  :price 100)
(define-item (refined-oil liquids value-item) 24 40 8 8
  :price 200)
(define-item (thermal-fluid liquids value-item) 32 40 8 8
  :price 30)
(define-item (mossy-water liquids value-item) 40 40 8 8
  :price 50)
(define-item (cloudy-water liquids value-item) 48 40 8 8
  :price 150)

(defclass skins () ()) (defmethod item-order ((_ skins)) 5)
(define-item (ruined-pelt skins value-item) 8 48 8 8
  :price 50)
(define-item (fine-pelt skins value-item) 0 48 8 8
  :price 100)
(define-item (pristine-pelt skins value-item) 16 48 8 8
  :price 200)

;; QUEST ITEMS
(define-item (seeds quest-item) 16 16 8 8)
(define-item (semi-factory-key quest-item) 8 0 8 8)
(define-item (can quest-item) 0 16 8 8)

;; VALUE-ITEMS (can be sold)
(define-item (mushroom-good-1 value-quest-item) 24 8 8 8
  :price 10)
(define-item (mushroom-good-2 value-quest-item) 32 8 8 8
  :price 10)
(define-item (mushroom-bad-1 value-quest-item) 16 8 8 8
  :price 20)
(define-item (walkie-talkie value-quest-item) 0 8 8 8
  :price 500)

;; SPECIAL ITEMS
(defclass palette-unlock (special-item)
  ())
(defmethod unlocked-palettes ((inventory inventory))
  (list-items inventory 'palette-unlock))
(macrolet ((define-palettes ()
             `(progn
                ,@(loop for palette in (getf (read-src (input* (asset 'kandria 'player))) :palettes)
                        for name = (intern (format NIL "~:@(PALETTE-~a~)" (substitute #\- #\Space palette)) '#:item)
                        for i from 0
                        append `((define-item (,name palette-unlock) 0 16 8 8)
                                 (defmethod palette-index ((,name ,name)) ,i))))))
  (define-palettes))

;; Draws
(define-random-draw mushrooms
  (item:mushroom-good-1 1)
  (item:mushroom-good-2 1)
  (item:mushroom-bad-1 1))
;; generally don't use this one, as it can be hard for the player to differentiate good from bad ones in the world, and they might not want to collect bad ones (for Catherine to burn, or Sahil to buy) - unless they can destroy them in their inventory (probably preferable to handling dropping in the world)

(define-random-draw mushrooms-good
  (item:mushroom-good-1 1)
  (item:mushroom-good-2 1))
;; placement: where background big mushrooms are
  
(define-random-draw mushrooms-good-1
  (item:mushroom-good-1 2)
  (item:mushroom-good-2 1))
;; placement: where background big mushrooms are
  
(define-random-draw mushrooms-good-2
  (item:mushroom-good-1 1)
  (item:mushroom-good-2 2))
;; placement: where background big mushrooms are
  
(define-random-draw mushrooms-bad-1
  (item:mushroom-bad-1 1))
;; placement: where mushrooms wouldn't be expected to grow i.e. in non-soil areas
  
(define-random-draw region1-cave
  (item:clay-clump 3)
  (item:rich-soil 1)
  (item:meteorite-fragment 2)
  (item:quartz-crystal 1)
  (item:rusted-clump 3)
  (item:dirt-clump 3)
  (item:ruined-pelt 3))
;; placement: region 1 soil areas

(define-random-draw region1-home
  (item:satchel 2)
  (item:small-battery 2)
  (item:controller 1)
  (item:cable 3)
  (item:broken-circuit 3)
  (item:simple-gadget 3))
;; placement: region 1 apartment areas

(define-random-draw region1-office
  (item:simple-circuit 2)
  (item:complex-circuit 1)
  (item:broken-ring 4)
  (item:metal-ring 3))
;; placement: region 1 office areas

(define-random-draw region1-factory
  (item:heavy-spring 3)
  (item:screw 3)
  (item:bolt 3)
  (item:nut 3)
  (item:gear 3)
  (item:bent-rod 3)
  (item:crude-oil 1))
;; placement: region 1 factory areas

(define-random-draw region1-market
  (item:mossy-water 1)
  (item:cloudy-water 1)
  (item:bronze-clump 1)
  (item:rusted-key 2)
  (item:coin 3))
;; placement: region 1 market areas

;; DEBUG SPAWNERS
(define-random-draw debug-pure-water
  (item:pure-water 1))
  
(define-random-draw debug-pearl
  (item:pearl 1))
  
(define-random-draw debug-thermal
  (item:thermal-fluid 1))
  
(define-random-draw debug-coolant
  (item:coolant 1))

#| ITEMS UNUSED IN SPAWNERS SO FAR
  
  (item:large-gear 1)
  (item:copper-ring 1)  
  (item:genera-core 1)
  (item:heavy-rod 1)
  (item:light-rod 1)  
  (item:dented-plate 1)    
  (item:large-battery 1)
  (item:connector 1)  
  (item:memory 1)  
  (item:hardened-alloy 3)
  (item:pearl 1)
  (item:gold-nugget 1)
  (item:silver-ore 2)  
  (item:coolant 3)
  (item:pure-water 1)  
  (item:refined-oil 2)
  (item:thermal-fluid 3)
  (item:fine-pelt 2)
  (item:pristine-pelt 1)
  
|#

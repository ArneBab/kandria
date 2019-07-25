(asdf:defsystem leaf
  :components ((:file "package")
               (:file "helpers")
               (:file "auto-fill")
               (:file "layered-container")
               (:file "serialization")
               (:file "packet")
               (:file "region")
               (:file "keys")
               (:file "textbox")
               (:file "surface")
               (:file "lighting")
               (:file "background")
               (:file "chunk")
               (:file "lighted-sprite-entity")
               (:file "moving-platform")
               (:file "moving")
               (:file "move-to")
               (:file "interactable")
               (:file "player")
               (:file "world")
               (:file "versions/v0")
               (:file "editor")
               (:file "menu")
               (:file "camera")
               (:file "main")
               (:file "save-state")
               (:file "versions/save-v0")
               (:file "effects"))
  :depends-on (:trial-glfw
               :zip
               :fast-io
               :ieee-floats
               :babel
               :form-fiddle
               :array-utils
               :lambda-fiddle
               :trivial-arguments
               :trivial-indent
               :leaf-dialogue
               :leaf-quest
               :alexandria))

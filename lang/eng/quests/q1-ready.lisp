;; -*- mode: poly-dialog; -*-
(in-package #:org.shirakumo.fraf.kandria)

(quest:define-quest (kandria q1-ready)
  :author "Tim White"
  :title "Talk to Catherine"
  :description "I should let Catherine know when I'm ready to help her fix the leak."
  :on-activate (q1-ready-chat)
  (q1-ready-chat
   :title "Talk to Catherine in Engineering"
   :condition NIL
   :on-activate T
   :on-complete (q1-water)
   (:interaction talk-catherine
    :interactable catherine
    :repeatable T
    :dialogue "
~ catherine
| You ready to \"fix that leak\"(orange)?
~ player
- I'm ready.
  ~ catherine
  | Alright. We're going down the ladder over there.
  | Follow the \"red pipeline\"(orange) and \"stay close\"(orange).
  ! eval (deactivate interaction)
  ! eval (complete task)
- Not yet.
  ~ catherine
  | [? Alright, you can have a minute. | Okay but we need to hurry - the water supply isn't gonna fix itself. | Okay, but whatever you need to do, please be quick about it.]
- (Review task log)
  ~ player
  | \"//My Log Files record data about my assigned tasks; if ever I'm unsure what to do next, I should access and review these.//\"(light-gray)
  | (:giggle)\"//The benefits of being an android!//\"(light-gray)
- What are we doing again?
  ~ catherine
  | (:concerned)Um, did your short-term memory corrupt? We need to fix the leak - before we lose the crop and everyone starves!
  ~ player
  - I don't need to eat.
    ~ catherine
    | (:disappointed)Well the rest of us aren't so lucky. Aren't so unlucky, actually.
  - Ah, I remember now.
    ~ catherine
    | (:concerned)Good. Well...
  - But my systems are currently sub-optimal.
    ~ catherine
    | Decades sat on your ass in a cave will do that.
    | (:concerned)I don't think there's much I can do for you right now though. Sorry.
  ~ catherine
  | \"Let me know\"(orange) when you're ready to go. But we can't afford to wait too long.
  ")
  )
)

#| TODO add in diegetic explanation of saving progress, in addition to the onscreen prompt? e.g.

- (Save progress)
  ~ player
  | //Now I'm learning about this world, I should save my log files - just in case something untoward happens again.//
  | //I saw one of their phone booths outside - I think I can interface with that to record my data.//

|#
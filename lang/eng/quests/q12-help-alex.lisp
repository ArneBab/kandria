;; -*- mode: poly-dialog; -*-
(in-package #:org.shirakumo.fraf.kandria)

(quest:define-quest (kandria q12-help-alex)
  :author "Tim White"
  :title ""
  :visible NIL
  :on-activate (alex-task)

  (alex-task
   :title ""
   :invariant (not (complete-p 'q13-planting-bomb))
   :condition all-complete
   :on-activate (alex-interact)

   (:interaction alex-interact
    :interactable alex
    :title ""    
    :dialogue "
? (complete-p 'q8-alex-cerebat)
| ~ player
| | Why are you here?
| ~ alex
| | (:angry)Why do you think?
|?
| ~ player
| - Alex?
|   ~ alex
|   | (:angry)Not for much longer.
| - What are you doing here?
|   ~ alex
|   | (:angry)Biding my time.
| - Are you sober?
|   ~ alex
|   | (:angry)As a judge at the Last Judgement.
  
~ alex
| (:angry)I can't wait to see the look on Fi's face when the Wraw come pouring out the ground.
~ player
- What do you mean?
- What have you done?
~ alex
| \"I told them the exact location o' the Noka camp.\"(orange)
| (:angry)It's the least I could do to repay you an' Fi for your loyalty.
| (:normal)Now if you don't mind, I've got a battle to fight.
| (:angry)Watch your back, {(nametag player)}.
! eval (setf (location 'fi) (location 'shutter-3))
! eval (setf (direction 'fi) -1)
! eval (setf (location 'jack) (location 'shutter-4))
! eval (setf (direction 'jack) -1)
! eval (activate 'fi-task)
"))

  ;; optional dialogue - marker added though, as adds further depth to the story
  ;; could occur with either Jack and Fi alone, or with Islay if Semis are on surface now; or with Fi and Islay alone in Engineering. Either way, Islay doesn't weigh in on this Noka business, and we can assume Fi will tell her later
  ;; invariants after q13-planting-bomb, when the next quest q14-envoy will hardwire Alex's betrayal reveal
  (fi-task
   :title ""
   :marker '(fi 500)
   :invariant (not (complete-p 'q13-planting-bomb))
   :condition all-complete
   :on-activate (fi-interact)

   (:interaction fi-interact
    :interactable fi
    :title "Alex has betrayed us."
    :dialogue "
~ fi
| (:unsure)Alex has... betrayed us? What do you mean?
~ player
| I found them in Wraw territory. They told them our location.
~ fi
| (:unsure)...
? (not (complete-p 'q11a-bomb-recipe))
| ~ jack
| | (:annoyed)Why didn't ya put 'em outta their misery when you had the chance?! Who knows what else they've told them.
| ~ player
| - In cold blood?
|   ~ jack
|   | (:annoyed)Androids don't have blood.
|   ~ fi
|   | (:annoyed)I beg to differ, Jack.
| - I'm not a killer.
|   ~ jack
|   | (:annoyed)Oh really? What's your body count since you woke up?
|   | (:normal)I bet you've lost count.
|   | (:annoyed)Not to mention all those you killed before the Calamity.
|   ~ fi
|   | {(nametag player)} has helped and defended us. (:annoyed)And I won't hear your superstitions!
|   ~ jack
|   | (:annoyed)...
| - Maybe you're right.
|   ~ jack
|   | (:shocked)...
|   ~ fi
|   | (:annoyed)No, I don't think he is.
| ~ fi
| | It was better to know about Alex sooner rather than later. At least we know what we're up against.
| | Thank you, {(nametag player)}.
|?
| ~ fi
| | (:unsure)I don't know what to say.
| | (:normal)At least with Alex we know what we're up against.
| | Thank you for telling me, {(nametag player)}.
")))
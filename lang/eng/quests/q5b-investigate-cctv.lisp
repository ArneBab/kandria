;; -*- mode: poly-dialog; -*-
(in-package #:org.shirakumo.fraf.kandria)

(quest:define-quest (kandria q5b-investigate-cctv)
  :author "Tim White"
  :title "Investigate CCTV"
  :description "The Semi Sisters' CCTV cameras along their low-eastern border have gone down."
  :on-activate (q5b-task-reminder q5b-task-cctv-1 q5b-task-cctv-2 q5b-task-cctv-3 q5b-task-cctv-4)
  :variables (first-cctv)
 
 
 (q5b-task-reminder
   :title NIL
   :visible NIL
   :on-activate T
   (:interaction q5b-reminder
    :title "Remind me about the downed CCTV cameras."
    :interactable innis
    :repeatable T
    :dialogue "
~ innis
? (complete-p 'q5b-task-cctv-1 'q5b-task-cctv-2 'q5b-task-cctv-3 'q5b-task-cctv-4)
| ? (not (complete-p 'q5b-boss))
| | | You might've found all the CCTV sites, but I want you to \"bring me back that saboteur from the low-eastern region\"(orange).
|?
| ? (complete-p 'q5b-boss)
| | | Go to the \"low-eastern region\"(orange) along the Cerebat border, and \"investigate the remaining downed CCTV cameras\"(orange).
| | | Then \"return to me\"(orange). Hopefully you won't encounter any more saboteurs.
| |? (active-p 'q5b-boss)
| | | Go to the \"low-eastern region\"(orange) along the Cerebat border, and \"investigate the remaining downed CCTV cameras\"(orange).
| | | And dinnae forget to \"bring me back that saboteur\"(orange).
| |?
| | | Go to the \"low-eastern region\"(orange) along the Cerebat border, and \"find out what's wrong with the 4 downed CCTV cameras\"(orange).
| | | Then \"return to me\"(orange).
"))
;; dinnae = don't (Scottish)

;; NARRATIVE: the saboteur has been destroying the cameras in ways to avoid arousing suspicion, so they seem like electrical fires, poor maintenance, etc. However, by the fourth one, once the sabotage is clearly known, it recasts these descriptions of damage as likely sabotage.
  (q5b-task-cctv-1
   :title "Find CCTV camera 1"
   :marker '(cctv-1-mark 1000)
   :condition all-complete
   :on-activate T   
   (:interaction q5b-cctv-1
    :interactable cctv-1
    :dialogue "
~ player
| \"Here's \"CCTV camera 1\"(red).\"(light-gray, italic)
| \"The lens is smashed and the casing is charred from a fire.\"(light-gray, italic)
? (complete-p 'q5b-task-cctv-2 'q5b-task-cctv-3 'q5b-task-cctv-4)
| ? (complete-p 'q5b-boss)
| | | (:normal)\"That was the last of the downed cameras. I should \"return to Innis\"(orange) and report on the saboteur.\"(light-gray, italic)
| | ! eval (deactivate 'q5b-task-reminder)
| | ! eval (activate 'q5b-task-return-cctv)
| |?
| | | (:normal)\"That was the last downed camera. But I still need to \"find the saboteur in the low-eastern area\"(orange), before I \"return to Innis\"(orange).\"(light-gray, italic)
|? (not (var 'first-cctv))
| | (:normal)\"This doesn't bode well. I need to \"find the other CCTV sites\"(orange), as recorded in my \"Log Files\"(orange) and on my \"Map\"(orange).\"(light-gray, italic)
| ! eval (setf (var 'first-cctv) T)
"))

  (q5b-task-cctv-2
   :title "Find CCTV camera 2"
   :marker '(cctv-2-mark 1000)
   :condition all-complete
   :on-activate T   
   (:interaction q5b-cctv-2
    :interactable cctv-2
    :dialogue "
~ player
| \"Here's \"CCTV camera 2\"(red).\"(light-gray, italic)
| \"The outer case is missing - it's on the ground beneath the camera. It looks like moisture has shorted out the circuit boards.\"(light-gray, italic)
? (complete-p 'q5b-task-cctv-1 'q5b-task-cctv-3 'q5b-task-cctv-4)
| ? (complete-p 'q5b-boss)
| | | (:normal)\"That was the last of the downed cameras. I should \"return to Innis\"(orange) and report on the saboteur.\"(light-gray, italic)
| | ! eval (deactivate 'q5b-task-reminder)
| | ! eval (activate 'q5b-task-return-cctv)
| |?
| | | (:normal)\"That was the last downed camera. But I still need to \"find the saboteur in the low-eastern area\"(orange), before I \"return to Innis\"(orange).\"(light-gray, italic)
|? (not (var 'first-cctv))
| | (:normal)\"This doesn't bode well. I need to \"find the other CCTV sites\"(orange), as recorded in my \"Log Files\"(orange) and on my \"Map\"(orange).\"(light-gray, italic)
| ! eval (setf (var 'first-cctv) T)
"))

  (q5b-task-cctv-3
   :title "Find CCTV camera 3"
   :marker '(cctv-3-mark 1000)
   :condition all-complete
   :on-activate T   
   (:interaction q5b-cctv-3
    :interactable cctv-3
    :dialogue "
~ player
| \"Here's \"CCTV camera 3\"(red).\"(light-gray, italic)
| \"It's in pieces on the floor, surrounded by rocks and stones.\"(light-gray, italic)
? (complete-p 'q5b-task-cctv-1 'q5b-task-cctv-2 'q5b-task-cctv-4)
| ? (complete-p 'q5b-boss)
| | | (:normal)\"That was the last of the downed cameras. I should \"return to Innis\"(orange) and report on the saboteur.\"(light-gray, italic)
| | ! eval (deactivate 'q5b-task-reminder)
| | ! eval (activate 'q5b-task-return-cctv)
| |?
| | | (:normal)\"That was the last downed camera. But I still need to \"find the saboteur in the low-eastern area\"(orange), before I \"return to Innis\"(orange).\"(light-gray, italic)
|? (not (var 'first-cctv))
| | (:normal)\"This doesn't bode well. I need to \"find the other CCTV sites\"(orange), as recorded in my \"Log Files\"(orange) and on my \"Map\"(orange).\"(light-gray, italic)
| ! eval (setf (var 'first-cctv) T)
"))

  (q5b-task-cctv-4
   :title "Find CCTV camera 4"
   :marker '(cctv-4-mark 1000)
   :condition all-complete
   :on-activate T   
   (:interaction q5b-cctv-4
    :interactable cctv-4
    :dialogue "
~ player
| \"Here's \"CCTV camera 4\"(red).\"(light-gray, italic)
| (:thinking)\"The wiring has been cut, but otherwise it seems in good working order.\"(light-gray, italic)
| (:skeptical)\"But without the others daisy-chained in sequence, it still wouldn't work.\"(light-gray, italic)
| (:normal)\"I should tell Innis about the cut wires. Accessing FFCS protocols...\"(light-gray, italic)
| Hello, Innis.
~ innis
| (:angry)You! How did you reach me?...
| (:sly)This is an FFCS broadcast, isn't it. Clever android.
| (:angry)Look, now isn't a good time. What do you want?
~ player
- This is important.
  ~ innis
  | (:angry)It'd better be. Get on with it then.
- Sorry to interrupt.
  ~ innis
  | (:angry)I'll accept that apology if you have something useful to say.
- How do you know about FFCS?
  ~ innis
  | (:sly)I wouldnae have been very good at my old job if I didnae ken it.
~ player
| The power line to one of the cameras has been cut by hand.
~ innis
| (:angry)Then we have a \"saboteur\"(orange). (:sly)Maybe a sly Cerebat spy, watching you right now.
| (:angry)\"Find them and bring them to me.\"(orange)
! eval (activate 'q5b-boss)
~ player
? (complete-p 'q5b-task-cctv-1 'q5b-task-cctv-2 'q5b-task-cctv-3)
| | (:normal)\"That was also the last of the downed cameras. I should \"find the nearby saboteur and then return to Innis\"(orange).\"(light-gray, italic)
|? (not (var 'first-cctv))
| | (:normal)\"I also need to \"find the other CCTV sites\"(orange), as recorded in my \"Log Files\"(orange) and on my \"Map\"(orange).\"(light-gray, italic)
| ! eval (setf (var 'first-cctv) T)
"))
;; wouldnae = wouldn't (Scottish)
;; didnae = didn't (Scottish)
;; ken = know (Scottish)

  (q5b-task-return-cctv
   :title "Return to Innis in the Semi Sisters control room to discuss the saboteur"
   :marker '(innis 500)
   :condition all-complete
   :on-activate T
   (:interaction q5b-return-cctv
    :title "(Report on the sabotaged CCTV)"
    :interactable innis
    :dialogue "
~ innis
| (:pleased)I'm glad you survived.
| (:sly)So what are we dealing with?
~ player
- It was a big, badass robot.
  ~ innis
  | ... That's no' something the Cerebats would use.
- I don't know. It's in pieces if you want to go look.
  ~ innis
  | The Cerebats dinnae use robots. And no thank you.
- Do the Cerebats use robots?
  ~ innis
  | No.
~ innis
| (:thinking)They also dinnae make aggressive moves like crossing our border.
| ...
| (:angry)I think we might have a problem. A mutual problem:
| The Wraw.
| There've been other signs lately. Islay warned me about this.
| Fuck.
| ...
| (:normal)I need to speak with my sister.
? (complete-p 'q5a-rescue-engineers)
| ~ innis
| | Perhaps you should \"return to Fi\"(orange).
| | It's a pity you couldnae persuade Alex to come home. (:sly)I'd love to see the look on Fi's face when you tell her.
| | I suppose androids cannae do everything.
| | (:angry)And tell her we want Catherine back too. We need her now more than ever.
| | (:sly)If she disagrees tell her I'll shut the water off.
| ! eval (activate 'q6-return-to-fi)
| ! eval (activate (unit 'fi-ffcs-1))
| ! eval (activate (unit 'fi-ffcs-2))
")))
;; couldnae = couldn't (Scots)
;; dinnae = don't (Scottish)

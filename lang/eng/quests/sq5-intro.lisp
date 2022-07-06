;; -*- mode: poly-dialog; -*-
(in-package #:org.shirakumo.fraf.kandria)

;; Semi Sisters barkeep, non-binary, French code switching from time to time
;; semi-patron-1 - sober, female
;; semi-patron-2 - drunk, female
;; ambiguous whether this is an alcoholic drink or not, as in q5-intro player can choose that they don't drink alcohol if they prefer
(quest:define-quest (kandria sq5-intro)
  :author "Tim White"
  :visible NIL
  :title NIL
  :on-activate T
  :variables (lost-bet-1 lost-bet-2)

  (intro
   :title NIL
   :invariant (not (complete-p 'q10-wraw))
   :condition NIL
   :on-activate T

   (:interaction intro-chat
    :interactable semi-barkeep
    :repeatable T
    :dialogue "
! eval (setf (nametag (unit 'semi-barkeep)) (@ semi-barkeep-nametag))
! eval (setf (nametag (unit 'semi-patron-1)) (@ semi-patron-1-nametag))
! eval (setf (nametag (unit 'semi-patron-2)) (@ semi-patron-2-nametag))
~ semi-barkeep
| Salut, {(nametag player)}.
| I was hoping you might stop by. This lot have too much time on their hands, as you can see.
| You fancy bringing a bit of sparkle to this establishment? I'm talking about \"time trials\"(orange).
~ player
- Let's hear it.
- I'll be going.
  < leave
~ semi-barkeep
| First, can I interest you in a beverage? On the house, of course.
! label choice
~ player
- Hit me.
  ~ semi-patron-1
  | So androids //can// drink. You owe me fifty.
  ~ semi-patron-2
  | Dammit, android. But you don't //drink// drink, do you? <-Hic->.
  ~ semi-patron-1
  | Don't get technical, mate. If the android drinks it, it counts.
  ~ player
  | (:embarassed)\"They're waiting to see what I'll do. I am designed to drink.\"(light-gray, italic)
  | \"But do I want to, now everyone is staring at me?\"(light-gray, italic)
  - (Drink it)
    ~ semi-patron-1
    | Boom! Fifty scrap parts, thank you very much.
    ~ semi-patron-2
    | Ah, shit. Take it.
    ~ player
    | Yep, that tasted like diesel mixed with seaweed.
    ! eval (setf (var 'lost-bet-2) T)
  - (Leave it)
    ~ semi-patron-2
    | Looks like you owe me, matey.
    ~ semi-patron-1
    | Screw you, android.
    ! eval (setf (var 'lost-bet-1) T)
- No thanks.
  ~ semi-barkeep
  | As you wish.
- You're smooth.
  ~ semi-barkeep
  | Merci beaucoup. It does help in this line of work.
  | So, about that drink? Though I can't promise it will be as smooth.
  < choice
- I'll be going.
  < leave
~ semi-barkeep
| As I was saying, life here can get a little... //stale//. For those of us not favoured by our esteemed leaders, at least.
| We have a //good// life, as you can see - by post-Calamity standards, of course. But not a lot happens around here.
| So when an android arrives, people take notice.
~ semi-patron-2
| Get to the point, will ya? <-Hic->. The android ain't got all day.
? (var 'lost-bet-2)
| | And neither have I if I'm gonna win my money back.
|? (var 'lost-bet-1)
| ~ semi-patron-1
| | Neither have I if I'm gonna win my money back.
  
~ semi-barkeep
| Hold your horses! All in good time.
| So it goes like this: We train our best hunters by sending them out on \"patrol to retrieve a unique item\"(orange). And we \"time them\"(orange).
| We want you to see if - or rather //when// - you can \"beat their times\"(orange).
| We'll run a sweepstake, and give you a \"cut of the winnings - you'll get more the faster you are\"(orange).
| Let's see... We've got some \"broken Genera cores\"(orange) lying around. These will do nicely.
| The hunters can \"plant them far and wide\"(orange) - around our territory, and perhaps even beyond.
| \"Let me know if you want in\"(orange). In the meantime, I'll try organise this motley crew and take some bets.
! eval (activate 'sq5-race)
! eval (complete task)
! eval (reset* interaction)
! label leave
~ semi-barkeep
| Allez, salut. Don't stay away too long.
")))
;; mate = friend, in this context
;; don't mention Catherine by name here, as it could spoiler the later mainline reveal of Catherine previously being part of the Semis
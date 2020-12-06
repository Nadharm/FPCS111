;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname adventure) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
(require "adventure-define-struct.rkt")
(require "macros.rkt")
(require "utilities.rkt")

;;;
;;; OBJECT
;;; Base type for all in-game objects
;;;

(define-struct object
  ;; adjectives: (listof string)
  ;; List of adjectives to be printed in the description of this object
  (adjectives)
  
  #:methods
  ;; noun: object -> string
  ;; Returns the noun to use to describe this object.
  (define (noun o)
    (type-name-string o))

  ;; description-word-list: object -> (listof string)
  ;; The description of the object as a list of individual
  ;; words, e.g. '("a" "red" "door").
  (define (description-word-list o)
    (cons "the" (append (object-adjectives o)
                        (remove "room" (list (noun o))))))
  ;; description: object -> string
  ;; Generates a description of the object as a noun phrase, e.g. "a red door".
  (define (description o)
    (words->string (description-word-list o)))
  
  ;; print-description: object -> void
  ;; EFFECT: Prints the description of the object.
  (define (print-description o)
    (begin (printf (description o))
           (newline)
           (void))))

;;;
;;; CONTAINER
;;; Base type for all game objects that can hold things
;;;

(define-struct (container object)
  ;; contents: (listof thing)
  ;; List of things presently in this container
  (contents)
  
  #:methods
  ;; container-accessible-contents: container -> (listof thing)
  ;; Returns the objects from the container that would be accessible to the player.
  ;; By default, this is all the objects.  But if you want to implement locked boxes,
  ;; rooms without light, etc., you can redefine this to withhold the contents under
  ;; whatever conditions you like.
  (define (container-accessible-contents c)
    (container-contents c))
  
  ;; prepare-to-remove!: container thing -> void
  ;; Called by move when preparing to move thing out of
  ;; this container.  Normally, this does nothing, but
  ;; if you want to prevent the object from being moved,
  ;; you can throw an exception here.
  (define (prepare-to-remove! container thing)
    (void))
  
  ;; prepare-to-add!: container thing -> void
  ;; Called by move when preparing to move thing into
  ;; this container.  Normally, this does nothing, but
  ;; if you want to prevent the object from being moved,
  ;; you can throw an exception here.
  (define (prepare-to-add! container thing)
    (void))
  
  ;; remove!: container thing -> void
  ;; EFFECT: removes the thing from the container
  (define (remove! container thing)
    (set-container-contents! container
                             (remove thing
                                     (container-contents container))))
  
  ;; add!: container thing -> void
  ;; EFFECT: adds the thing to the container.  Does not update the thing's location.
  (define (add! container thing)
    (set-container-contents! container
                             (cons thing
                                   (container-contents container))))

  ;; describe-contents: container -> void
  ;; EFFECT: prints the contents of the container
  (define (describe-contents container)
    (begin (local [(define other-stuff (remove me (container-accessible-contents container)))]
             (if (empty? other-stuff)
                 (printf "There's nothing here.~%")
                 (begin (printf "You see:~%")
                        (for-each print-description other-stuff))))
           (void))))

;; move!: thing container -> void
;; Moves thing from its previous location to container.
;; EFFECT: updates location field of thing and contents
;; fields of both the new and old containers.
(define (move! thing new-container)
  (begin
    (prepare-to-remove! (thing-location thing)
                        thing)
    (prepare-to-add! new-container thing)
    (prepare-to-move! thing new-container)
    (remove! (thing-location thing)
             thing)
    (add! new-container thing)
    (set-thing-location! thing new-container)))

;; destroy!: thing -> void
;; EFFECT: removes thing from the game completely.
(define (destroy! thing)
  ; We just remove it from its current location
  ; without adding it anyplace else.
  (remove! (thing-location thing)
           thing))


;;;
;;; ROOM
;;; Base type for rooms and outdoor areas
;;;

(define-struct (room container)
  ())

;; new-room: string -> room
;; Makes a new room with the specified adjectives
(define (new-room adjectives)
  (make-room (string->words adjectives)
             '()))

;;;
;;; THING
;;; Base type for all physical objects that can be inside other objects such as rooms
;;;

(define-struct (thing container)
  ;; location: container
  ;; What room or other container this thing is presently located in.
  (location)
  
  #:methods
  (define (examine thing)
    (print-description thing))

  ;;eat -> lets you know that you can't eat a thing unless it's a food
  (define (eat thing)
    (display-line "You can't eat this. It is inedible."))

  (define (attack! thing person)
    (display-line "You can't attack that. Why would you even want to?"))

  (define (drink thing)
    (display-line "You can't drink that. Sorry!"))

  (define (solve! thing answer)
    (display-line "There's nothing to solve here??"))

  (define (activate! thing)
    (display-line "You can't activate this... seriously what are you trying to do?"))

  (define (equip! thing person)
    (display-line "You cannot equip this, sorry!"))

  
  ;; prepare-to-move!: thing container -> void
  ;; Called by move when preparing to move thing into
  ;; container.  Normally, this does nothing, but
  ;; if you want to prevent the object from being moved,
  ;; you can throw an exception here.
  (define (prepare-to-move! container thing)
    (void)))

;; initialize-thing!: thing -> void
;; EFFECT: adds thing to its initial location
(define (initialize-thing! thing)(add! (thing-location thing)
                                       thing))

;; new-thing: string container -> thing
;; Makes a new thing with the specified adjectives, in the specified location,
;; and initializes it.
(define (new-thing adjectives location)
  (local [(define thing (make-thing (string->words adjectives)
                                    '() location))]
    (begin (initialize-thing! thing)
           thing)))


;;;
;;; DOOR
;;; A portal from one room to another
;;; To join two rooms, you need two door objects, one in each room
;;;

(define-struct (door thing)
  ;; destination: container
  ;; The place this door leads to
  (destination)
  
  #:methods
  ;; go: door -> void
  ;; EFFECT: Moves the player to the door's location and (look)s around.
  (define (go door)
    (begin (move! me (door-destination door))
           (look)))

  (define (take door)
    (print "You can't take that!")))

;; join: room string room string
;; EFFECT: makes a pair of doors with the specified adjectives
;; connecting the specified rooms.
(define (join! room1 adjectives1 room2 adjectives2)
  (local [(define r1->r2 (make-door (string->words adjectives1)
                                    '() room1 room2))
          (define r2->r1 (make-door (string->words adjectives2)
                                    '() room2 room1))]
    (begin (initialize-thing! r1->r2)
           (initialize-thing! r2->r1)
           (void))))

;;;
;;; PERSON
;;; A character in the game.  The player character is a person.
;;;

(define-struct (person thing)
  (calorie-count health defense equipped-weapon)


  #:methods

  (define (take person)
    (print "You can't take that!"))

  ;;check-calories -> checks how many calories the peprson has
  (define (check-calories! person)
    (if (> (person-calorie-count person) 2500)
        (display-line "You are full!")
        (display-line (+ (person-calorie-count person) 0))))

  ;;check-health -> checks how much HP player has
  (define (check-health! person)
    (if (> (person-health person) 100)
        (display-line "You are completly healthy.")
        (display-line (+ (person-health person) 0))))

  ;;check-defense -> defense value
  (define (check-defense! person)
    (display-line (person-defense person)))

  ;;check-equipped-weapon -> what weapon are you holding?
  (define (check-equipped-weapon! person)
    (if (string? (person-equipped-weapon person))
        (display-line "You are currently equipping nothing! You might want to find a weapon! Quick!!!!")
        (begin (display-line "You are currently equipping: ")
               (display-line (prop-noun-to-print (person-equipped-weapon person))))))

  ;; equip! -> equips weapon if in inventory
  (define (equip! weapon person)
    (if (have? weapon)
        (begin (set-person-equipped-weapon! person weapon)
               (display-line "Weapon equipped!"))
        (display-line "I don't have that weapon!")))

  ;; dead? -> check if player is dead
  (define (dead? person)
    (if (< (person-health person) 1)
        (begin (display-line "Oh no! It looks like you've died!")
               #t)
        #f))

  ;; attack -> fighting 
  (define (attack! enemy person)
    (if (string? (person-equipped-weapon person))
        (display-line "Whoa! Find and equip a weapon first! You don't want to touch that with your bare hands!")
        (if (eq? (thing-location enemy)
                 (thing-location person))
            (local[(define (attack-helper person ps enemy es)
                     (if (> ps es)
                         (begin (set-enemy-health! enemy
                                                   (- (enemy-health enemy)
                                                      (weapon-damage (person-equipped-weapon person))))
                                (display-line "Your speed allows you to get a free shot at the enemy!")
                                (printf "You deal ~a damage to ~a."
                                        (weapon-damage (person-equipped-weapon person))
                                        (enemy-name enemy))
                                (set-weapon-durability! (person-equipped-weapon person)
                                                                (- (weapon-durability (person-equipped-weapon person)) 1))
                                (display-line "")
                                (display-line "")
                                (if (dead? enemy)
                                    (begin (remove! (thing-location enemy) enemy)
                                           (if (broken? (person-equipped-weapon person))
                                               (begin (display-line "Your weapon broke just as you killed the beast!")
                                                      (set-person-equipped-weapon! person "Nothing"))
                                               #f)
                                           (void))
                                    (if (broken? (person-equipped-weapon person))
                                        (begin (display-line "Oh no! Your weapon has broken! RUN!")
                                               (set-person-equipped-weapon! person "Nothing"))
                                        (attack-helper person (- ps 1) enemy es))))
                         (if (< ps es)
                             (begin (set-person-health! person
                                                        (- (person-health person)
                                                           (round (* (enemy-attack-damage enemy)
                                                              (- 1 (person-defense person))))))
                                    (display-line "The enemy was too quick for you and damaged you!")
                                    (printf "You take ~a damage from ~a."
                                            (round (* (enemy-attack-damage enemy)
                                               (- 1 (person-defense person))))
                                            (enemy-name enemy))
                                    (display-line "")
                                    (display-line "")
                                    (if (dead? person)
                                        ;; TO DO ONCE WE FINISH GAME
                                        (display-line "INSERT END GAME")
                                        (attack-helper person ps enemy (- es 1))))
                             (if (= ps es)
                                 (begin (set-enemy-health! enemy
                                                           (- (enemy-health enemy)
                                                              (weapon-damage (person-equipped-weapon person))))
                                        (set-weapon-durability! (person-equipped-weapon person)
                                                                (- (weapon-durability (person-equipped-weapon person)) 1))
                                        (set-person-health! person
                                                            (- (person-health person)
                                                               (round (* (enemy-attack-damage enemy)
                                                                  (- 1 (person-defense person))))))
                                        (display-line "You both attack each other simultaneously")
                                        (printf "You deal ~a damage to ~a."
                                                (weapon-damage (person-equipped-weapon person))
                                                (enemy-name enemy))
                                        (display-line "")
                                        (printf "You take ~a damage from ~a."
                                                (round (* (enemy-attack-damage enemy)
                                                   (- 1 (person-defense person))))
                                                (enemy-name enemy))
                                        (display-line "")
                                        (display-line "")
                                        (if (dead? person)
                                            ;;TO DO
                                            (display-line "INSERT END GAME")
                                            (if (dead? enemy)
                                                (begin (remove! (thing-location enemy) enemy)
                                                       (if (broken? (person-equipped-weapon person))
                                                           (begin (display-line "Your weapon broke just as you killed the beast!")
                                                                  (set-person-equipped-weapon! person "Nothing"))
                                                           #f)
                                                       (void))
                                                (if (= ps 0)
                                                    (begin (display-line "You separate yourself from the enemy giving you time to think.")
                                                           (if (broken? (person-equipped-weapon person))
                                                               (begin (display-line "Your weapon broke just as you escaped!")
                                                                      (set-person-equipped-weapon! person "Nothing"))
                                                               #f)
                                                           (printf "You have ~a health points left. "
                                                                   (person-health person))
                                                           (display-line "")
                                                           (printf "~a has ~a health points left. "
                                                                   (enemy-name enemy)
                                                                   (enemy-health enemy)))
                                                    (if (broken? (person-equipped-weapon person))
                                                        (begin (display-line "Your weapon has broken! RUN!!!")
                                                               (set-person-equipped-weapon! person "Nothing"))
                                                        (attack-helper person (- ps 1) enemy (- es 1))))))
                                        )
                                 (display-line "something odd must be going on...")))))]
              (attack-helper person
                             (weapon-speed (person-equipped-weapon person))
                             enemy
                             (enemy-attack-speed enemy)))
            (display-line "That enemy is no where near me...")
            )))
  )


;; initialize-person: person -> void
;; EFFECT: do whatever initializations are necessary for persons.
(define (initialize-person! p)
  (initialize-thing! p))

;; new-person: string container -> person
;; Makes a new person object and initializes it.
(define (new-person adjectives location calorie-total hPoints)
  (local [(define person
            (make-person (string->words adjectives)
                         '()
                         location
                         0
                         100
                         0
                         "Nothing"))]
    
    (begin (initialize-person! person)
           person)))

;; This is the global variable that holds the person object representing
;; the player.  This gets reset by (start-game)
(define me empty)


;;;
;;; PROP
;;; A thing in the game that can be held by the person.
;;;

(define-struct (prop thing)
  (;; noun-to-print: string
   ;; The user can set the noun to print in the description so it doesn't just say "prop"
   noun-to-print
   ;; examine-text: string
   ;; Text to print if the player examines this object
   examine-text
   )
  
  #:methods
  (define (noun prop)
    (prop-noun-to-print prop))

  (define (examine prop)
    (display-line (prop-examine-text prop)))

  (define (take prop)
    (begin (move! prop me)
           (display-line "Item added to inventory.")))

  (define (drop prop)
    (move! prop (here)))

  (define (put prop container)
    (move! prop container)))

;; new-prop: string container -> prop
;; Makes a new prop with the specified description.
(define (new-prop description examine-text location)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define prop (make-prop adjectives '() location noun examine-text))]
    (begin (initialize-thing! prop)
           prop)))

;;;
;;; ADD YOUR TYPES HERE!
;;;

;;;
;;; ENEMY
;;; An NPC that the player can fight
;;;
  
(define-struct (enemy prop)
  (name health attack-damage attack-speed item)

  #:methods
  (define (dead? enemy)
    (if (< (enemy-health enemy) 0)
        (if (empty? (enemy-item enemy))
            (begin (display-line "It's dead! Finally! Too bad it had nothing of value to loot.")
                   #t)
            (begin (display-line "You've killed it! UwU? What's this? The enemy has dropped something!")
                   (move! (enemy-item enemy) (thing-location enemy))
                   #t)
            )
        #f))
  )

;;new-enemy -> the way to make new enemies
(define (new-enemy description examine-text location name health attack-damage attack-speed item)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define enemy (make-enemy adjectives
                                    '()
                                    location
                                    noun
                                    examine-text
                                    name
                                    health
                                    attack-damage
                                    attack-speed
                                    item))]
    (begin (initialize-thing! enemy)
           enemy)))

;;;
;;; STAIRS
;;; Like doors, but go between floors
;;;

(define-struct (stairs door)
  ()

  #:methods
  (define (take stairs)
    (print "You can't take that!")))

;; join-floors: room string room string
;; EFFECT: makes a flight of stairs with the specified adjectives
;; connecting the specified rooms.

(define (join-floors! room1 adjectives1 room2 adjectives2)
  (local [(define r1->r2 (make-stairs (string->words adjectives1)
                                      '() room1 room2))
          (define r2->r1 (make-stairs (string->words adjectives2)
                                      '() room2 room1))]
    (begin (initialize-thing! r1->r2)
           (initialize-thing! r2->r1)
           (void))))

;;;
;;; FURNITURE
;;; A thing that exists as decoration or to be sat on. I'm almost jealous.
;;;

(define-struct (furniture thing)
  (;; noun-to-print: string
   ;; The user can set the noun to print in the description so it doesn't just say "prop"
   noun-to-print
   ;; examine-text: string
   ;; Text to print if the player examines this object
   examine-text
   )
  
  #:methods
  (define (noun furniture)
    (furniture-noun-to-print furniture))

  (define (examine furniture)
    (display-line (furniture-examine-text furniture)))

  (define (take furniture)
    (print "You can't take that!")))

;; new-furniture: string container -> furniture
;; Makes a new piece of furniture with the specified description.
(define (new-furniture description examine-text location)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define furniture (make-furniture adjectives '() location noun examine-text))]
    (begin (initialize-thing! furniture)
           furniture)))

;;;
;;; FOOD
;;; A thing that a person can eat!
;;;

(define-struct (food prop)
  (calories)
  
  #:methods
  (define (eat food)
    (calorie-accumulator food me))

  (define (calorie-accumulator food person)
    (if (> (person-calorie-count person) 2500)
        (display-line "You can't eat anymore. You are full!")
        (begin (destroy! food)
               (set-person-calorie-count! person (+ (person-calorie-count person) (food-calories food)))
               (display-line "Yum!")))))

;; new-food: string container -> food
;; Makes a new piece of food with the specified description.
(define (new-food description examine-text location calorie)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define food (make-food adjectives '() location noun examine-text calorie))]
    (begin (initialize-thing! food)
           food)))

;;;
;;; POTION
;;; A thing that grants the user HP
;;;

(define-struct (potion prop)
  (hpoints)

  #:methods
  (define (drink potion)
    (drink-accumulator potion me))

  (define (drink-accumulator potion person)
    (if (>= (person-health person) 100)
        (display-line "You can't drink this. You are full health.")
        (begin (destroy! potion)
               (set-person-health! person (+ (person-health person) (potion-hpoints potion)))
               (display-line "Very satisfying!")))))

;;new-potion
(define (new-potion description examine-text location hp)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define potion (make-potion adjectives '() location noun examine-text hp))]
    (begin (initialize-thing! potion)
           potion)))

;;;
;;; WEAPON
;;; A prop that is used to attack enemies.
;;;

(define-struct (weapon prop)
  (damage speed durability)

  #:methods
  (define (stats weapon)
    (begin (display-line "This weapons stats:")
           (printf "Damage: ~a" (weapon-damage weapon))
           (display-line "")
           (printf "Speed: ~a" (weapon-speed weapon))
           (display-line "")
           (printf "Durability: ~a" (weapon-durability weapon))))
  
  (define (broken? weapon)
    (if (< (weapon-durability weapon) 0)
        (begin (remove! (thing-location weapon) weapon)
               #t)
        #f)))


;;; new-weapon: string prop -> weapon
;;; Creates a new weapon with the specified description

(define (new-weapon description examine-text location damage speed durability)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define weapon (make-weapon adjectives '() location noun examine-text damage speed durability))]
    (begin (initialize-thing! weapon)
           weapon)))

;;;
;;; TOOL
;;; A weapon that has other uses around the house.
;;;

(define-struct (tool weapon)
  ())

;;; new-tool: string container -> weapon
;;; Creates a new tool with the specified description

(define (new-tool description examine-text location damage speed durability)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define tool (make-tool adjectives '() location noun examine-text damage speed durability))]
    (begin (initialize-thing! tool)
           tool))) 

;;;
;;; ARMOR
;;; A prop that takes damage for the player without losing health
;;;

(define-struct (armor prop)
  (armor-value))

;;;
;;; new-armor: string container -> weapon
;;; Creates a new armor with the specified description

(define (new-armor description examine-text location armor-value)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define armor (make-armor adjectives '() location noun examine-text armor-value))]
    (begin (initialize-thing! armor)
           armor)))


;;;
;;; PUZZLE
;;; A puzzle that the player will solve to advance in the game
;;;

(define-struct (puzzle prop)
  (;; question-text: string
   ;; This is the question that the player must answer
   question-text
   ;; solution-text: string
   ;; This is the solution to the puzzle/question
   solution-text
   ;; prize: unknown
   prize
   )
  #:methods
  ;; question: get the question-text
  (define (question puzzle)
    (puzzle-question-text puzzle))
  ;; solution: get the solution-text
  (define (solution puzzle)
    (puzzle-solution-text puzzle))
  ;; activate!: activate the puzzle
  (define (activate! puzzle)
    (begin (display-line "use the solve! function to input answer")
           (display-line (question puzzle))
           (void)))
  ;; solve!: solve the puzzle
  (define (solve! puzzle answer)
    (if (string? answer)
        (if (string=? answer
                      (solution puzzle))
            (begin (display-line "Wow! Well done!")
                   (move! (puzzle-prize puzzle) me)
                   (display-line "Your prize has been added to your inventory!")
                   )
            (display-line "Sorry! That was incorrect. Maybe try inputting the correct answer?")
            )
        (display-line "Sorry, you'll need to enter an answer in the form of a string")
        )
    ))

;; new-puzzle: creates new puzzles
(define (new-puzzle description examine-text location question solution prize)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define puzzle (make-puzzle adjectives '() location noun examine-text question solution prize))]
    (begin (initialize-thing! puzzle)
           puzzle)))




;;;
;;; LOCKED DOOR
;;; A door that joins together two rooms, but its initial state is locked.
;;;

(define-struct (locked-door door)
  (key)

  #:methods
  (define (go door)
    (if (have? (locked-door-key door))
        (begin (move! me (door-destination door))
               (look))
        (print "You need the key to unlock this door!"))))

(define (join-locked-door! room1 adjectives1 room2 adjectives2 key)
  (local [(define r1->r2 (make-locked-door (string->words adjectives1)
                                           '() room1 room2 key))
          (define r2->r1 (make-locked-door (string->words adjectives2)
                                           '() room2 room1 key))]
    (begin (initialize-thing! r1->r2)
           (initialize-thing! r2->r1)
           (void))))

;;;
;;; CUP
;;; A cup.
;;;

(define-struct (cup prop)
  ())

(define (filler cup person)
  (if (and (have? cup)
           (eq? (thing-location person) (thing-location (the toilet))))
      (begin (print "You fill your cup with toilet water.")
             (new-cup "cup of water"
                      "A cup full of toilet water"
                      me)
             (destroy! cup))
      (print "You can't do that!")))

(define (fill cup)
  (filler cup me))
  

;; Makes a new cup with the specified description.
(define (new-cup description examine-text location)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define cup (make-cup adjectives '() location noun examine-text))]
    (begin (initialize-thing! cup)
           cup)))

;;;
;;; FIREPLACE
;;; A raging fire, consuming everything in reach!
;;;
(define-struct (fireplace prop)
  (item)
  
  #:methods
   (define (douse fireplace)
    (if (have? (the cup of water))
        (begin (display-line "You douse the fire with a cup of toilet water. You reach into the charred wood and retrieve a half burnt picture.")
               (display-line "It's an old picture of middle-aged man. On the bottom, someone has written 'I'm sorry, John'.")
               (display-line "You also find a key labeled 'cellar' in the burnt remains. It looks to be damaged; hope it still works.")
               (destroy! (the cup of water))
               (new-prop "picture"
                         "A picture of a man named John. I wonder what happened to him."
                         me)
               (move! (fireplace-item fireplace) me)) 
        (print "You don't have the means to douse the fire!"))))

(define (new-fireplace description examine-text location key)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define fireplace (make-fireplace adjectives '() location noun examine-text key))]
    (begin (initialize-thing! fireplace)
           fireplace)))
;;;
;;; USER COMMANDS
;;;

(define (look)
  (begin (printf "You are in ~A.~%"
                 (description (here)))
         (describe-contents (here))
         (void)))

(define-user-command (look) "Prints what you can see in the room")

(define (inventory)
  (if (empty? (my-inventory))
      (printf "You don't have anything.~%")
      (begin (printf "You have:~%")
             (for-each print-description (my-inventory)))))

(define-user-command (inventory)
  "Prints the things you are carrying with you.")

(define-user-command (examine thing)
  "Takes a closer look at the thing")

(define-user-command (take prop)
  "Moves prop to your inventory")

(define-user-command (drop prop)
  "Removes prop from your inventory and places it in the room")


(define-user-command (put prop container)
  "Moves the prop from its current location and puts it in the container.")

(define (help)
  (for-each (λ (command-info)
              (begin (display (first command-info))
                     (newline)
                     (display (second command-info))
                     (newline)
                     (newline)))
            (all-user-commands)))

(define-user-command (help)
  "Displays this help information")

(define-user-command (go door)
  "Go through the door to its destination")

(define (check condition)
  (if condition
      (display-line "Check succeeded")
      (error "Check failed!!!")))

(define-user-command (check condition)
  "Throws an exception if condition is false.")

;;;
;;; ADD YOUR COMMANDS HERE!
;;;

;;food
(define-user-command (eat food person)
  "Satiates the person.")

(define (check-calories)
  (check-calories! me))

;;checking-calories
(define-user-command (check-calories)
  "Checks how many calories that person has. Max of 2500.")



(define (attack enemy)
  (attack! enemy me))

(define-user-command (attack enemy)
  "This will attack the enemy")

(define (equip weapon)
  (equip! weapon me))

(define-user-command (equip weapon)
  "This will equip a weapon")

(define (activate puzzle)
  (activate! puzzle))

(define-user-command (activate puzzle)
  "Use this to activate and read the puzzle")

(define (solve puzzle answer)
  (solve! puzzle answer))

(define-user-command (solve puzzle answer)
  "Use this to solve the puzzle. Input your answer as a string")

(define (check-health)
  (check-health! me))

(define-user-command (check-health)
  "View your health")

(define (check-equipped-weapon)
  (check-equipped-weapon! me))

(define-user-command (check-equipped-weapon)
  "View currently equipped weapon")

(define (check-defense)
  (check-defense! me))

(define-user-command (check-defense)
  "View defense stat")

(define-user-command (stats weapon)
  "View the stats of a weapon")



;;;
;;; ENDGAME CHECKS
;;; Checks at the end of the day how prepared the player is
;;;

(define (time-person?)
  "fill me in")

(define (weapons-person?)
  "fill me in")

(define (armour-person?)
  "fill me in")

(define (location-person?)
  "fill me in")

(define (enemies-house?)
  "fill me in")

(define (calories-person?)
  "fill me in")

(define (potions-person?)
  "fill me in")

(define (locked-house?)
  "fill me in")

(define (secured-house?)
  "fill me in")

(define (ammo-person?)
  "fill me in")

(define (success-person?)
  "fill me in")

;;;
;;; THE GAME WORLD - FILL ME IN
;;;

;; start-game: -> void
;; Recreate the player object and all the rooms and things.
(define (start-game)
  ;; Fill this in with the rooms you want
  (local [(define room-0 (new-room "outside"))
          (define room-1 (new-room "lobby"))
          (define room-2 (new-room "living-room"))
          (define room-3 (new-room "kitchen"))
          (define room-4 (new-room "dining-room"))
          (define room-5 (new-room "piano-room"))
          (define room-6 (new-room "bathroom"))
          (define room-7 (new-room "hallway"))
          (define room-8 (new-room "master-bedroom"))
          (define room-9 (new-room "guest-room"))
          (define room-10 (new-room "storage"))
          (define room-11 (new-room "study"))
          (define room-12 (new-room "balcony"))
          (define room-13 (new-room "basement"))
          (define room-14 (new-room "chamber"))
          (define room-15 (new-room "cellar"))
          (define room-16 (new-room "backyard"))
          (define room-17 (new-room "shed"))

          ;;This will be room for prize items and drops 
          (define room-100 (new-room "limbo"))
    
          ;; Setting up keys
          (define master-bedroom-key (new-prop "master-bedroom-key"
                                               "A key to the master bedroom on the second floor."
                                               room-100))
          (define study-key (new-prop "study-key"
                                      "A key to the study on the second floor."
                                      room-100))
          (define cellar-key (new-prop "cellar-key"
                                       "A mysterious, rusty key. It looks like it's been damaged."
                                       room-100))
          (define shed-key (new-prop "shed-key"
                                     "A key to the shed outside."
                                     room-11))
          (define outside-key (new-prop "outside key"
                                      "A key into the lobby"
                                      room-100))]
    
    ;; Add join commands to connect your rooms with doors
    (begin (set! me (new-person "" room-1 0 100))
           (join-locked-door! room-0 "lobby"
                              room-1 "outside"
                              outside-key)
           (join! room-1 "living-room"
                  room-2 "lobby")
           (join! room-1 "piano-room"
                  room-5 "lobby")
           (join! room-2 "kitchen"
                  room-3 "living-room")
           (join! room-3 "dining-room"
                  room-4 "kitchen")
           (join! room-4 "piano-room"
                  room-5 "dining-room")
           (join! room-5 "bathroom"
                  room-6 "piano-room")
           (join-floors! room-1 "lobby"
                         room-7 "hallway")
           (join-locked-door! room-7 "master-bedroom"
                              room-8 "hallway"
                              master-bedroom-key)
           (join! room-7 "guest-room"
                  room-9 "hallway")
           (join! room-7 "storage"
                  room-10 "hallway")
           (join-locked-door! room-7 "study"
                              room-11 "hallway"
                              study-key)
           (join! room-7 "balcony"
                  room-12 "hallway")
           (join-floors! room-5 "piano-room"
                         room-13 "basement")
           (join! room-13 "chamber"
                  room-14 "basement")
           (join-locked-door! room-14 "cellar"
                              room-15 "chamber"
                              cellar-key)
           (join! room-3 "backyard"
                  room-16 "kitchen")
           (join-locked-door! room-16 "shed"
                              room-17 "backyard"
                              shed-key)

           ;; Add code here to add things to your rooms
           
           ;;furniture/props
           (new-furniture "statue"
                          "It's just standing there. Menancingly..."
                          room-1)
           (new-furniture "piano"
                          "A rustic, old grand piano. Wonder if it still works."
                          room-5)
           (new-furniture "window"
                          "A beautiful day outside, besides the heavy downpour and wind."
                          room-5)
           (new-fireplace "fireplace"
                          "A raging fire illuminates the place. It looks like something is behind the flames, but it's too hot to reach past."
                          room-2
                          cellar-key)
           (new-cup "cup"
                     "A cup. I can't think of anything more to say about it."
                     room-4)
           (new-prop "painting"
                     "A large mural spanning across the wall. It's a horrible portrait of the zombie apocalypse, when it first broke out in 2023. Seems kind of tasteless."
                     room-2)
           (new-prop "corpse"
                     "The body of a man eaten alive, still gripping fervently to a machete."
                     room-1)
           (new-furniture "toilet"
                          "A device for transporting waste to a secret, underground facility."
                          room-6)
           
           ;;food
           (new-food "apple"
                     "A crunchy, red fruit. Healthy!"
                     room-3
                     100)
           (new-food "banana"
                     "A yellow, bedtime snack. Also healthy!"
                     room-8
                     125)
           (new-food "can of corn"
                     "Contains lots of fiber. Tons of healthy!"
                     room-4
                     250)
           (new-food "granola bar"
                     "Man's best snack. That's an objective fact."
                     room-10
                     200)
           (new-food "chocolate cake"
                     "A half-eaten cake, topped with glorious amounts of chocolate. Unhealthy, but filling!"
                     room-11
                     2000)
           
           
           ;;potions
           (new-potion "blue potion"
                       "A small potion - grants 20 health points."
                       room-10
                       20)
           (new-potion "red potion"
                       "A small potion - grants 20 health points."
                       room-8
                       20)
           (new-potion "green potion"
                       "A small potion - grants 20 health points."
                       room-15
                       20)
           (new-potion "gold potion"
                       "A big potion - grants 50 health points."
                       room-11
                       50)
           ;;tools
           (new-tool "hammer"
                     "A hammer. You could use it to fight, or to hammer some nails."
                     room-17
                     2
                     1
                     40)

           ;;Weapons
           (new-weapon "machete"
                       "There's a bit of rust on it... but it should hold up...?"
                       room-1
                       10
                       1
                       20)

           (new-weapon "knife"
                       "Why is this knife so big? Who needs a knife this big?!?"
                       room-3
                       8
                       3
                       60)

           (new-weapon "axe"
                       "A really shiny, new-looking axe."
                       room-17
                       15
                       2
                       100)

           ;;Enemies
           (new-enemy "zombie"
                      "It's looking at me funny..."
                      room-1
                      "Chad the Zombie"
                      50
                      2
                      3
                      '())
           
           (new-enemy "zombie"
                      "Strangely enough, it looks depressed, almost heartbroken."
                      room-15
                      "John"
                      70
                      3
                      3
                      outside-key)
                      

           ;;Puzzles
           (new-puzzle "mysterious box"
                       "The box is covered with dust. As you wipe away, you reveal a prompt."
                       room-9
                       "The year the world changed forever..."
                       "2023"
                       master-bedroom-key)
           (new-puzzle "safe"
                       "A safe is tucked away under the desk. It's a four-letter code combination."
                       room-8
                       "There's nothing on the safe that indicates what the word is, but I imagine it's pretty important"
                       "John"
                       study-key)
           
           (check-containers!)
           (void))))

;;; end-game -> void
;;; Runs the ending sequence to check if the player will survive the night.
(define (end-game)
  (begin (display-line "Your time has run out.")
         (display-line "Now it's time to see how you have done.")
         (display-line (string-append "Did you have weapons? " (weapons-person?)))
         (display-line (string-append "Did you have armour? " (armour-person?)))
         (display-line (string-append "Where did you spend the night? " (location-person?)))
         (display-line (string-append "Were there enemies in the house? " (enemies-house?)))
         (display-line (string-append "How many calories did you have? " (calories-person?)))
         (display-line (string-append "Did you take any potions? " (potions-person?)))
         (display-line (string-append "Did you lock all the doors? " (locked-house?)))
         (display-line (string-append "Did you secure the windows and doors? " (secured-house?)))
         (display-line (string-append "How much ammunition did you have? " (ammo-person?)))
         (display-line (string-append "How long did it take you to leave? " (time-person?)))
         (display-line (string-append "Grade: " (success-person?)))))


;;;
;;; PUT YOUR WALKTHROUGHS HERE
;;;

(define-walkthrough win
  (go (the piano-room door))
  (go (the dining-room door))
  (take (the cup))
  (go (the piano-room door))
  (go (the bathroom door))
  (fill (the cup))
  (go (the piano-room door))
  (go (the lobby door))
  (go (the living-room door))
  (examine (the painting))
  (douse (the fireplace))
  (go (the lobby door))
  (go (the lobby stairs))
  (go (the guest-room door))
  (solve! (the mysterious box) "2023")
  (go (the hallway door))
  (go (the master-bedroom door))
  (solve! (the safe) "John")
  (go (the hallway door))
  (go (the study door))
  (take (the shed-key))
  (go (the hallway door))
  (go (the hallway stairs))
  (go (the piano-room door))
  (go (the dining-room door))
  (go (the kitchen door))
  (go (the backyard door))
  (go (the shed door))
  (take (the axe))
  (equip (the axe))
  (go (the backyard door))
  (go (the kitchen door))
  (go (the dining-room door))
  (go (the piano-room door))
  (go (the piano-room stairs))
  (go (the chamber door))
  (go (the cellar door))
  (attack (the zombie))
  (attack (the zombie))
  (take (the outside key))
  (go (the chamber door))
  (go (the basement door))
  (go (the basement stairs))
  (go (the lobby door))
  (go (the outside door)))

;;;
;;; UTILITIES
;;;

;; here: -> container
;; The current room the player is in
(define (here)
  (thing-location me))

;; stuff-here: -> (listof thing)
;; All the stuff in the room the player is in
(define (stuff-here)
  (container-accessible-contents (here)))

;; stuff-here-except-me: -> (listof thing)
;; All the stuff in the room the player is in except the player.
(define (stuff-here-except-me)
  (remove me (stuff-here)))

;; my-inventory: -> (listof thing)
;; List of things in the player's pockets.
(define (my-inventory)
  (container-accessible-contents me))

;; accessible-objects -> (listof thing)
;; All the objects that should be searched by find and the.
(define (accessible-objects)
  (append (stuff-here-except-me)
          (my-inventory)))

;; have?: thing -> boolean
;; True if the thing is in the player's pocket.
(define (have? thing)
  (eq? (thing-location thing)
       me))

;; have-a?: predicate -> boolean
;; True if the player has something satisfying predicate in their pocket.
(define (have-a? predicate)
  (ormap predicate
         (container-accessible-contents me)))

;; find-the: (listof string) -> object
;; Returns the object from (accessible-objects)
;; whose name contains the specified words.
(define (find-the words)
  (find (λ (o)
          (andmap (λ (name) (is-a? o name))
                  words))
        (accessible-objects)))

;; find-within: container (listof string) -> object
;; Like find-the, but searches the contents of the container
;; whose name contains the specified words.
(define (find-within container words)
  (find (λ (o)
          (andmap (λ (name) (is-a? o name))
                  words))
        (container-accessible-contents container)))

;; find: (object->boolean) (listof thing) -> object
;; Search list for an object matching predicate.
(define (find predicate? list)
  (local [(define matches
            (filter predicate? list))]
    (case (length matches)
      [(0) (error "There's nothing like that here!")]
      [(1) (first matches)]
      [else (error "Which one?")])))

;; everything: -> (listof container)
;; Returns all the objects reachable from the player in the game
;; world.  So if you create an object that's in a room the player
;; has no door to, it won't appear in this list.
(define (everything)
  (local [(define all-containers '())
          ; Add container, and then recursively add its contents
          ; and location and/or destination, as appropriate.
          (define (walk container)
            ; Ignore the container if its already in our list
            (unless (member container all-containers)
              (begin (set! all-containers
                           (cons container all-containers))
                     ; Add its contents
                     (for-each walk (container-contents container))
                     ; If it's a door, include its destination
                     (when (door? container)
                       (walk (door-destination container)))
                     ; If  it's a thing, include its location.
                     (when (thing? container)
                       (walk (thing-location container))))))]
    ; Start the recursion with the player
    (begin (walk me)
           all-containers)))

;; print-everything: -> void
;; Prints all the objects in the game.
(define (print-everything)
  (begin (display-line "All objects in the game:")
         (for-each print-description (everything))))

;; every: (container -> boolean) -> (listof container)
;; A list of all the objects from (everything) that satisfy
;; the predicate.
(define (every predicate?)
  (filter predicate? (everything)))

;; print-every: (container -> boolean) -> void
;; Prints all the objects satisfying predicate.
(define (print-every predicate?)
  (for-each print-description (every predicate?)))

;; check-containers: -> void
;; Throw an exception if there is an thing whose location and
;; container disagree with one another.
(define (check-containers!)
  (for-each (λ (container)
              (for-each (λ (thing)
                          (unless (eq? (thing-location thing)
                                       container)
                            (error (description container)
                                   " has "
                                   (description thing)
                                   " in its contents list but "
                                   (description thing)
                                   " has a different location.")))
                        (container-contents container)))
            (everything)))

;; is-a?: object word -> boolean
;; True if word appears in the description of the object
;; or is the name of one of its types
(define (is-a? obj word)
  (let* ((str (if (symbol? word)
                  (symbol->string word)
                  word))
         (probe (name->type-predicate str)))
    (if (eq? probe #f)
        (member str (description-word-list obj))
        (probe obj))))

;; display-line: object -> void
;; EFFECT: prints object using display, and then starts a new line.
(define (display-line what)
  (begin (display what)
         (newline)
         (void)))

;; words->string: (listof string) -> string
;; Converts a list of one-word strings into a single string,
;; e.g. '("a" "red" "door") -> "a red door"
(define (words->string word-list)
  (string-append (first word-list)
                 (apply string-append
                        (map (λ (word)
                               (string-append " " word))
                             (rest word-list)))))

;; string->words: string -> (listof string)
;; Converts a string containing words to a list of the individual
;; words.  Inverse of words->string.
(define (string->words string)
  (string-split string))

;; add-a-or-an: (listof string) -> (listof string)
;; Prefixes a list of words with "a" or "an", depending
;; on whether the first word in the list begins with a
;; vowel.
(define (add-a-or-an word-list)
  (local [(define first-word (first word-list))
          (define first-char (substring first-word 0 1))
          (define starts-with-vowel? (string-contains? first-char "aeiou"))]
    (cons (if starts-with-vowel?
              "an"
              "a")
          word-list)))

;;
;; The following calls are filling in blanks in the other files.
;; This is needed because this file is in a different langauge than
;; the others.
;;
(set-find-the! find-the)
(set-find-within! find-within)
(set-restart-game! (λ () (start-game)))
(define (game-print object)
  (cond [(void? object)
         (void)]
        [(object? object)
         (print-description object)]
        [else (write object)]))

(current-print game-print)
   
;;;
;;; Start it up
;;;

(start-game)
(begin (display-line "You are trapped in a house, and you have one objective: Escape!")
       (display-line "This house is riddled with enemies and puzzles, and in order to escape through the front door, you'll have to use your wits.")
       (display-line "(Wits not included)")
       (display-line "You only have an hour to do so, so make sure you don't waste any time!"))
(look)



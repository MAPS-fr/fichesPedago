extensions [network]

turtles-own
[id
 state
 infected-time
 recovery-time
 node-clustering-coefficient
 perco
]

links-own [rewired?                    ;; keeps track of whether the link has been rewired or not
          ]
   
globals[S I R list-I maxI N-R cumul-R cumul-R-% IQ-I-list IQ-I R0
       perco?
       count-perco
       clustering-coefficient                 
       average-path-length                  
       number-rewired
       network-data
       group1
       ]
;************************************************************************;
to set-globals
set S count turtles with [state = "S"] / count turtles * 100
set I count turtles with [state = "I"] / count turtles * 100
set R count turtles with [state = "R"] / count turtles * 100
set list-I lput I list-I
set cumul-R lput (last cumul-R + (R * count turtles / 100)) cumul-R
set R0 nbre-moyen-contacts * pInfection / pGuerison
set perco? 0
end
;************************************************************************;
to setup
  clear-all
  
  ifelse network = "none"
         [crt number-of-nodes
              [set state "S"
               set infected-time 0
               if Guerison = "Temps fixe"
                  [set recovery-time (1 / pGuerison)]
               if Guerison = "Temps aléatoire"
                  [while [recovery-time = 0]
                         [set recovery-time (random-poisson (1 / pGuerison))]
                  ]
               setxy random-xcor random-ycor
               set shape "bug"
               ]
         ]
         [setup-network]
  
 
  ask turtles 
    [become-susceptible 
     if Guerison = "Temps fixe"
      [set recovery-time (1 / pGuerison)]
     if Guerison = "Temps aléatoire"
      [while [recovery-time = 0]
      [set recovery-time (random-poisson (1 / pGuerison))]
      ]
    ]
  
  ask n-of nbre_inf_INI turtles
    [ become-infected ]
  set list-I (list)
  set cumul-R (list 0)
  set-globals
  ask links [ set color white ]
  reset-ticks
  compute-average-shortest-path-length
  find-clustering-coefficient
end
;************************************************************************;
to setup-clean
  ask turtles
    [ become-susceptible 
      
        if Guerison = "Temps fixe"
      [set recovery-time (1 / pGuerison)]
     if Guerison = "Temps aléatoire"
      [while [recovery-time = 0]
      [set recovery-time (random-poisson (1 / pGuerison))]
      ]
    ]    
  ask n-of nbre_inf_INI turtles
    [ become-infected ]
    
  set-globals
  ask links [ set color white ]
  
  reset-ticks
end

;************************************************************************;
;**************SETUP NETWORK*********************************************;
 to setup-network
  while [perco? = 0]
        [clear-all
         
         if network = "clustered"
          [setup-nodes
           setup-spatially-clustered-network
          ]
        if network = "scale free"
        [setup-scale-free 
        ]
        if network = "small world 4" or network = "small world 6" or network = "small world 8" or network = "small world 10" or network = "small world 12" 
           [setup-small-world
           ]
        set count-perco 0
        while [count-perco = 0]
           [ask one-of turtles
              [set perco 1
                percolation ;;; la procédure de percolation ré-initialise le réseau jusqu'à ce qu'il soit totalement connecté
              ]
           ]
        
        ]     
  end 

;**************************************************************************************;
;***********************CLUSTERED NETWORK**********************************************;
to setup-nodes
  set-default-shape turtles "circle"
  crt number-of-nodes
  [
    ; for visual reasons, we don't put any nodes *too* close to the edges
    setxy (random-xcor ) (random-ycor )
    
 
    
  ]
end

to setup-spatially-clustered-network
  let num-links (average-node-degree * number-of-nodes) / 2
  while [count links < num-links ]
  [
    ask one-of turtles
    [
      let choice (min-one-of (other turtles with [not link-neighbor? myself])
                   [distance myself])
      if choice != nobody [ create-link-with choice ]
    ]
  ]
end

;**************************************************************************************;
;***********************SCALE FREE NETWORK**********************************************;
to setup-scale-free 
set-default-shape turtles "circle"
;; make the initial network of two turtles and an edge
  make-node nobody        ;; first node, unattached
  make-node turtle 0      ;; second node, attached to first node
  ;; new edge is green, old edges are gray
  ask links [ set color gray ]
  make-node find-partner         ;; find partner & use it as attachment
                                 ;; point for new node
  
  repeat number-of-nodes [make-node find-partner]  
  ask links [ set color gray ]
end

;; used for creating a new node
to make-node [old-node]
  crt 1
  [
    set color red
    if old-node != nobody
      [ create-link-with old-node [ set color green ]
        ;; position the new node near its partner
        move-to old-node
        fd 8
      ]
  ]
end

;; This code is borrowed from Lottery Example (in the Code Examples
;; section of the Models Library).
;; The idea behind the code is a bit tricky to understand.
;; Basically we take the sum of the degrees (number of connections)
;; of the turtles, and that's how many "tickets" we have in our lottery.
;; Then we pick a random "ticket" (a random number).  Then we step
;; through the turtles to figure out which node holds the winning ticket.
to-report find-partner
  let total random-float sum [count link-neighbors] of turtles
  let partner nobody
  ask turtles
  [
    let nc count link-neighbors
    ;; if there's no winner yet...
    if partner = nobody
    [
      ifelse nc > total
        [ set partner self ]
        [ set total total - nc ]
    ]
  ]
  report partner
end

;**************************************************************************************;
;***********************SMALL WORLD NETWORK**********************************************;
to setup-small-world
set-default-shape turtles "circle"
  make-turtles
  ;; set up a variable to determine if we still have a connected network
  ;; (in most cases we will since it starts out fully connected)
  if network = "small world 4" [wire-them-av-degree4]
  if network = "small world 6" [wire-them-av-degree6]
  if network = "small world 8" [wire-them-av-degree8]
  if network = "small world 10" [wire-them-av-degree10]
  if network = "small world 12" [wire-them-av-degree12]
  repeat (%rewired * number-of-nodes / 100) [rewire-one]   
end  
;;;;;;;;;;;;;;;;;;;;;;;
;;; Network Creation ;;
;;;;;;;;;;;;;;;;;;;;;;;

to make-turtles
  crt number-of-nodes [ set color gray + 2 ]
  ;; arrange them in a circle in order by who number
  layout-circle (sort turtles) max-pxcor - 1
end

to wire-them-av-degree4
  ;; iterate over the turtles
  let n 0
  while [n < count turtles]
  [
    ;; make edges with the next two neighbors
    ;; this makes a lattice with average degree of 6
    make-edge turtle n
              turtle ((n + 1) mod count turtles)
    make-edge turtle n
              turtle ((n + 2) mod count turtles)
    make-edge turtle n
              turtle ((n + 3) mod count turtles)
    set n n + 1
  ]
end

to wire-them-av-degree6
  ;; iterate over the turtles
  let n 0
  while [n < count turtles]
  [
    ;; make edges with the next two neighbors
    ;; this makes a lattice with average degree of 6
    make-edge turtle n
              turtle ((n + 1) mod count turtles)
    make-edge turtle n
              turtle ((n + 2) mod count turtles)
    make-edge turtle n
              turtle ((n + 3) mod count turtles)
    set n n + 1
  ]
end


to wire-them-av-degree8
  ;; iterate over the turtles
  let n 0
  while [n < count turtles]
  [
    ;; make edges with the next two neighbors
    ;; this makes a lattice with average degree of 6
    make-edge turtle n
              turtle ((n + 1) mod count turtles)
    make-edge turtle n
              turtle ((n + 2) mod count turtles)
    make-edge turtle n
              turtle ((n + 3) mod count turtles)
    make-edge turtle n
              turtle ((n + 4) mod count turtles)
    set n n + 1
  ]
end

to wire-them-av-degree10
  ;; iterate over the turtles
  let n 0
  while [n < count turtles]
  [
    ;; make edges with the next two neighbors
    ;; this makes a lattice with average degree of 6
    make-edge turtle n
              turtle ((n + 1) mod count turtles)
    make-edge turtle n
              turtle ((n + 2) mod count turtles)
    make-edge turtle n
              turtle ((n + 3) mod count turtles)
    make-edge turtle n
              turtle ((n + 4) mod count turtles)
    make-edge turtle n
              turtle ((n + 5) mod count turtles)
    set n n + 1
  ]
end

to wire-them-av-degree12
  ;; iterate over the turtles
  let n 0
  while [n < count turtles]
  [
    ;; make edges with the next two neighbors
    ;; this makes a lattice with average degree of 6
    make-edge turtle n
              turtle ((n + 1) mod count turtles)
    make-edge turtle n
              turtle ((n + 2) mod count turtles)
    make-edge turtle n
              turtle ((n + 3) mod count turtles)
    make-edge turtle n
              turtle ((n + 4) mod count turtles)
    make-edge turtle n
              turtle ((n + 5) mod count turtles)
    make-edge turtle n
              turtle ((n + 6) mod count turtles)
    set n n + 1
  ]
end

;; connects the two turtles
to make-edge [node1 node2]
  ask node1 [ create-link-with node2  [
    set rewired? false
  ] ]
end

to rewire-one

  ;; make sure num-turtles is setup correctly else run setup first
  if count turtles != number-of-nodes [
    setup
  ]

  let potential-edges links with [ not rewired? ]
  ifelse any? potential-edges [
    ask one-of potential-edges [
      ;; "a" remains the same
      let node1 end1
      ;; if "a" is not connected to everybody
      if [ count link-neighbors ] of end1 < (count turtles - 1)
      [
        ;; find a node distinct from node1 and not already a neighbor of node1
        let node2 one-of turtles with [ (self != node1) and (not link-neighbor? node1) ]
        ;; wire the new edge
        ask node1 [ create-link-with node2 [ set color cyan  set rewired? true ] ]

        set number-rewired number-rewired + 1  ;; counter for number of rewirings

        ;; remove the old edge
        die
      ]
    ]
   ; do-plotting
  ]
  [ user-message "all edges have already been rewired once" ]
end 

;****************PERCOLATION******************
;********************************************
to percolation
ifelse not any? link-neighbors with [perco = 0]
       [set count-perco 1
        if count turtles with [perco = 1] = count turtles
           [set perco? 1]
        ]
       [ 
         ask link-neighbors with [perco = 0]
         [set perco 1
          percolation
         ]
       ]
end



;**************************************************************************************;
;**************************************************************************************;
;**************************************************************************************;
;**************************************************************************************;
to go
  set-globals
  
  ask turtles with [state = "S"]
    [ifelse interactions = "explicit" [transition-S-I-explicit-contacts] [transition-S-I-implicit-contacts]]
  ask turtles with [state = "I"]
    [transition-I-R]
  
ask turtles [
      if network = "none"
         [if not IndividualsStatic?
             [setxy random-xcor random-ycor]
         ]
     if state = "SI"
        [become-infected]
     if state = "IR"
        [become-resistant]
    ]
    do-plotting
    if condition-stop? 
       [calculate-outputs
        stop]
    
    test-infection-start
    
  tick
end

;**************************************************************************************;
to test-infection-start
  if I = 0 and ticks = 19
  [
    setup-clean
  ]
end
;**************************************************************************************;

to-report condition-stop?
if I = 0 and ticks > 20
      [report true]
      report false
end

;**************************************************************************************;
;**************************************************************************************;
to become-infected  ;; turtle procedure
  set state "I"
  set infected-time 0
  set color red
end

to become-susceptible  ;; turtle procedure
  set state "S"
  set color green
  set id who
end

to become-resistant  ;; turtle procedure
  set state "R"
  set color gray
  ask my-links [ set color gray - 2 ]
end


;**************************************************************************************;
to transition-S-I-explicit-contacts

;;Voisinage liens
let link-turtles (turtle-set)

ifelse network = "none"
       [set link-turtles turtles]
       [set link-turtles  link-neighbors] ;with [state = "I"]

let my-neighbours (turtle-set)
if count (link-turtles) > 0 [
set my-neighbours get-my-neighbours my-neighbours link-turtles

foreach sort my-neighbours
        [ifelse [state] of ? = "I"
                [let p random-float 1
                 ifelse p < (pInfection * pas_de_temps)
                        [set state "SI"]
                        []
                 ]
                 []
         ]
]

end

to transition-S-I-implicit-contacts
let bool (random-float 1 < nbre-moyen-contacts * pInfection * (I / 100) * pas_de_temps) 
if (neighbourhood = "local") [set bool (random-float 1 < nbre-moyen-contacts * pInfection * prop-infected-neighbours * pas_de_temps)]
if bool
[ 
  set state "SI"
]
end

to-report prop-infected-neighbours
let my-neighbours (turtle-set)
set my-neighbours (other turtles in-radius radius)
let my-infected-neighbours count my-neighbours with [state = "I"]
ifelse (my-neighbours = 0)
  [report 0]
  [report my-infected-neighbours / my-neighbours]
end

;**************************************************************************************;
to transition-I-R
ifelse Guerison = "Probabilité"
       [let p random-float 1
        ifelse p < ((pGuerison) * pas_de_temps)
               [set state "IR"]
               []
       ]
       [set infected-time (infected-time + (1 * pas_de_temps)) 
        if infected-time >= recovery-time
           [set state "IR"]           
       ]

end
;**************************************************************************************;
to-report get-my-neighbours [my-neighbours link-turtles]
ifelse network = "none"
       [ifelse neighbourhood = "Global"
               [set my-neighbours n-of (random-poisson nbre-moyen-contacts) turtles
                report my-neighbours
               ]
               [let a other turtles in-radius radius
                let b (random-poisson nbre-moyen-contacts)
                ifelse count a < b
                       [set my-neighbours a
                        report my-neighbours]
                       [set my-neighbours n-of b a
                        report my-neighbours 
                       ]
               ]
       ]
       [let nbContact 0
        set nbContact (random-poisson nbre-moyen-contacts)
        ifelse nbContact <= count(link-turtles) 
               [set my-neighbours n-of nbContact link-turtles
               ]
               [set my-neighbours link-turtles
               ]
        report my-neighbours
       ]
end  
;**************************************************************************************;
to do-plotting
set-current-plot "Suivi des populations"
set-current-plot-pen "S"
plotxy ticks S
set-current-plot-pen "I"
plotxy ticks I
set-current-plot-pen "R"
plotxy ticks R
end
;**************************************************************************************;
to plot-nbre-contacts
let n n-values count turtles [random-poisson nbre-moyen-contacts]
set-current-plot "Nombre moyen de contacts"
histogram n
end
;**************************************************************************************;
to calculate-outputs
set maxI max list-I
set N-R last cumul-R
set cumul-R-% (list)
foreach cumul-R
        [set cumul-R-% lput (? / N-R * 100) cumul-R-%
        ]
set IQ-I-list filter [? <= 25] cumul-R-%
set IQ-I-list filter [? >= 75] cumul-R-%
set IQ-I length IQ-I-list 
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Clustering computations ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report in-neighborhood? [ hood ]
  report ( member? end1 hood and member? end2 hood )
end

to find-clustering-coefficient
  ifelse all? turtles [count link-neighbors <= 1]
  [
    ;; it is undefined
    ;; what should this be?
    set clustering-coefficient 0
  ]
  [
    let total 0
    ask turtles with [ count link-neighbors <= 1]
      [ set node-clustering-coefficient "undefined" ]
    ask turtles with [ count link-neighbors > 1]
    [
      let hood link-neighbors
      set node-clustering-coefficient (2 * count links with [ in-neighborhood? hood ] /
                                         ((count hood) * (count hood - 1)) )
      ;; find the sum for the value at turtles
      set total total + node-clustering-coefficient
    ]
    ;; take the average
    set clustering-coefficient total / count turtles with [count link-neighbors > 1]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Shortest path computation ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to compute-average-shortest-path-length
set average-path-length network:mean-link-path-length turtles links 
end 


;**************************************************************************************;
;**************************************************************************************;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;LOAD AND SAVE NETWORK FILES;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load
clear-all

set-default-shape turtles "circle"
let file user-new-file
if ( file != false )
  [
file-open file
set network-data []
while [ not file-at-end? ]
      [set network-data sentence network-data (list (list file-read file-read file-read file-read))]
file-close
set-nodes
set-links
  ]  
 
  ask turtles 
    [become-susceptible 
     if Guerison = "Temps fixe"
      [set recovery-time (1 / pGuerison)]
     if Guerison = "Temps aléatoire"
      [while [recovery-time = 0]
      [set recovery-time (random-poisson (1 / pGuerison))]
      ]
    ]
  
  ask n-of nbre_inf_INI turtles
    [ become-infected ]
  set list-I (list)
  set cumul-R (list 0)
  set-globals
  ask links [ set color white ]
  reset-ticks
 ; compute-average-shortest-path-length
 ; find-clustering-coefficient
  


end

to set-nodes
foreach network-data
   [if not any? turtles with [id = (first ?)] 
      [ crt 1 [set id (first ?)
               set xcor item 1 ?
               set ycor item 2 ?]
      ]
   ]

end

to set-links
foreach network-data
   [ask turtle first ?
        [ifelse not link-neighbor? turtle (last ?)
                [create-link-with turtle (last ?)]
                []
        ]
   ]
end

;**************************************************************************************;
to save
let file user-new-file
  ;; We check to make sure we actually got a string just in case
  ;; the user hits the cancel button.
  if is-string? file
  [
    ;; If the file already exists, we begin by deleting it, otherwise
    ;; new data would be appended to the old contents.
    if file-exists? file
      [ file-delete file]
    file-open file
    ;; record the initial turtle data
    write-to-file
   
  ]

end

to write-to-file
  foreach sort turtles [
    ask ? [
      foreach sort link-neighbors
          [file-print (word id " " xcor " " ycor " " [id] of ?)
          ]
    ]
  ]
 file-close  
end
@#$#@#$#@
GRAPHICS-WINDOW
464
20
956
533
40
40
5.951
1
10
1
1
1
0
0
0
1
-40
40
-40
40
1
1
1
ticks
30.0

BUTTON
14
19
109
59
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
116
19
211
59
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
7
221
176
254
number-of-nodes
number-of-nodes
0
10000
1000
500
1
NIL
HORIZONTAL

SLIDER
6
261
174
294
average-node-degree
average-node-degree
1
number-of-nodes - 1
8
1
1
NIL
HORIZONTAL

SLIDER
349
630
521
663
nbre_inf_INI
nbre_inf_INI
0
10
1
1
1
NIL
HORIZONTAL

SLIDER
347
721
522
754
pGuerison
pGuerison
0
1
0.45
0.01
1
NIL
HORIZONTAL

CHOOSER
678
715
848
760
Guerison
Guerison
"Temps fixe" "Temps aléatoire" "Probabilité"
0

SLIDER
680
669
850
702
pInfection
pInfection
0
1
1
0.05
1
NIL
HORIZONTAL

SLIDER
224
18
396
51
pas_de_temps
pas_de_temps
0
1
0.01
0.001
1
NIL
HORIZONTAL

SLIDER
348
673
523
706
nbre-moyen-contacts
nbre-moyen-contacts
0
2
1.66
0.01
1
NIL
HORIZONTAL

PLOT
990
20
1470
338
Suivi des populations
Ticks
%
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"S" 1.0 0 -10899396 true "" ""
"I" 1.0 0 -2674135 true "" ""
"R" 1.0 0 -13345367 true "" ""

MONITOR
1251
468
1308
513
NIL
I
17
1
11

BUTTON
16
69
133
102
NIL
setup-clean
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1136
667
1226
712
NIL
R0
1
1
11

MONITOR
990
414
1047
459
NIL
maxI
1
1
11

MONITOR
992
466
1049
511
NIL
IQ-I
1
1
11

MONITOR
1252
414
1309
459
NIL
R
1
1
11

MONITOR
1135
723
1225
768
Tps virémie
1 / pGuerison
1
1
11

CHOOSER
7
171
176
216
network
network
"clustered" "scale free" "small world 4" "small world 6" "small world 8" "small world 12" "none"
6

MONITOR
7
394
173
439
NIL
clustering-coefficient
3
1
11

MONITOR
8
443
173
488
NIL
average-path-length
3
1
11

SLIDER
7
306
173
339
%rewired
%rewired
0
100
10
10
1
NIL
HORIZONTAL

BUTTON
142
124
205
157
NIL
load
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
214
124
279
157
NIL
save
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
3
755
169
788
IndividualsStatic?
IndividualsStatic?
1
1
-1000

CHOOSER
3
604
170
649
neighbourhood
neighbourhood
"Global" "Local"
0

SLIDER
3
654
169
687
radius
radius
0
20
3
1
1
NIL
HORIZONTAL

TEXTBOX
9
120
159
168
*********************\nParamètres réseau\n*********************
12
0.0
1

TEXTBOX
191
262
360
303
Nombre moyen de voisins (à choisir en entrée pour le réseau \"clusterisé\")
10
0.0
1

TEXTBOX
188
309
388
341
Paramètre pour réorganiser le réseau \"Small World\" 
10
0.0
1

TEXTBOX
190
231
340
249
Nombre d'individus
10
0.0
1

TEXTBOX
290
127
393
159
Charger/sauvegarder un réseau
10
0.0
1

TEXTBOX
8
491
203
539
*******************************\nInteractions entre individus\n*******************************
12
0.0
1

TEXTBOX
348
580
498
628
**************************\nParamètres épidémie\n**************************
12
0.0
1

TEXTBOX
527
631
677
663
Nbre individus infectés au départ
10
0.0
1

TEXTBOX
527
721
677
749
Probabilité de guérison / Temps de virémie
10
0.0
1

TEXTBOX
865
671
976
704
Probabilité d'infection suite à contact
10
0.0
1

TEXTBOX
530
677
680
695
Nombre moyen de contacts
10
0.0
1

TEXTBOX
190
656
340
684
Portée des interactions (voisinage local)
10
0.0
1

TEXTBOX
191
616
310
634
Locales / globales
10
0.0
1

TEXTBOX
188
170
392
234
- pas de réseau (espace isotrope)\n- réseau \"clusterisé\"\n- invariant d'échelle\n- Small World
10
0.0
1

TEXTBOX
6
690
156
738
*************************\nMobilité des individus\n*************************
12
0.0
1

TEXTBOX
862
708
1141
762
- probabiliste\n- temps de virémie identique pour toute la population\n- temps de virémie différent pour chaque individu (distribution de Poisson)
10
0.0
1

TEXTBOX
181
757
331
799
Individus statiques / mobiles (sans limites)
10
0.0
1

TEXTBOX
142
72
292
100
Réinitialiser la population sans réinitialiser le réseau
10
0.0
1

TEXTBOX
1058
417
1208
445
% d'individus infectés au pic de l'épidémie
10
0.0
1

TEXTBOX
1063
461
1216
567
Indicateur de durée de l'épidémie:\npériode comprise entre les deux instants où 25% et 75% des individus sont sortis de la classe infectée (en nb de pas de temps)
10
0.0
1

TEXTBOX
1322
426
1472
444
% d'individus ayant été infectés
10
0.0
1

TEXTBOX
1324
483
1474
501
% d'individus infectés
10
0.0
1

TEXTBOX
1263
676
1413
704
R0 = nbre-moyen-contacts * pInfection / pGuerison
10
0.0
1

TEXTBOX
1264
731
1414
759
Période infectieuse\n(en pas de temps)
10
0.0
1

TEXTBOX
189
400
339
428
Coeficient de clustering du réseau
10
0.0
1

TEXTBOX
187
446
350
488
Distance moyenne entre noeuds\n(plus court chemin)
10
0.0
1

TEXTBOX
992
359
1142
407
**********************\nSorties du modèle\n**********************
12
0.0
1

TEXTBOX
7
735
157
753
Si espace isotrope
10
0.0
1

CHOOSER
4
542
170
587
interactions
interactions
"explicit" "implicit"
1

TEXTBOX
188
534
338
604
Contacts dans le voisinage implicites ou explicites.\nNB: \"implicit\" ne s'utilise qu'avec network: none\"
10
0.0
1

MONITOR
7
345
173
390
average-degree
mean [count link-neighbors] of turtles
17
1
11

TEXTBOX
187
352
337
380
Degré moyen du réseau (nombre moyen de voisins)
10
0.0
1

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>s</metric>
    <metric>i</metric>
    <metric>r</metric>
    <enumeratedValueSet variable="average-node-degree">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Guerison">
      <value value="&quot;Temps fixe&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nodes">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pGuerison">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nbre-moyen-contacts">
      <value value="1.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pInfection">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-outbreak-size">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nbre_inf_INI">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pas_de_temps">
      <value value="0.01"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@

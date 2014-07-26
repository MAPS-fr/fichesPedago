breed [voters voter]
breed [candidates candidate]
breed [groups group]

candidates-own[
  nbVoters
  distance_totale
  posInitX
  posInitY
]

turtles-own[
  opinions
]

groups-own[
  effectif
]
patches-own [id-cluster nb-voters-here]

globals
[
  indic-color
]


;;
;; SETUP AND HELPERS
;;

to setup
  clear-all
  set indic-color 15
  set-default-shape turtles "circle"
  make-candidates
  make-voters
  reset-ticks
end


to make-voters
  create-voters nombre-d-electeurs [
    set shape "triangle" 
    ifelse Distrib_Electeurs = "Uniforme"
    [ ;;Distribution uniforme des votants
      setxy random-xcor random-ycor]
    [ ;;Distribution normale centrée des votants
      let x_result (int (random-normal 0 35))
           if (x_result < -100)
            [set x_result -100]
           if (x_result > 100)
            [set x_result 100]
           let y_result (int (random-normal 0 35))
           if (y_result < -100)
            [set y_result -100]
           if (y_result > 100)
            [set y_result 100]
       setxy x_result y_result
    ]
    set color white
  ]  
end

to make-candidates
  create-ordered-candidates nombre-de-candidats [
    if Distrib_Candidates = "Aleatoire" 
    [setxy random-xcor random-ycor]
    if Distrib_Candidates = "Polygone" 
    [jump 50]
    if Distrib_Candidates = "Ligne"
    [setxy min-pxcor + ((world-width / nombre-de-candidats) * (who + 0.5)) 0]
    if Distrib_Candidates = "Diagonale"
    [setxy (min-pxcor + ((world-width / nombre-de-candidats) * (who + 0.5))) (min-pycor + ((world-height / nombre-de-candidats) * (who + 0.5)))]
    set size 5 
    set distance_totale 0
    set posInitX xcor
    set posInitY ycor
    set color one-of base-colors
  ]
  
end

to go
  move-voters
  move-candidates
  update-poll
  tick
end  


to update-poll
  ask candidates [
    set nbVoters 0
  ]
  ask voters [
    set color white
    ask candidates with-min [distance myself] [
      if distance myself < Seuil_Attraction_Candidats
      [
        set nbVoters nbVoters + 1
        ask myself [
          set color ([color] of myself)
        ]
      ]
    ]
  ]
  ask candidates[
     set size 5 + nbVoters / 100
     set label floor (nbVoters * 100 / count voters)
  ]
end

to move-voters
  ask voters[
    ifelse (random 100 > poidscandidats)
    [
      ;;discussion entre votants
      let pote one-of other voters with [distance myself < Seuil_Attraction_Electeurs]
      if pote != nobody  [
        face pote 
        fd min list Distance_Parcourue (distance pote)
       ]
    ]
    [
      ;;influence des candidats
      let cand one-of candidates 
      if cand != nobody
      [
        ifelse (distance cand < Seuil_Attraction_Candidats)
        [ ;; influence
          face cand
          fd min list Distance_Parcourue (distance cand)
        ]
        [ if (distance cand > Seuil_Repulsion_Candidats)
          [;;reaction
            face cand
            right 180
            fd Distance_Parcourue
          ]
        ]
      ] 
      ]
    ]
end
  
to move-candidates

if (Strat_Candidats = "Groupe") and (ticks mod 4 = 0) [ make-clusters]
ask candidates[
 let posx xcor
 let posy ycor
 if Strat_Candidats ="Fixe" []
 if Strat_Candidats ="Aleatoire" [
     let choix random 5
     if choix = 1 [S1]
     if choix = 2 [S2]
     if choix = 3 [S3]
     if choix = 4 [S4]
 ]
 if Strat_Candidats ="Faire les marches" [ S1 ]
 if Strat_Candidats ="Distinction" [S2]
 if Strat_Candidats ="Groupe" [S3]
 if Strat_Candidats ="Se rapproche du meilleur" [S4]
set distance_totale distance_totale + distancexy posx posy
]  
end


to S1
      ;;se rapproche des votants
      let cible one-of other voters with [distance myself < Seuil_Attraction_Candidats] 
      if cible != nobody  [
        face cible 
          fd min list Distance_Parcourue (distance cible)
      ]
end

to S2
      ;;repulsion des autres candidats
      let cand one-of other candidates 
      if cand != nobody  [
        face cand
        right 180 
        fd Distance_Parcourue 
      ]   
end

to S3
    let cible max-one-of groups [effectif]
    if cible != nobody [
      face cible
      fd Distance_Parcourue
    ]
    
    
end  

to S4
     ;; se rapproche du candidat qui a le plus de voix
     let cand one-of other candidates with-max [nbVoters]
     if cand != nobody  [
        face cand
        fd min list Distance_Parcourue (distance cand) 
]
end

  
  
to make-clusters
ask groups [die]
let ag_a_traite voters
let groupes []
let dist_max Seuil_Attraction_Electeurs / 2.0
while [ (any? (ag_a_traite))][
  let ag_a_traite2 ag_a_traite
  ask ag_a_traite2 
   [ 
     set ag_a_traite other ag_a_traite
     let voisins ag_a_traite with [(distance myself < dist_max)]
     let nb-voters-here2 count voisins
     if nb-voters-here2 > 0 [
       let gp no-turtles
       set gp (turtle-set self gp)
        while [ (any? (voisins))][
         let voisins2 no-turtles
         ask voisins [
           set ag_a_traite other ag_a_traite
          let voisins3 ag_a_traite with [(distance myself < dist_max)]
          let nb-voters-here3 count voisins
           if nb-voters-here3 > 0 [
             set gp (turtle-set self gp)
             set voisins2 (turtle-set voisins2 voisins3)
           ]
         ]
         set voisins voisins2
       ]
           set groupes fput gp groupes
          
     ]
   ]
]
foreach groupes [
        let weighted-xcor mean [xcor] of ?
        let weighted-ycor mean [ycor] of ?
        create-groups 1
              [setxy weighted-xcor weighted-ycor
               set color magenta
               set size 2
               set effectif count ?
              ]
       ]
end







  
  
  
  
  
  
  
  
  
  
  
@#$#@#$#@
GRAPHICS-WINDOW
375
13
758
417
100
100
1.86
1
10
1
1
1
0
0
0
1
-100
100
-100
100
1
1
1
ticks
30.0

SLIDER
134
330
354
363
Seuil_Attraction_Electeurs
Seuil_Attraction_Electeurs
0
100
0
1
1
NIL
HORIZONTAL

BUTTON
71
15
192
76
setup
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
213
48
292
81
go
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
19
95
207
128
nombre-d-electeurs
nombre-d-electeurs
2
8000
1000
100
1
NIL
HORIZONTAL

SLIDER
89
377
355
410
Distance_Parcourue
Distance_Parcourue
0
100
8
1
1
NIL
HORIZONTAL

SLIDER
19
148
208
181
nombre-de-candidats
nombre-de-candidats
0
20
5
1
1
NIL
HORIZONTAL

SLIDER
89
212
122
362
PoidsCandidats
PoidsCandidats
0
100
100
1
1
NIL
VERTICAL

SLIDER
134
211
354
244
Seuil_Attraction_Candidats
Seuil_Attraction_Candidats
0
200
0
1
1
NIL
HORIZONTAL

SLIDER
134
248
353
281
Seuil_Repulsion_Candidats
Seuil_Repulsion_Candidats
Seuil_Attraction_Candidats
200
140
1
1
NIL
HORIZONTAL

TEXTBOX
16
227
75
352
Influence relative des candidats par rapport aux electeurs
11
0.0
1

TEXTBOX
91
416
359
443
Nombre de pas parcourus par un electeur sous l'influence d'un candidat/electeur\n
11
0.0
1

CHOOSER
226
88
364
133
Distrib_Electeurs
Distrib_Electeurs
"Uniforme" "Normale"
0

CHOOSER
225
143
362
188
Distrib_Candidates
Distrib_Candidates
"Aleatoire" "Polygone" "Ligne" "Diagonale"
2

TEXTBOX
30
465
208
493
Strategies des candidats
11
0.0
1

CHOOSER
28
488
288
533
Strat_Candidats
Strat_Candidats
"Fixe" "Faire les marches" "Distinction" "Groupe" "Se rapproche du meilleur" "Aleatoire"
0

PLOT
772
14
989
144
Repartition_votants
noCandidats
nbVotants
0.0
2.0
0.0
200.0
true
false
"" "clear-plot\nauto-plot-on\nforeach sort candidates [\nset-plot-pen-color [color] of ?\nplotxy [who] of ? [nbVoters] of ?\n]\nplotxy nombre-de-candidats (nombre-d-electeurs - sum [nbVoters] of candidates)"
PENS
"nbVoters" 1.0 1 -16777216 true "" ""

PLOT
770
438
987
575
Volatilite_Des_Candidats
time
distance
0.0
10.0
0.0
10.0
true
false
"ask candidates [\ncreate-temporary-plot-pen word \"pen\" who\nset-plot-pen-color color\n]" "ask candidates[\nset-current-plot-pen word \"pen\" who\nplot distancexy posInitX posInitY\n]"
PENS

PLOT
772
150
987
281
Entropie
time
S
0.0
10.0
0.0
1.0
true
false
"" "if (ticks > 1) [\nlet abst ((nombre-d-electeurs - sum [nbVoters] of candidates) / nombre-d-electeurs)\nlet S 0\nask candidates [\nlet p (nbVoters / nombre-d-electeurs)\nif p > 0\n[set S (S - (p * ln p))]\n]\nif abst > 0 \n[set S (S - abst * ln abst)]\nset S S / ln (count candidates + 1)\nplot S\n]"
PENS
"pen-0" 1.0 0 -8053223 true "" ""

PLOT
770
580
986
713
Richesse du debat public
time
Richesse
0.0
10.0
0.0
10.0
true
false
"" "if ticks > 1 [\nlet dist 0\nlet poids 0\nask candidates[\nask other candidates[\nlet p min list ([nbVoters] of self) ([nbVoters] of myself)\nset dist dist + (distance myself) * p\nset poids poids + p\n]\n]\nifelse poids != 0 \n[plot (dist / poids)]\n[plot 0]\n]"
PENS
"default" 1.0 0 -13345367 true "" ""

TEXTBOX
1004
159
1154
271
Indice de Shannon permettant de caracteriser l'aspect plus ou moins egalitaire de la repartition des electeurs par candidats : entre 0 (repartition egalitaire) et 1 (repartition inegalitaire)
11
0.0
1

TEXTBOX
1002
479
1152
535
Distance entre la position au temps t d'un candidat et sa position de depart au fil de la simulation
11
0.0
1

TEXTBOX
1001
585
1151
711
Moyenne des distances entre les candidats pris deux à deux ponderees par le plus petit nombre de votants d'entre les deux candidats. Indice large : beaucoup de distance ; indice faible : proximite des candidats.
11
0.0
1

PLOT
771
283
987
433
Plus proche voisin en moyenne
time
R
0.0
10.0
0.0
3.0
true
false
"" "let dist-min []\nask voters[\n  let nearest min-one-of other voters [distance myself]\n  set dist-min lput distance nearest dist-min\n]\nlet average-shortest-dist mean dist-min\nplot (average-shortest-dist / (0.5 * sqrt (world-width * world-height / count voters)))\n; show (average-shortest-dist / (0.5 * sqrt (world-width * world-height / count voters)))"
PENS
"default" 1.0 0 -16777216 true "" ""

TEXTBOX
1003
284
1153
438
Ratio R entre (a) la valeur moyenne de la distance au plus proche voisin chez les électeurs et (b) ce qu'elle serait dans une distribution aléatoire. R=0 : distribution concentree. R=1 : distribution aleatoire. R > 1 : tend vers une couverture de plus en plus homogene de l'espace.
11
0.0
1

BUTTON
214
10
292
43
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model simulates 



## HOW IT WORKS

## HOW TO USE IT

## THINGS TO NOTICE

## THINGS TO TRY

## EXTENDING THE MODEL

dimensions ? rester sur du 2D ou augmenter ?

V0 distributions initiales des électeurs

déplacement et stratégie des candidats
	exploration locale
	prise de température de l'opinion générale
	si les candidats suivent les opinions des électeurs, on risque d'avoir très rapidement un regroupement
	attractions répulsions des candidats
	certains vont chercher plutôt des abstentionnistes
candidats peuvent fusiionner ? (peu de candidats peuvent s'éliminer ? (non car pas souvent de désistement)

phénomènes de rumeurs (différentiel de perception de l'opinion d'un candidat par rapport à son opinion réelle)
que se passe t'il quand on rajoute un évènement aléatoire (type dsk, merah)

électeurs

V0 prendre en compte la taille des candidats
quand ils s'influencent, c'est sur une dimensions seulement

formation d'un candidat moyen pour représenter virtuellement l'opinion d'un groupe de votants non représentés, vers lequel pourrait se déplacer un candidat (même si les votants qui ont contribué à créer ce candidat se sont depuis déplacés)

création d'un candidat représentatif d'un groupe de votants non représentés si ils sont suffisamment nombreux. 

vote 

procédure électorale réaliste V0 

 	

## NETLOGO FEATURES

The model creates turtles by asking patches to sprout a turtle initialized with a certain rule. Because a patch can only sprout one turtle, only a certain number of turtles can fit in a certain radius. The model verifies that the user hasn't asked for more turtles than can fit in the initial-radius specified to avoid an error.

## CREDITS AND REFERENCES

The study is described in Levy, S.T., & Wilensky, U. (2004). Making sense of complexity: Patterns in forming causal connections between individual agent behaviors and aggregate group behaviors. In U. Wilensky (Chair) and S. Papert (Discussant) Networking and complexifying the science classroom: Students simulating and making sense of complex systems using the HubNet networked architecture. The annual meeting of the American Educational Research Association, San Diego, CA, April 12 - 16, 2004. http://ccl.northwestern.edu/papers/midlevel-AERA04.pdf

Thanks to Stephanie Bezold for her work on this model.

## HOW TO CITE

If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:
- Wilensky, U. (2004).  NetLogo Scatter model.  http://ccl.northwestern.edu/netlogo/models/Scatter.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.  
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

In other publications, please use:  
- Copyright 2004 Uri Wilensky. All rights reserved. See http://ccl.northwestern.edu/netlogo/models/Scatter for terms of use.

## COPYRIGHT NOTICE

Copyright 2004 Uri Wilensky. All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:  
a) this copyright notice is included.  
b) this model will not be redistributed for profit without permission from Uri Wilensky. Contact Uri Wilensky for appropriate licenses for redistribution for profit.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.
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
NetLogo 5.0.5
@#$#@#$#@
set too-close 1.5
set too-far 2.0
set num-open-min-max 50
setup
repeat 75 [ go ]
@#$#@#$#@
@#$#@#$#@
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

globals 
[
  NbProies NbPredateurs                             ;; effectifs des 2 populations
  Periode NbProiesEquilibre NbPredateursEquilibre   ;; propriétés du modéle pour a,b,c,d fixés
  Alpha                                             ;; efficience de la prédation pour la reproduction des predateurs
  t
 ]                                            
                       

to-report deriveeNbProies [UnNbProies UnNbPredateurs]
;; ROLE : renvoie la variation du nombre de proies pendant un pas de temps (1ere equation differentielle)
;; ENTREE UnNbProies, UnNbPredateurs : effectifs à l'instant courant
;; ENTREE GLOBALE a, b : taux de croissance (a) et de mortalite par predation (b)
  report  (a * UnNbProies - b * UnNbProies * UnNbPredateurs)
end



to-report deriveeNbPredateurs [UnNbProies UnNbPredateurs]
;; ROLE : renvoie la variation du nombre de prédateurs pendant un pas de temps (2nde equation differentielle)
;; ENTREE UnNbProies, UnNbPredateurs : effectifs é l'instant courant
;; ENTREE GLOBALE c, d : taux de mortalité (c) et de croissance par predation (d)
  report  (- c * UnNbPredateurs + d * UnNbProies * UnNbPredateurs)
end


to AffecterValeursPredefinies1
  __clear-all-and-reset-ticks
  set a 1.5                     ;; taux de croissance annuelle des proies (par unité de proie)
  set b 0.05                    ;; taux de mortalite annuelle des proies par predation (par unité de proie et unité de prédateur)
  set c 0.25                    ;; taux de mortalite annuelle des predateurs (par unité de prédateur)
  set d 0.0003                  ;; taux de croissance annuelle des predateurs lié é la prédation (par unité de proie et unité de prédateur)
  set NbProiesInitial 1000
  set NbPredateursInitial 35
  CalculerProprietesModele
end


to AffecterValeursPredefinies2
  __clear-all-and-reset-ticks
  set a 0.35                   ;; taux de croissance annuelle des proies (par unité de proie)
  set b 0.001                  ;; taux de mortalite annuelle des proies par predation (par unité de proie et unité de prédateur)
  set c 0.25                   ;; taux de mortalite annuelle des predateurs (par unité de prédateur)
  set d 0.000005               ;; taux de croissance annuelle des predateurs lié é la prédation (par unité de proie et unité de prédateur)
  set NbProiesInitial 40000
  set NbPredateursInitial 300
  CalculerProprietesModele
end

;; Initialisation

to setup
  ifelse HoldPhase? 
    [set-current-plot "Populations"      clear-plot   ;; remise à 0 du graphique d'evolution des populations seul
     set-current-plot "DiagrammeDePhase" plot-pen-up  ;; pour eviter de tracer une droite inutile entre 2 simulations
    ] 
    [clear-all-plots]                                 ;; remise é 0 de tous les graphiques si on ne maintient pas le tracé du diagramme de phase 
  set NbProies     NbProiesInitial                    ;; initialisation du nombre de proies
  set NbPredateurs NbPredateursInitial                ;; initialisation du nombre de predateurs
  set t 0
  update-plot
  set-current-plot "DiagrammeDePhase" plot-pen-down   ;;au cas oo on a leve le crayon si maintien des traces
  CalculerProprietesModele
end

;; EXECUTION D'UN PAS DE SIMULATION

to go
  ;; INTEGRATION : les variables en Y1 sont relatives aux proies, celles en Y2 aux predateurs
  ;; on calcule la variation a operer sur les proies (dY1) et sur les predateurs (dY2)
  ;; Pour la méthode d'Euler, on fait une seule approximation A (dY1a, dY2a)
  ;; Pour la méthode de RK4,  on fait 4 approximations A (dY1a, dY2a), B (dY1b, dY2b), C (dY1c, dY2c) et D (dY1d, dY2d)
  ;;                          puis on les pondére (poids 1 pour A et D, poids 2 pour B et C)
  let dt  PasDeTemps
  let dY1a   dt * deriveeNbProies     NbProies  NbPredateurs  ;; 1ere approximation sur Y1 (Euler)
  let dY2a   dt * deriveeNbPredateurs NbProies  NbPredateurs  ;; 1ere approximation sur Y2 (Euler)
  
  ifelse MethodeDeResolution = "Euler (standard)"
    [ ;; Utilisation de la méthode d'Euler
     set NbProies     NbProies     +  dY1a 
     set NbPredateurs NbPredateurs +  dY2a 
    ]
    [ ;; Utilisation de la méthode de Runge-Kutta 4
     let dY1b   dt * deriveeNbProies     (NbProies + dY1a / 2) (NbPredateurs + dY2a / 2) ;; 2eme approximation sur Y1
     let dY2b   dt * deriveeNbPredateurs (NbProies + dY1a / 2) (NbPredateurs + dY2a / 2) ;; 2eme approximation sur Y2
     let dY1c   dt * deriveeNbProies     (NbProies + dY1b / 2) (NbPredateurs + dY2b / 2) ;; 3eme approximation sur Y1
     let dY2c   dt * deriveeNbPredateurs (NbProies + dY1b / 2) (NbPredateurs + dY2b / 2) ;; 3eme approximation sur Y2
     let dY1d   dt * deriveeNbProies     (NbProies + dY1c)     (NbPredateurs + dY2c)     ;; 4eme approximation sur Y1
     let dY2d   dt * deriveeNbPredateurs (NbProies + dY1c)     (NbPredateurs + dY2c)     ;; 4eme approximation sur Y2
     set NbProies     NbProies     +  (dY1a + 2 * (dY1b + dY1c) + dY1d) / 6              ;; estimation finale de Y1
     set NbPredateurs NbPredateurs +  (dY2a + 2 * (dY2b + dY2c) + dY2d) / 6              ;; estimation finale de Y1
    ]
  set t t + dt
  update-plot
  if t > 15 * periode [stop]
end

;; Affichage des graphes

to update-plot
  set-current-plot "Populations"
  set-current-plot-pen "Proies"             plot NbProies
  set-current-plot-pen "Pred. * 100"        plot NbPredateurs * 100
  set-current-plot "DiagrammeDePhase"       plotxy NbProies NbPredateurs
  set-current-plot-pen "point-fixe"         plotxy NbProiesEquilibre NbPredateursEquilibre
  set-current-plot-pen "proies-predateurs"
end


; Periode et point d'équilibre du modèle

to CalculerProprietesModele
;; ROLE : calcule la période des oscillations et les coordonnées du point fixe
;; SORTIE GLOBALE Periode, NbProiesEquilibre, NbPredateursEquilibre, Alpha
  Set Periode               2 * pi / (a * c) ^ 0.5
  Set NbProiesEquilibre     c / d
  Set NbPredateursEquilibre a / b
  Set Alpha d / b
end
@#$#@#$#@
GRAPHICS-WINDOW
1633
10
1878
221
25
25
3.53
1
14
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

SLIDER
11
386
201
419
NbProiesInitial
NbProiesInitial
0
50000
1000
100
1
NIL
HORIZONTAL

SLIDER
111
346
205
379
b
b
0
0.1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
11
347
103
380
a
a
0
2
1.5
0.1
1
NIL
HORIZONTAL

SLIDER
12
546
209
579
NbPredateursInitial
NbPredateursInitial
0
500
35
10
1
NIL
HORIZONTAL

SLIDER
116
507
209
540
d
d
0
0.0005
3.0E-4
0.00001
1
NIL
HORIZONTAL

SLIDER
12
508
104
541
c
c
0
0.50
0.25
0.01
1
NIL
HORIZONTAL

BUTTON
10
89
65
122
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
68
89
123
122
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

PLOT
497
84
1108
427
Populations
Temps
Nombre de proies et de prédateurs
0.0
50.0
0.0
100.0
true
true
"" ""
PENS
"Proies" 1.0 0 -13345367 true "" ""
"Pred. * 100" 1.0 0 -2674135 true "" ""

SLIDER
258
142
374
175
PasDeTemps
PasDeTemps
0.0001
0.1
0.01
0.001
1
NIL
HORIZONTAL

BUTTON
9
180
187
213
Paramètres prédéfinis 1
AffecterValeursPredefinies1
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
495
436
1105
777
DiagrammeDePhase
Nombre de Proies
Nombre de Predateurs
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"proies-predateurs" 1.0 0 -16777216 true "" ""
"point-fixe" 1.0 2 -2674135 false "" ""

TEXTBOX
403
10
1129
37
Modèle Proies-Prédateurs - version MACRO (EDO)
20
0.0
1

TEXTBOX
14
322
120
343
d(NbProies)/dt
13
0.0
1

TEXTBOX
138
484
473
502
= -c * NbPredateurs + d * NbProies * NbPredateurs
13
0.0
1

TEXTBOX
110
321
405
353
= a * NbProies - b * NbProies * NbPredateurs
13
0.0
1

TEXTBOX
11
484
146
503
d(NbPredateurs)/dt
13
0.0
1

MONITOR
1122
86
1236
139
NbProies
NbProies
1
1
13

MONITOR
1123
148
1234
201
NbPredateurs
NbPredateurs
1
1
13

CHOOSER
8
130
251
175
MethodeDeResolution
MethodeDeResolution
"Euler (standard)" "Runge-Kutta 4 (precise)"
1

BUTTON
196
180
374
213
Paramètres prédéfinis 2
AffecterValeursPredefinies2
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
16
730
212
783
Période
Periode
1
1
13

MONITOR
220
666
413
719
Nb Proies Equilibre (c/d)
NbProiesEquilibre
0
1
13

MONITOR
15
667
211
720
Nb Predateurs Equilibre (a/b)
NbPredateursEquilibre
0
1
13

SWITCH
1128
474
1260
507
HoldPhase?
HoldPhase?
1
1
-1000

MONITOR
219
731
413
784
Efficacité prédation (d/b)
Alpha
6
1
13

TEXTBOX
121
223
334
271
************************\nParamètres du modèle\n************************
15
0.0
1

TEXTBOX
139
37
326
85
*********************\nContrôle Simulation\n*********************
15
0.0
1

TEXTBOX
119
609
314
663
***********************\nPropriétés du modèle\n***********************\n
15
0.0
1

TEXTBOX
795
45
945
64
Résultats\n
15
0.0
1

TEXTBOX
1119
434
1323
462
Conservation du diagramme de phase entre chaque simulation
11
0.0
1

TEXTBOX
15
275
424
320
-----------------------------------------------\nEvolution du nombre de proies\n-----------------------------------------------
12
0.0
1

TEXTBOX
13
439
463
479
--------------------------------------------------------\nEvolution du nombre de prédateurs\n--------------------------------------------------------
12
0.0
1

@#$#@#$#@
## LE MODELE

Ce modèle permet d'étudier l'évolution du nombre de proies (NbProies) et de prédateurs (NbPredateurs) dont les variation sont soumises au système de deux équations différentielles ordinaires (EDO) de Lotka-Volterra pour des conditions initiales et des valeurs de paramètres fixés par l'utilisateur dans l'interface. 

Le modèle est formalisé par un système de deux équations différentielles, décrivant la variation du nombre de proies et de prédateurs par pas de temps dt :
d(NbProies)/dt =  a.NbProies  - b.NbProies.NbPredateurs
d(NbPredateurs)/dt = -c.NbPredateurs + d.NbProies.NbPredateurs

La description du modèle et de ses paramètres sont présentés dans la suite.

## VARIABLES ET PARAMETRES

NbProies : nombre de proies à l’instant t
d(NbProies)/dt : variation du nombre de proies à l’instant t (dérivée de x)
NbPredateurs : nombre de prédateurs à l’instant t
d(NbPredateurs)/dt : variation du nombre de prédateurs à l’instant t (dérivée de y)
a : taux de croissance des proies en l’absence de prédation (par unité de proie)
b : taux de mortalité des proies par prédation (par unité de proie et unité de prédateur)
c : taux de décroissance des prédateurs en l’absence de nourriture par prédation (par unité de prédateur)
d : taux de natalité des prédateurs grâce à la nourriture par prédation (par unité de prédateur et unité de proie)

## DESCRIPTION DU MODELE 

Dans sa version la plus fondamentale, le modèle Proie-Prédateur calcule l’évolution de l’effectif de deux populations en fonction du temps, prenant en compte 4 processus : 
* une augmentation de la population des proies par reproduction en l’absence des prédateurs
* une diminution de la population des proies du fait de la prédation par les prédateurs
* une diminution de la population des prédateurs par manque de nourriture en l’absence des proies
* une augmentation de la population des prédateurs par reproduction du fait de leur alimentation en proies

Le modèle est formalisé par un système de deux équations différentielles, décrivant la variation du nombre de proies et de prédateurs par pas de temps dt :
d(NbProies)/dt =  a.NbProies  - b.NbProies.NbPredateurs
d(NbPredateurs)/dt = -c.NbPredateurs + d.NbProies.NbPredateurs

La première équation exprime la variation de l’effectif des proies au cours du temps qui dépend d’une part de la croissance naturelle nette des proies (coefficient a, taux de natalité des proies en l'absence de prédateurs) et, d’autre part, de la mortalité par prédation (coefficient b, taux de mortalité des proies dû à la prédation). En l’absence de prédation, la population des proies augmente de manière exponentielle. Elle n’est pas dépendante de la présence d’une ressource. Cette hypothèse peut être acceptée dans la mesure où, du fait de la prédation, l’effectif des proies n’atteint pas une valeur telle que la disponibilité des ressources du milieu soit limitative. 

La seconde équation exprime la variation de l’effectif des prédateurs au cours du temps qui dépend d’une part, de la décroissance naturelle des prédateurs en l’absence de proies (coefficient c, taux de mortalité des prédateurs en l'absence de proies) et d’autre part, de la natalité suite à la prédation (coefficient d, taux d’efficacité de la prédation sur la croissance des prédateurs). En l’absence de capture, la population des prédateurs diminuera jusqu’à extinction. Ceci repose sur l’hypothèse que le prédateur en question n’a pas d’autre nourriture que les proies.

## RESULTATS

La dynamique caractéristique du modèle se traduit par l’apparition d’oscillations décalées dans le temps de l’effectif des deux populations : lorsque l’effectif des proies augmente, la prédation augmente ce qui a pour conséquence d’augmenter l’effectif des prédateurs après un certain temps. Cette augmentation a alors pour effet de diminuer l’effectif des proies, s’ensuit une augmentation de la mortalité des prédateurs. Ces oscillations s'observent également sur le « portrait de phase » qui permet de visualiser comment les effectifs des deux populations évoluent simultanément l'un par rapport à l'autre au cours du temps. Il fait apparaître différentes trajectoires. Chacune d’elle est associée à une simulation à partir d’un couple de conditions initiales.

Lorsque l’on fait varier les conditions initiales d'effectifs de proies et de prédateurs, les différentes trajectoires obtenues s’enroulent de manière concentrique autour d’un point particulier, correspondant à un point d’équilibre des effectifs (ou point fixe). 
Quelles que soient les conditions initiales, les trajectoires tournent toujours autour de ce point dont la position ne dépend que de la valeur des paramètres du modèle. Par contre, l’amplitude des fluctuations autour de ce point varie en fonction de la distance qui le sépare des conditions initiales .
La recherche et l'étude des points d'équilibres représente une partie importante de l'étude des systèmes dynamiques car c'est autour de ces points que s'organise le système. Ils permettent donc d'avoir une idée du comportement du modèle.
Un point d'équilibre est un point tel que si on choisi comme conditions initiales les coordonnées de ce point, on restera dessus. C'est donc un point pour lequel il n'y a pas de variation de l'état du système et donc pour lequel d(NbProies)/dt=0 et d(NbPredateurs)/dt=0.

Sur cette interface, il est ainsi possible de suivre l'évolution du nombre de proies et de prédateurs en fonction du temps (plot : Populations), mais également l'un en fonction de l'autre (plot : DiagrammeDePhase). Ce sont les trajectoires sur système de Lotka-Volterra.
Rappelons que le système étant déterministe, pour un jeu de paramètre et des conditions initiales fixés, la
Enfin, ce modèle permet d'obtenir les point d'équilibre ainsi que la période des oscillations.

## METHODES NUMERIQUES

Les méthodes numériques d'intégration de systèmes dynamique sont basés sur une méthode de discrétisation des équations continues. Elles utilisent l'itération précédente pour calculer l’itération suivante (c'est d'ailleurs pour cela que seule la condition initiale suffit pour calculer toute la solution). L'erreur numérique est la différence entre la solution obtenue numériquement et la solution théorique. Cette erreur s'accumule à chaque pas de temps au cours des simulations. Pour les méthodes dites à 1 pas (Euler, RK1), l'erreur finale est de l’ordre du pas d'intégration (PasDeTemps), tandis que pour les méthodes à pas multiples (n), comme RK4 est à 4 pas, l'erreur finale est de l'ordre de PasDeTemps^n (donc PasDeTemps^4 pour RK4), ce qui explique  que les résultats obtenus sont beaucoup plus proches de la solution explicite du système. En général on utilise des pas d'intégration au moins de l'ordre de 10^{-2} ou 10^{-3}, on passe donc d'une erreur de cet ordre à une erreur de l'ordre de 10^{-8} ou 10^{-12} lorsque l'on passe de la méthode d'Euler à la méthode de Runge-Kutta d'ordre 4.

## COMMENT CA MARCHE ?

L'utilisateur peut utiliser des valeurs de conditions initiales et de paramètres prédéfinis. Il peut également définir lui même ces valeurs à l'aide des différents sliders (voir partie "VARIABLES ET PARAMETRES").

Pour chaque simulation, l'utilisateur peut choisir la méthode d'intégration numérique ainsi que le pas d'intégration (voir partie "METHODES NUMERIQUES". 

De plus, si l'utilisateur souhaite lancer des simulations avec des paramètres ou des conditions initiales différentes, il lui ai possible de garder en mémoire dans le plot "DiagrammeDePhase" les résultats des simulations précédentes en mettant sur "on" le "switch : HoldPhase?".

1. Fixer les valeurs de paramètres et les conditions initiales.
2. Choisir la méthode d'intégration numérique et fixer le pas d'intégration.
3. Presser le bouton SETUP.  
4. Presser le bouton GO.  
5. Observer les résultats sur les moniteurs et les plots et les interpréter.

## AUTEURS

M. Amalric - UMR 7324 CITERES - Tours France 
S. Caillault - UMR 6590 ESO - Angers France 
N. Corson - EA 3821 LMAH - Le Havre France 
P. Langlois - UMR 6266 IDEES - Rouen France 
C. Monteil - UMR 1201 DYNAFOR INPT-INRA - Toulouse France 
N. Marilleau - UMI 209 UMMISCO - IRD/UPMC - Bondy France 
D. Sheeren - UMR 1201 DYNAFOR INPT-INRA - Toulouse France

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

sheep
false
15
Rectangle -1 true true 166 225 195 285
Rectangle -1 true true 62 225 90 285
Rectangle -1 true true 30 75 210 225
Circle -1 true true 135 75 150
Circle -7500403 true false 180 76 116

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

wolf
false
0
Rectangle -7500403 true true 195 106 285 150
Rectangle -7500403 true true 195 90 255 105
Polygon -7500403 true true 240 90 217 44 196 90
Polygon -16777216 true false 234 89 218 59 203 89
Rectangle -1 true false 240 93 252 105
Rectangle -16777216 true false 242 96 249 104
Rectangle -16777216 true false 241 125 285 139
Polygon -1 true false 285 125 277 138 269 125
Polygon -1 true false 269 140 262 125 256 140
Rectangle -7500403 true true 45 120 195 195
Rectangle -7500403 true true 45 114 185 120
Rectangle -7500403 true true 165 195 180 270
Rectangle -7500403 true true 60 195 75 270
Polygon -7500403 true true 45 105 15 30 15 75 45 150 60 120

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
setup
set grass? true
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

globals
[
  patch-unit-size     ; size of the patches in meters 
  step-duration       ; diuration of a time step in seconds 
  patch-limitation    ; allowing more than one sheep on a patch ? 
  year-duration       ; duration of a year
  day-duration        ; duration of a day   
  
  ; Initiale Populations
  ;Sheep
  initial-sheep-pop
  ; Wolves
  initial-wolf-pop
  
  
  ; State Variables of the model 
  nbwolves-toborn
  nbsheeps-toborn
  nbwolves-todie
  nbsheeps-todie
  predation-rate-list
  
  ; Variables containing the model outputs 
  b-rate-list
  b-rate
  
]

; Definition of species
;  - wolves characteristics   
breed [wolves wolf]
wolves-own [nb-eat-sheep]

; - sheep characteristics
breed [sheeps sheep]
sheeps-own [ nearest-neighbor ]
patches-own [is-forest? ] 

; Initialization of the model
to setup
  clear-all 
  setup-global
  setup-patches
  setup-prey init-sheep-pop
  setup-predator init-wolves-pop
  reset-ticks
end

; Initialization of global variables to calibrate the model 
to setup-global
  set  patch-unit-size 100               ; one patch corresponds to 1 Ha
  set  step-duration 60                  ; one time step corresponds to 1 minute 
  set  day-duration 2 * 3600 / step-duration
  set  year-duration 90                  ; in the model, 1 year = 90 days 
  set  patch-limitation  false           ; no patch limitation 
  set  initial-sheep-pop init-sheep-pop  ;
  
  set nbwolves-toborn 0
  set nbsheeps-toborn 0
  set nbwolves-todie  0
  set nbsheeps-todie  0
  set predation-rate-list []
  set b-rate-list []
  set b-rate 0
end

; Creation and initialization of prey
to setup-prey [ nbPrey]
  create-sheeps nbPrey
  [
    let curPatch one-of patches
    if patch-limitation 
    [
      set curPatch one-of patches with [ ( count turtles-here ) = 0] 
    ]  
    
    let x 0
    let y 0
    set x random-xcor
    set y random-ycor
    setxy x y
    set shape "sheep"
    set color white
    set size 5
    
 ]
end

; Creation and initialization of predators 
to setup-predator [nbpred]
  create-wolves nbpred
  [
   
   let curPatch one-of patches
   if patch-limitation 
   [
    set curPatch one-of patches with [ ( count turtles-here ) = 0] 
   ] 
   setxy [pxcor] of curPatch [pycor] of curPatch
   set shape "wolf"
   set color black
   set size 5
   set nb-eat-sheep 0
  ]
end

; Initialization of the environment
to setup-patches
  ask patches
  [
    ifelse heterogenety and random-float 1 < wood-density
    [
      set is-forest? true
      set pcolor brown
    ]
    [
      set is-forest? false
      set pcolor green
    ] 
  ]
  
end


; Management of one time step for wolves, sheep and environment 
to go
  go-sheeps
  go-wolves
  
  if ticks mod day-duration = 0
  [
    go-day
  ]
  tick
end

; from one day to the next
to go-day
  go-day-sheep
  go-day-wolf
  init-new-day
end

; action of sheep between one day and the next
to go-day-sheep
  born-sheep
end

; action of wolves between one day and the next
to go-day-wolf
  kill-wolf
  born-wolf
end

; management of the sheep life-cycle 
to go-sheeps
  ask sheeps
  [
    go-sheep
  ]
end

; behaviour of a sheep
to go-sheep
  fd sheep-speed * step-duration / patch-unit-size
end

; management of the wolves life-cycle 
to go-wolves
  ask wolves
  [
    go-wolf
    eat-wolf
  ]
end

; moving behaviour of a wolf
to go-wolf
  lt (( random 120) - 60)
  fd wolf-speed * step-duration / patch-unit-size
end

; dying behaviour of a wolf
to kill-wolf
  set nbwolves-todie nbwolves-todie + (count wolves * wolf-die / year-duration )
  if nbwolves-todie >= 1
  [
    ask n-of (int  nbwolves-todie) wolves
    [
     die 
    ]
    set nbwolves-todie nbwolves-todie - (int  nbwolves-todie)
  ]
end


; passage to a new day 
to init-new-day
 do-plots
 init-wolves
 set initial-wolf-pop count wolves
 set initial-sheep-pop count sheeps 
end


; initialization of the number of sheep eaten by each wolf 
to init-wolves
  ask wolves
  [
    set nb-eat-sheep 0
  ]
end

; birth behaviour of wolves
to born-wolf
  
    let nb-predation (sum [nb-eat-sheep] of wolves)
    set nbwolves-toborn nbwolves-toborn + (nb-predation * wolf-born-rate  )
  
  if nbwolves-toborn >= 1
  [
    setup-predator (int  nbwolves-toborn)
    set nbwolves-toborn nbwolves-toborn - (int  nbwolves-toborn)
  ]
end

; birth behaviour of sheep 
to born-sheep
  set nbsheeps-toborn nbsheeps-toborn + (count sheeps * sheep-born-rate / year-duration )
  
  if nbsheeps-toborn >= 1
  [
    setup-prey (int  nbsheeps-toborn)
    set nbsheeps-toborn nbsheeps-toborn - (int  nbsheeps-toborn)
  ]
end

; capture behaviour of sheep by a wolf  
to eat-wolf
   let currSheep  one-of sheeps with [ ( false = [is-forest?] of patch-here and (distance myself  ) < predating-distance / patch-unit-size ) or ( [is-forest?] of patch-here and (distance myself  ) < predating-distance * 0.5 / patch-unit-size ) ]
  if currSheep != nobody
   [
     ask currSheep
     [
       die 
     ]
     set nb-eat-sheep nb-eat-sheep + 1
   ]    
end

; plots in the interface
to do-plots
  set-current-plot "population"
  set-current-plot-pen "sheep-pop"
  
  let nbSh  count sheeps
  plot nbSh
  set-current-plot-pen "wolf-pop"
  plot count wolves * 100
  
 
   if initial-wolf-pop != 0 and initial-sheep-pop != 0
  [
   set-current-plot "predation-rate"
   set-current-plot-pen "predation-rate"
 
   let nb-shp-eat ( sum [nb-eat-sheep] of wolves )
   let predating-rate  nb-shp-eat /  initial-wolf-pop
   set predation-rate-list  lput predating-rate predation-rate-list
   
   set b-rate predating-rate / initial-sheep-pop
   set b-rate-list  lput b-rate b-rate-list
   
   plot predating-rate
   set-current-plot-pen "predation-rate-list"
   plot mean predation-rate-list
   
   
   set-current-plot "vulnerability-coef"
   set-current-plot-pen "b"
   plot b-rate  
   
   set-current-plot-pen "b-mean"
   plot mean b-rate-list  
  
  ]
  
  set-current-plot "sheep-wolf"
  set-current-plot-pen "sheep-wolf"
  plotxy count sheeps count wolves
end


; B coefficient computation / simulation 
to-report f-b-rate
     let nb-shp-eat ( sum [nb-eat-sheep] of wolves )
   ifelse  initial-wolf-pop = 0 or initial-sheep-pop = 0
   [
     report 0
   ]
   [
   let predating-rate  nb-shp-eat /  initial-wolf-pop   
   report  predating-rate / initial-sheep-pop
   ]
end


; Mean predation coefficient computation 
to-report f-predating
     ifelse  initial-wolf-pop = 0 or initial-sheep-pop = 0
   [
     report 0
   ]
   [
     let nb-shp-eat ( sum [nb-eat-sheep] of wolves )
     report   nb-shp-eat /  initial-wolf-pop
   ]
end
@#$#@#$#@
GRAPHICS-WINDOW
726
61
1258
614
-1
-1
2.6
1
10
1
1
1
0
1
1
1
0
200
0
200
0
0
1
ticks
30.0

BUTTON
14
12
87
45
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
116
13
179
46
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
475
100
679
133
init-sheep-pop
init-sheep-pop
0
5000
820
1
1
->833
HORIZONTAL

SLIDER
475
138
680
171
init-wolves-pop
init-wolves-pop
0
500
29
1
1
->30
HORIZONTAL

SLIDER
239
136
457
169
wolf-speed
wolf-speed
0
2
0.95
0.05
1
M/S
HORIZONTAL

SLIDER
239
175
458
208
sheep-speed
sheep-speed
0
2
0.5
0.02
1
M/S
HORIZONTAL

SLIDER
13
98
218
131
sheep-born-rate
sheep-born-rate
0
2
1.5
0.01
1
a
HORIZONTAL

SLIDER
13
135
218
168
wolf-die
wolf-die
0
1
0.25
0.01
1
c
HORIZONTAL

SLIDER
12
173
219
206
wolf-born-rate
wolf-born-rate
0
1
0.0060
0.01
1
d/b
HORIZONTAL

SWITCH
271
260
429
293
heterogenety
heterogenety
1
1
-1000

SLIDER
238
99
457
132
predating-distance
predating-distance
0
1000
25
1
1
M
HORIZONTAL

SLIDER
242
301
461
334
wood-density
wood-density
0
1
0.3
0.01
1
NIL
HORIZONTAL

PLOT
13
387
213
537
sheep-wolf
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"sheep-wolf" 1.0 0 -7500403 true "" ""

PLOT
227
386
427
536
population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"sheep-pop" 1.0 0 -7500403 true "" ""
"wolf-pop" 1.0 0 -2674135 true "" ""

PLOT
13
557
213
707
predation-rate
step
nb moutons
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"predation-rate" 1.0 0 -7500403 true "" ""
"predation-rate-list" 1.0 0 -2674135 true "" ""

PLOT
228
555
428
705
vulnerability-coef
NIL
NIL
0.0
0.0020
0.0
0.0020
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"b" 1.0 0 -7500403 true "" ""
"b-mean" 1.0 0 -2674135 true "" ""

MONITOR
454
387
532
432
day
floor (ticks / day-duration)
17
1
11

MONITOR
454
435
533
480
wolves nb
count wolves
17
1
11

MONITOR
540
433
614
478
sheep nb
count sheeps
17
1
11

MONITOR
453
488
654
533
nb sheep evolution
initial-sheep-pop - count sheeps
17
1
11

MONITOR
540
385
648
430
predation rate
( initial-sheep-pop - count sheeps ) / count sheeps
17
1
11

TEXTBOX
33
73
223
91
Mathematical model parameters
10
0.0
1

TEXTBOX
263
74
460
101
Agent-based model parameters
10
0.0
1

TEXTBOX
513
75
663
93
Global model parameters
10
0.0
1

TEXTBOX
314
355
501
373
MODEL OUTPUTS
12
0.0
1

TEXTBOX
313
44
463
62
MODEL PARAMETERS
12
0.0
1

TEXTBOX
262
230
438
256
Spatial heterogeneity parameters
10
0.0
1

@#$#@#$#@
## INTRODUCTION

Modelling predator-prey dynamics has a great importance in ecology. Models based on differential equations aim to understand the interactions between populations of prey and predators at a global (macro) scale but are unable to handle spatial and individual-behaviour heterogeneities (micro scale). Some authors published individual-based models relying on strong assumptions that limit the scope of the results, for example adding a food resource for the prey, or limiting the number of individuals per patch. In this study, we propose an approach that build an individual-based model from the archetypical Lotka-Volterra global model using a micro scale only for the predation process, leaving at a macro scale the processes of reproduction for both species and natural death of predators. Local rules were defined for individual movements of prey and predators, and the predation process was related to a perception distance of predators and the presence of shelters for prey in the spatial environment. The choices of spatial and temporal granularities are discussed. Simulations showed an overall classic periodic evolution of population sizes with local variations. The global predation rate and birth rate of predators were computed during the individual-based simulations and then analysed. The model was implemented on the NetLogo platform. This work illustrates how both micro and macro scales may be linked through methodological choices in order to focus on the effects of spatialisation and to take into account the effects of spatial and individual heterogeneities.


## GOALS
- Introducing students to population dynamics and to modeling in this field based on a classical basic example.
- Showing both micro and macro modeling approaches of the same populations dynamics problem.. 
- Showing the main differences between micro and macro levels of modeling, especially concerning spacialization and temporality. 
- Comparing structures and functioneing (inputs and outputs) of both micro and macro models to understand their main differences.

## AUTHORS
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
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

sheep 2
false
0
Polygon -7500403 true true 209 183 194 198 179 198 164 183 164 174 149 183 89 183 74 168 59 198 44 198 29 185 43 151 28 121 44 91 59 80 89 80 164 95 194 80 254 65 269 80 284 125 269 140 239 125 224 153 209 168
Rectangle -7500403 true true 180 195 195 225
Rectangle -7500403 true true 45 195 60 225
Rectangle -16777216 true false 180 225 195 240
Rectangle -16777216 true false 45 225 60 240
Polygon -7500403 true true 245 60 250 72 240 78 225 63 230 51
Polygon -7500403 true true 25 72 40 80 42 98 22 91
Line -16777216 false 270 137 251 122
Line -16777216 false 266 90 254 90

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
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.5
@#$#@#$#@
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


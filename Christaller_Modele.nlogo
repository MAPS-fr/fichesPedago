Globals [nb_producers1 nb_producers2 nb_producers3 cons_per_prod1 cons_per_prod2 cons_per_prod3 percentage_satisfied1 percentage_satisfied2 percentage_satisfied3 size_max]

Breed [ producers producer ]
Breed [ consumers consumer ]

producers-own [my_nb_consumers1 my_nb_consumers2 my_nb_consumers3 service_level satisfaction price_service1 price_service2 price_service3]
consumers-own [my_producer1 my_producer2 my_producer3]

To setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  ask patches [ sprout-consumers 1 ]
  set size_max sqrt (((min-pxcor - max-pxcor) * (min-pxcor - max-pxcor)) + ((min-pycor - max-pycor) * (min-pycor - max-pycor)))
  ask consumers  
  [
    set color white
    set size 0.3 
    set hidden? false  
    set shape "square"
    set heading 0         
  ]

  
End

To go 

  if all? producers [ satisfaction = 1]
  [
    stop
  ]
  ;movie-grab-view
; print movie-status
 
  calculate-allocation-consumers-producers
  create-links
  calculate-satisfaction
  movements
  do-plots
  do-histogram
  tick 
End


to create-level-1
create-producers 27
 ;ask producers
    [
         setxy random-xcor random-ycor 
         set shape "circle" 
         set color red
         set size 0.5
         set service_level 1    
    ]
 set cons_per_prod1 ceiling(count (consumers) / count(producers))
 setup-histogram_level1   
end

to create-level-2
create-producers 9
  [         set service_level 2 
            set shape "circle" 
            set  color yellow
            set size 1.5 
            setxy random-xcor random-ycor
     ]
 set cons_per_prod1 ceiling(count (consumers) / count(producers))
 set cons_per_prod2 ceiling(count(consumers) / count(producers with [service_level >= 2]))
 setup-histogram_level2   
  do-plots 
end

to create-level-3  
  
create-producers 3  
 [   set service_level 3 
     set shape "circle" 
     set  color green
     set size 2.3
     setxy random-xcor random-ycor
  ]
 
 set cons_per_prod1 ceiling(count (consumers) / count(producers))
 set cons_per_prod2 ceiling(count(consumers) / count(producers with [service_level >= 2]))
 set cons_per_prod3 ceiling(count(consumers) / count(producers with [service_level >= 3]))
 setup-histogram_level3    
  do-plots 
end
  

To calculate-allocation-consumers-producers
  clear-links
  ask producers
  [
    set  my_nb_consumers1 0   
    set  my_nb_consumers2 0
    set  my_nb_consumers3 0    
  ]
  
  let producers2 producers with [service_level >= 2]
  let producers3 producers with [service_level >= 3]

  ask consumers
  [
    set my_producer1 one-of producers with-min [ (distance myself) / size_max * (1 - Distance_Price_Service1) + (price_service1 * Distance_Price_Service1) ]
    ask my_producer1
    [
      set my_nb_consumers1 my_nb_consumers1 + 1
    ]
    if (any? producers2)
    [
      set my_producer2 one-of producers2 with-min [ (distance myself)/ size_max * (1 - Distance_Price_Service2) + (price_service2 * Distance_Price_Service2) ]
      ask my_producer2
      [
        set my_nb_consumers2 my_nb_consumers2 + 1
      ]    
    ]
    if (any? producers3)
    [
      set my_producer3 one-of producers3 with-min [ (distance myself)/ size_max * (1 - Distance_Price_Service3) + (price_service3 * Distance_Price_Service3) ]
      ask my_producer3
      [
        set my_nb_consumers3 my_nb_consumers3 + 1
      ]    
    ]
  ]
  update_prices
End


To calculate-satisfaction
  ask producers
  [
    ifelse ((my_nb_consumers1 * (1 + adjustment_factor) >= cons_per_prod1) 
      and (service_level < 2 or my_nb_consumers2 * (1 + adjustment_factor)  >= cons_per_prod2) 
      and (service_level < 3 or my_nb_consumers3 * (1 + adjustment_factor) >= cons_per_prod3))  
    [
      set satisfaction 1 
    ]
    [
      set satisfaction 0
                
    ]
  ]   
End

To update_prices
   ask producers
   [
    ifelse my_nb_consumers1 = 0
     [set price_service1 1]
     [set price_service1 (1 / my_nb_consumers1)]
    ifelse my_nb_consumers2 = 0
     [set price_service2 1]
     [set price_service2 (1 / my_nb_consumers2)]
    ifelse my_nb_consumers3 = 0
     [set price_service3 1]
     [set price_service3 (1 / my_nb_consumers3)]
   ]
End 



To movements
  ask producers with [ satisfaction = 0]
  [
    to-move
    ;ask my-links with [ color = green ] [ die ]
  ]
  create-links  
end 



to create-links 
  clear-links
  ask consumers
  [
    create-link-with  my_producer1 [ set color red ]
    ifelse links1? 
    [
      ask link-with my_producer1 [ show-link ]
    ]
    [
      ask link-with my_producer1 [ hide-link ]
    ]
    if any? producers with [ service_level >=  2 ]
    [
      create-link-with  my_producer2 [ set color yellow ] 
      ifelse  links2?
      [
        ask link-with my_producer2 [ show-link ]
      ]
      [
        ask link-with my_producer2 [ hide-link ]
      ]
    ]
    if any? producers with [ service_level =  3 ]
    [
      create-link-with  my_producer3 [ set color green ]      
      ifelse  links3?
      [
        ask link-with my_producer3 [ show-link ]
      ]
      [
        ask link-with my_producer3 [ hide-link ]
      ]
    ]
  ]
end 

to show-links
  ifelse links1? 
  [ask links with [color = red] [set hidden? false]]
  [ask links with [color = red] [set hidden? true]]
  
  ifelse links2? 
  [ask links with [color = yellow] [set hidden? false]]
  [ask links with [color = yellow] [set hidden? true]]
  
  ifelse links3? 
  [ask links with [color = green] [set hidden? false]]
  [ask links with [color = green] [set hidden? true]]
end


To to-move
  let list_x [ ]
  let list_y [ ]
  let my_consumers []
  if service_level = 1 [set my_consumers consumers]
  if service_level = 2 [set my_consumers consumers with [my_producer2 != 0]]
  if service_level = 3 [set my_consumers consumers with [my_producer3 != 0]]
  
  ask link-neighbors
  [  
    set list_x fput xcor list_x
    set list_y fput ycor list_y
  ]
  ifelse (empty? list_x)
  [
     if (service_level = 1) [
        face one-of producers with-max [ my_nb_consumers1 ]
        fd random Maximum_distance1
      ]
      if (service_level = 2) [
        face one-of producers with-max [ my_nb_consumers2 ]
        fd random Maximum_distance2
      ]
      if (service_level = 3) [
        face one-of producers with-max [ my_nb_consumers3 ]
        fd random Maximum_distance3
      ]
  ]
  [
    let x-barycentre mean list_x 
    let y-barycentre mean list_y 
    ifelse (x-barycentre = xcor and y-barycentre = ycor and satisfaction = 0) 
    [ 
      if (service_level = 1) [
        face one-of producers with-max [ my_nb_consumers1 ]
        fd random Maximum_distance1
      ]
      if (service_level = 2) [
        face one-of producers with-max [ my_nb_consumers2 ]
        fd random Maximum_distance2
      ]
      if (service_level = 3) [
        face one-of producers with-max [ my_nb_consumers3 ]
        fd random Maximum_distance3
      ]
    ]
    [
    setxy mean list_x mean list_y
    ] 
  ]
end 

to setup-histogram_level1
  set-current-plot "nb consumers per producer - service 1"
  set-plot-x-range 0 (count consumers) / 10.0
  set-plot-y-range 0 count producers
  set-histogram-num-bars 20
end

to setup-histogram_level2
  set-current-plot "nb consumers per producer - service 2"
  set-plot-x-range 0 (count consumers) / 5.0
  set-plot-y-range 0 count producers with [service_level >= 2]
  set-histogram-num-bars 20
end


to setup-histogram_level3
  set-current-plot "nb consumers per producer - service 3"
  set-plot-x-range 0 (count consumers) / 2.0
  set-plot-y-range 0 count producers with [service_level >= 3]
  set-histogram-num-bars 20
end



to do-plots
  set percentage_satisfied1 count producers with [service_level = 1 and satisfaction = 1] * 100 / (count producers with[service_level = 1])
  if any? producers with[service_level = 2] [ set percentage_satisfied2 (count producers with [service_level = 2 and satisfaction = 1] * 100 / (count producers with[service_level = 2]))]
  if any? producers with[service_level = 3] [ set percentage_satisfied3 (count producers with [service_level = 3 and satisfaction = 1] * 100 / (count producers with[service_level = 3]))]
  set-current-plot "Satisfied producers"
  set-current-plot-pen "producers1"
  plot percentage_satisfied1
  set-current-plot-pen "producers2"
  plot percentage_satisfied2
  set-current-plot-pen "producers3"
  plot percentage_satisfied3
end



to do-histogram
  set-current-plot "nb consumers per producer - service 1"
  set-current-plot-pen "producers1"
  histogram [my_nb_consumers1] of producers 
  set-current-plot "nb consumers per producer - service 2"
  set-current-plot-pen "producers2"
  histogram [my_nb_consumers2] of (producers with [service_level >= 2]) 
  set-current-plot "nb consumers per producer - service 3"
  set-current-plot-pen "producers3"
  histogram [my_nb_consumers3] of (producers with [service_level >= 3])
end
@#$#@#$#@
GRAPHICS-WINDOW
234
11
716
514
16
16
14.303030303030303
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
24
20
95
53
Setup
Setup\n\ncreate-level-1\ncreate-level-2  \ncreate-level-3  
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
108
21
171
54
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
115
280
213
313
Hide Consumers
ask consumers [set hidden? true]
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
115
317
214
350
Show Consumers
ask Consumers [set hidden? false set color white]
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
6
279
109
312
Links1?
Links1?
0
1
-1000

SWITCH
6
311
109
344
Links2?
Links2?
1
1
-1000

SWITCH
6
343
109
376
Links3?
Links3?
1
1
-1000

SLIDER
9
90
181
123
Maximum_distance1
Maximum_distance1
0
32
4
1
1
NIL
HORIZONTAL

SLIDER
9
122
181
155
Maximum_distance2
Maximum_distance2
0
32
4
1
1
NIL
HORIZONTAL

SLIDER
9
154
181
187
Maximum_distance3
Maximum_distance3
0
33
4
1
1
NIL
HORIZONTAL

SLIDER
7
222
199
255
adjustment_factor
adjustment_factor
0
1
0
0.1
1
NIL
HORIZONTAL

PLOT
721
13
1255
168
Satisfied producers
time
Percentage of satisfied producers
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"producers1" 1.0 0 -2674135 true "" ""
"producers2" 2.0 0 -4079321 true "" ""
"producers3" 2.0 0 -10899396 true "" ""

SLIDER
7
440
195
473
Distance_Price_Service2
Distance_Price_Service2
0
1
0
0.1
1
NIL
HORIZONTAL

SLIDER
7
472
195
505
Distance_Price_Service3
Distance_Price_Service3
0
1
0
0.1
1
NIL
HORIZONTAL

PLOT
720
173
1256
334
nb consumers per producer - service 1
nb consumers
nb producers
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"producers1" 1.0 1 -2674135 true "" ""

PLOT
720
339
993
504
nb consumers per producer - service 2
nb consumers
nb producers
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"producers2" 1.0 1 -7171555 true "" ""

PLOT
997
339
1258
504
nb consumers per producer - service 3
nb consumers
nb producers
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"producers3" 1.0 1 -10899396 true "" ""

SLIDER
8
408
195
441
Distance_Price_Service1
Distance_Price_Service1
0
1
0
0.1
1
NIL
HORIZONTAL

TEXTBOX
11
77
161
95
Max Distance of relocation
11
0.0
1

TEXTBOX
8
209
158
227
Adjustement factor
11
0.0
1

TEXTBOX
13
392
163
420
Distance or Price
11
0.0
1

TEXTBOX
9
266
164
284
Links
11
0.0
1

TEXTBOX
122
268
272
286
Consummers
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@

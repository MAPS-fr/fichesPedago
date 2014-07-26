;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; DECLARATIONS DE VARIABLES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

breed [cities city ]
breed [agriculteurs agriculteur]
breed [exploitations exploitation]

agriculteurs-own [
  monExploitation
  typeComportement
  ]

patches-own [
  proprietaire
  chgtCulture ; flag marquant l'année où le patch à changé de culture
  culture ; culture en cours
  cityMarket ; marché utilisé
  nextCulture ; culture choisie 
  nextCity    ; marché choisi 
  rente  ; rente actuelle de la parcelle (celle induite de la culture en cours)
  ]

cities-own [
  prixCourantI
  prixCourantF
  prixCourantC
  prixCourantR
  qteCourante
  ]

globals [
  culturesList
  rendementsList
  transportsList
  prixMarcheList
  coutProdList
  colorList
  plotsList
  propList
  propResistants
  demandeCourantI 
  demandeCourantF 
  demandeCourantC 
  demandeCourantR 
  cityObserved
  propI
  propC
  propF
  propR
]




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;   INITIALISATION   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
   __clear-all-and-reset-ticks
  
  ; initialisations 
  build-city ; création des villes
  build-lists ; création des listes
  ask patches[  ;initialisation des parcelles
    set pcolor black 
    set culture 0 
  ]
  build-agriculteurs ; création des agriculteurs
  tick
  
end

to setupVT
  setup 
  ask agriculteurs[ask monExploitation [
    let combiOptimale calculerCultureEtVilleVT
    let renteMax item 0 combiOptimale
    let indMax item 1 combiOptimale
    let cityChosen item 2 combiOptimale 
    ifelse(renteMax <= 0) [
      set culture 0
      set rente 0 
      set pcolor black
      set cityMarket one-of cities
      ][
      set culture item indMax culturesList
      set cityMarket cityChosen
      set rente renteMax
      set pcolor item indMax colorlist
      ]
     set nextCulture culture]]
end


; creation des agriculteurs - il y a 1 agriculteur par patch 
to build-agriculteurs
  ask patches [ ; chaque patch se cree un agriculteur
    if count cities-here = 0 [
      init_agriculteur_on_me
    ]]
end



; methode de patch
; initialisation de son agriculteur
to init_agriculteur_on_me

  let typeCulture 0
  let renteCurrent 0

  ; création de l'agriculteur
  sprout-agriculteurs 1 [

   set size 0.9
   set shape "circle"
   set color black 
   move-to myself 

   ; creation de l'exploitation
   set monExploitation myself    
   ask myself [set proprietaire self]

  ; si comportement diversifies, tirage du comportement de l'agriculteur, sinon comportement = VT 
  ifelse comportementAgriculteurs = "diversifiés" [
    let listProps (list optimisateursVT sous-optimisateurs aversesRisque obsIntelligents earlyAdopters followers resistants)
    let listRefs (list "VT"  "SO" "AR" "OI" "EA" "F" "R") 
    let listShapes (list "star" "x" "triangle" "circle 2" "square 2" "dot" "line")
    set typeComportement tirageSelonDistributionDans listProps listRefs
    set shape item (position typeComportement listRefs) listShapes
  ][set typeComportement "VT"]
 ]
 
 ; initialisation du type de culture : tirage 
 let listProps n-values NombreProduits [1]; tirage equiprobable
 let listIndex n-values NombreProduits [?]
 set typeCulture tirageSelonDistributionDans listProps listIndex 

 ; mise en place de la culture sur le patch 
 set culture item typeCulture culturesList
 set chgtCulture (- random 50) - 1 ; initialisation à nbr negatif aleatoire pour que les chgts soient echelonnés si inertie 
 set nextCulture culture
 set pcolor item typeCulture colorList  

 ; attribution du marché 
 set cityMarket one-of cities
 ask cityMarket [ set renteCurrent calculerRenteReportCity typeCulture]
 set rente renteCurrent
 set nextCity cityMarket
end


; creation des villes 
to build-city
  create-cities NombreVilles
  [set size 2
    setxy random-xcor random-ycor 
    set shape "circle"
    set color yellow
    set chgtCulture 0
    set culture 0  
    set prixCourantI prixMarcheI
    set prixCourantF prixMarcheF
    set prixCourantC prixMarcheC
    set prixCourantR prixMarcheR
    set qteCourante [0 0 0 0]
  ]
end


; creation des listes 
to build-lists
  set culturesList (list "I" "F" "C" "R") 
  set propList (list propI propF propC (1 - propI - propF - propC))
  set rendementsList (list rendementI rendementF rendementC rendementR)
  set transportsList (list transportI transportF transportC transportR)
  set prixMarcheList (list prixMarcheI prixMarcheF prixMarcheC prixMarcheR) 
  set coutProdList (list coutProdI coutProdF coutProdC coutProdR)
  set colorList (list red white blue green)
  set plotsList (list "I" "F" "C" "R")
  set demandeCourantI demandeI
  set demandeCourantF demandeF
  set demandeCourantC demandeC
  set demandeCourantR demandeR
  set cityObserved one-of cities
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;   RUN ET ROUTINES DE RUN  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go

  

  ; rafraichissement des listes
  update-lists
  
  ; mort des agents 
  ask agriculteurs [
    let rand random-float 1
    if rand < probaMort [ ; mourir revient a changer de culture aleatoirement, un autre agent vient 
      ask patch-here [init_agriculteur_on_me]
      die
       ]]
  
  ; evolution des cultures des agriculteurs 
  ; choix d'une nouvelle culture 
  ask agriculteurs [choisirCulture]
  ; installation de la nouvelle culture
  ask agriculteurs [installerNextCulture]

  
  ; creation de villes à la volée
  if mouse-down? [
    user-message "mouse-down!"]
  
  ; evolution des marches
    ask cities [
      update-market
    ]
  
  ; update plots et temsp
  do-plots
  tick
  
end


to update-lists
  set rendementsList (list rendementI rendementF rendementC rendementR)
  set transportsList (list transportI transportF transportC transportR)
  set coutProdList (list coutProdI coutProdF coutProdC coutProdR)
  set prixMarcheList (list prixMarcheI prixMarcheF prixMarcheC prixMarcheR)
  set demandeCourantI demandeI
  set demandeCourantF demandeF
  set demandeCourantC demandeC
  set demandeCourantR demandeR
end






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;   COMPORTEMENTS DES AGRICULTEURS  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; methode de agriculteur 
; choisit une culture selon son type de comportement
; dans le cas comportement = Von Thunen, tous les agriculteurs ont été initialisés avec typeComportement = VT 
to choisirCulture

  let renteMax 0 
  let patchMax patch-here
  let cityChosen one-of cities
  let indMax 0 
  let cultureMax culture 

  if (ticks - chgtCulture) > (inertie ) [ 

    ; il n'y a choix de culture que si la phase d'inertie est terminée
    ; cela inclut la banqueroute
    if typeComportement = "VT" [; maximisateurs de la rente au sens de VT 
      ask monExploitation [
        let combiOptimale calculerCultureEtVilleVT
        set renteMax item 0 combiOptimale
        set indMax item 1 combiOptimale
        set cityChosen item 2 combiOptimale 
        ifelse(renteMax <= 0) [
          set nextCulture 0
          set nextCity one-of cities][
        set nextCulture item indMax culturesList
        set nextCity cityChosen]
      ]]
    
    if typeComportement = "SO" [; tirage d'une culture pondéré par sa rente parmi cultures à rente > 0 
      ;;; ATTENTION NE MARCHE BIEN QUE POUR UN SEUL MARCHE, IL NE CHERCHE JAMAIS A CHANGER DE MARCHE...
      let rentes n-values nombreProduits [0]
      ask cityMarket [set rentes map [calculerRenteReportCity ?] (n-values nombreProduits [?])]
      ifelse length filter [? >= 0] rentes > 0 [ ; il existe au moins une culture à rente > 0 : tirage
        let positiveIndexes filter [item ? rentes >= 0] (n-values nombreProduits [?])
        let positivesRentes filter [? >= 0] rentes 
        let indNext tirageSelonDistributionDans positivesRentes positiveIndexes
        set nextCulture item indNext culturesList        
      ][ ; il n'existe pas de culture à rente  > 0 : friche
          set nextCulture 0
          set nextCity one-of cities      
      ] 
    ]
    
    
    if typeComportement = "AR" [; tirage d'une culture pondéré par son cout de production parmi cultures à rente > 0 
      let invCoutProds map [1 / ?]  coutProdList
show invCoutProds      
      let rentes n-values nombreProduits [0]      
      ask cityMarket [set rentes map [calculerRenteReportCity ?] (n-values nombreProduits [?])]
show rentes      
      ifelse length filter [? >= 0] rentes > 0 [ ; il existe au moins une culture à rente > 0 : tirage
        let positiveIndexes filter [item ? rentes >= 0] (n-values nombreProduits [?])
show positiveIndexes       
show rentes
show  invCoutProds
        let positivesCoutsProd filter [item ? rentes >= 0] invCoutProds 
show positivesCoutsProd        
        let indNext tirageSelonDistributionDans positivesCoutsProd positiveIndexes
        set nextCulture item indNext culturesList        
      ][ ; il n'existe pas de culture à rente  > 0 : friche
          set nextCulture 0
          set nextCity one-of cities      
      ] 
    ]
    
        
    if typeComportement = "OI" [; les OI regardent autour d'eux et prennent la culture max si superieure a leur rente
      set patchMax max-one-of neighbors [rente]
      if [rente] of patchMax > rente [ ; si ils sont en negatif et que autour d'eux le mieux est de ne rien faire alors ils ne font rien ! 
        set nextCulture [culture] of patchMax
        set nextCity [cityMarket] of patchMax
      ] 
    ]
    


    if typeComportement = "EA" [; les EA regardent si il y a une nouvelle culture autour d'eux et l'adoptent - random si il y en a plusieurs 
      set patchMax one-of neighbors with [(chgtCulture > 0) and ((ticks - chgtCulture) <= inertie + 1)]
      if not (patchMax = nobody) [
        set nextCulture [culture] of patchMax
        set nextCity [cityMarket] of patchMax
      ]
    ]
    
    if typeComportement = "F" [; les F regardent si une culture est majoritaire autour d'eux
      foreach culturesList [
        set indMax count neighbors with [culture = ?]
        if indMax >= 4 [
          set nextCulture ?
          set nextCity [cityMarket] of (one-of (neighbors with [culture = ?]))
        ]
      ]
    ]
    
    if typeComportement = "R" [ ; les R ne changent que si tout le monde autour d'eux a une meme culture
      foreach culturesList [
        set indMax count neighbors with [culture = ?]
        if indMax = 8 [
          set nextCulture ?
          set nextCity [cityMarket] of (one-of (neighbors with [culture = ?]))
        ]
      ]  ]
    
    if  banqueroute [ 
      ; si on active la banqueroute, mise en friche pour les cultures à R < 0  
      ; declenche seulement apres un certains nombre de ticks pour laisser le temps au modele de converger un peu 
      if ticks > 5 [
        if rente < 0 [
          set nextCulture 0 ]]
    ]  
  ]
end
  
  
; methode de agriculteur
; installe la culture choisie et met à jour les quantités de cultures sur les marchés
to installerNextCulture
  ; installe culture planifi�e sur la parcelle  
  if not (nextCulture = culture) [set chgtCulture ticks]   ; le flag chgtCulture est mis � true si la culture change
  set culture nextCulture
  set cityMarket nextCity
  let cultureIndex position culture cultureslist 
  ifelse culture = 0 [
    set rente 0 
    set pcolor black
    ] [
    ; calcul de la rente pour mémoire et mise à jour des quantités sur le marché
    ask cityMarket [
      set rente calculerRenteReportCity cultureIndex
      set qteCourante (replace-item cultureIndex qteCourante (item cultureIndex qteCourante + 1))]      
    set pcolor item cultureIndex colorlist 
    ]
  set nextCulture culture
  

end





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;   COMPORTEMENTS DES VILLES  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; methode de city
; evolution des prix du marché en fonction de l'offre et de la demande
to update-market
    ifelse prixFixe [
      set prixCourantI item 0 prixMarcheList
      set prixCourantF item 1 prixMarcheList
      set prixCourantC item 2 prixMarcheList
      set prixCourantR item 3 prixMarcheList  
      ]
    [; attention onne peut pas avoir de prix negatif ni même nul
      set prixCourantI max list 0.001  (prixCourantI + (demandeCourantI - (item 0 qteCourante)) * tauxDecroissance)
      set prixCourantF max list 0.001 (prixCourantF + (demandeCourantF - (item 1 qteCourante)) * tauxDecroissance)
      set prixCourantC max list 0.001 (prixCourantC + (demandeCourantC - (item 2 qteCourante)) * tauxDecroissance)
      set prixCourantR max list 0.001 (prixCourantR + (demandeCourantR - (item 3 qteCourante)) * tauxDecroissance)
    ]

 set qteCourante [0 0 0 0]

end






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;   ROUTINES DE CALCUL      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; methode du monde  
; effectue un tirage dans listRefs selon une distribution de probabilité donnée par listProp  
; renvoie le résultat
to-report tirageSelonDistributionDans [listProps listRefs]
  
  let listPropsUnif map [? / sum listProps] listProps ; normalisation à 1 des probabilités 
  let result -1 
  let rand random-float 1
  let sumProps 0  
  foreach n-values length listPropsUnif [?][
    if result < 0 [
      if rand < sumProps + item ? listPropsUnif [set result ?]
      set sumProps sumProps + item ? listPropsUnif
     ]
  ]
  if result = -1 [
    show listPropsUnif
    show listProps
    show listREfs
    show rand]
  report item result listRefs 
end



; methode de city
; calcule la rente de la culture indexée pour la city appelant et le patch appelant (myself)
to-report calculerRenteReportCity [index]
    
ifelse( index = 0)
[
  report  RendementI * (- transportI * distance myself + ( prixCourantI - coutProdI) )  
  ]
[
  ifelse (index = 1)
  [
    report  RendementF * (- transportF * distance myself + ( prixCourantF - coutProdF) )  
    ]
  [
    ifelse (index = 2)
    [
      report RendementC * (- transportC * distance myself + ( prixCourantC - coutProdC) )  
      ]
    [
      ifelse (index = 3)
      [
        report RendementR * (- transportR * distance myself + ( prixCourantR - coutProdR) )  
        ]
      [report 0]
      ]
    ]
  ]

end



; methode de exploitation 
; calcule pour le patch quelle est la combinaison culture-ville optimale au sens de VT 
; renvoie une liste (indice rente max - culture max - ville max)
to-report calculerCultureEtVilleVT

let renteMax 0
let renteTemp 0 
let indMax 0 
let cityChosen one-of cities

; calcule la rente pour chaque combinaison culture-ville et choisit la maximale ! 
  foreach n-values nombreProduits [?] 
   [
      ask cities 
      [
        set renteTemp calculerRenteReportCity ?          
        if (renteTemp > renteMax) [
          set renteMax renteTemp
          set indMax ? 
          set cityChosen self
          ]
      ]
   ]
   report (list renteMax indMax cityChosen)
end







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;   SORTIES                 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to do-plots  
  
;;; courbes des rentes des cultures en fonction de la distance à la ville
  set-current-plot "Rente des cultures selon la distance à la ville"
  clear-plot
  let i 0
  ifelse (initialOuCourant = "initial") [
    while[i < NombreProduits]
    [
      set-current-plot-pen (item i plotsList)
      plotxy 0 max list 0 ((item i rendementsList) * ((item i prixMarcheList) - (item i coutProdList))) 
      plotxy max list 0 ((item i prixMarcheList) - (item i coutProdList)) / (item i transportsList) 0
      set i (i + 1)
    ]
  ][  
  set-current-plot-pen "C"
  ask cityObserved [
    plotxy 0 max list 0 (RendementC * (prixCourantC - coutProdC)) 
    plotxy max list 0 (prixCourantC - coutProdC) / TransportC 0
    
    set-current-plot-pen "R"
    plotxy 0 max list 0 (RendementR * (prixCourantR - coutProdR)) 
    plotxy max list 0 (prixCourantR - coutProdR) / TransportR 0
    
    set-current-plot-pen "I"
    plotxy 0 max list 0 (RendementI * (prixCourantI - coutProdI)) 
    plotxy max list 0 (prixCourantI - coutProdI) / TransportI 0
    
    set-current-plot-pen "F"
    plotxy 0 max list 0 (RendementF * (prixCourantF - coutProdF)) 
    plotxy max list 0 (prixCourantF - coutProdF) / TransportF 0
  ]]
  
  
; plots temporels. Dans la nouvelle version de Netlogo on peut définir les fonctions des plots directement dans l'interface
; c'est le cas comportements et nombre total de cultures qui n'apparaissent donc pas ici 
  set-current-plot "Cultures"
  let tot count patches with [culture != 0]
  foreach ["C" "R" "I" "F"] [
    set-current-plot-pen ?
    plot 100 * count patches with [culture = ?]  / tot
  ]

  set-current-plot "Prix"
  set-current-plot-pen "C"
  plot [prixCourantC] of cityObserved
  set-current-plot-pen "R"
  plot [prixCourantR] of cityObserved
  set-current-plot-pen "I"
  plot [prixCourantI] of cityObserved
  set-current-plot-pen "F"
  plot [prixCourantF] of cityObserved
end

to refresh 
end
@#$#@#$#@
GRAPHICS-WINDOW
230
10
645
446
40
40
5.0
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
73
70
136
103
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

BUTTON
6
34
104
67
Init Random
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
664
44
768
77
coutProdI
coutProdI
0
1000
490
1
1
NIL
HORIZONTAL

SLIDER
664
77
767
110
coutProdF
coutProdF
0
1000
284
1
1
NIL
HORIZONTAL

SLIDER
664
109
767
142
coutProdC
coutProdC
0
1000
148
1
1
NIL
HORIZONTAL

SLIDER
664
142
767
175
coutProdR
coutProdR
0
1000
80
1
1
NIL
HORIZONTAL

SLIDER
664
181
767
214
prixMarcheI
prixMarcheI
0
1000
943
1
1
NIL
HORIZONTAL

SLIDER
664
213
767
246
prixMarcheF
prixMarcheF
0
1000
705
1
1
NIL
HORIZONTAL

SLIDER
664
246
767
279
prixMarcheC
prixMarcheC
0
1000
591
1
1
NIL
HORIZONTAL

SLIDER
664
279
766
312
prixMarcheR
prixMarcheR
0
1000
433
1
1
NIL
HORIZONTAL

SLIDER
776
42
882
75
TransportI
TransportI
0
100
38
1
1
NIL
HORIZONTAL

SLIDER
776
75
880
108
TransportF
TransportF
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
776
108
879
141
TransportC
TransportC
0
100
19
1
1
NIL
HORIZONTAL

SLIDER
776
141
878
174
TransportR
TransportR
0
100
9
1
1
NIL
HORIZONTAL

SLIDER
776
180
879
213
RendementI
RendementI
0
100
99
1
1
NIL
HORIZONTAL

SLIDER
776
213
880
246
RendementF
RendementF
0
100
75
1
1
NIL
HORIZONTAL

SLIDER
776
247
879
280
RendementC
RendementC
0
100
53
1
1
NIL
HORIZONTAL

SLIDER
776
279
878
312
RendementR
RendementR
0
100
33
1
1
NIL
HORIZONTAL

SLIDER
924
88
1066
121
demandeI
demandeI
0
1000
583
1
1
NIL
HORIZONTAL

SLIDER
924
121
1065
154
demandeF
demandeF
0
1000
595
1
1
NIL
HORIZONTAL

SLIDER
924
154
1066
187
demandeC
demandeC
0
1000
559
1
1
NIL
HORIZONTAL

SLIDER
924
188
1067
221
demandeR
demandeR
0
1000
539
1
1
NIL
HORIZONTAL

PLOT
226
447
641
655
Rente des cultures selon la distance à la ville
distance
Rente
0.0
10.0
0.0
0.1
true
true
"" ""
PENS
"C" 1.0 0 -13345367 true "" ""
"I" 1.0 0 -2674135 true "" ""
"R" 1.0 0 -10899396 true "" ""
"F" 1.0 0 -16777216 true "" ""

PLOT
1094
291
1390
469
Cultures
temps
% total cultures
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"C" 1.0 0 -13345367 true "" ""
"I" 1.0 0 -2674135 true "" ""
"R" 1.0 0 -10899396 true "" ""
"F" 1.0 0 -16777216 true "" ""

PLOT
1094
11
1391
172
Prix
temps
prix
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"C" 1.0 0 -13345367 true "" ""
"I" 1.0 0 -2674135 true "" ""
"R" 1.0 0 -10899396 true "" ""
"F" 1.0 0 -16777216 true "" ""

TEXTBOX
9
223
181
251
LIMITATION DU NB DE CULTURES
11
0.0
1

CHOOSER
8
129
190
174
comportementAgriculteurs
comportementAgriculteurs
"vonThunen" "diversifiés"
1

SLIDER
666
354
703
493
optimisateursVT
optimisateursVT
0
100
0
1
1
NIL
VERTICAL

SLIDER
781
390
886
423
earlyAdopters
earlyAdopters
0
100
0
1
1
NIL
HORIZONTAL

SLIDER
781
425
886
458
followers
followers
0
100
0
1
1
NIL
HORIZONTAL

BUTTON
7
69
70
102
NIL
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

SLIDER
781
357
886
390
obsIntelligents
obsIntelligents
0
100
0
1
1
NIL
HORIZONTAL

BUTTON
107
34
178
67
Init VT 
setupVT
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
673
530
784
563
probaMort
probaMort
0
1
0
0.01
1
NIL
HORIZONTAL

SWITCH
673
564
785
597
Banqueroute
Banqueroute
0
1
-1000

SLIDER
7
241
115
274
NombreProduits
NombreProduits
1
4
4
1
1
NIL
HORIZONTAL

SLIDER
98
176
190
209
NombreVilles
NombreVilles
1
10
1
1
1
NIL
HORIZONTAL

SWITCH
8
176
98
209
prixFixe
prixFixe
1
1
-1000

TEXTBOX
8
17
158
35
INITIALISATION / RUN
11
102.0
1

TEXTBOX
10
112
183
140
EXTENSIONS DU MODELE DE VT
11
0.0
1

BUTTON
518
510
611
543
Rafraichir
do-plots
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
519
465
611
510
initialOuCourant
initialOuCourant
"initial" "courant"
1

TEXTBOX
671
336
895
364
STRUCTURE POPULATION AGRICULTEURS 
11
0.0
1

TEXTBOX
713
20
863
38
PARAMETRES VT CULTURES
11
0.0
1

TEXTBOX
924
21
1074
39
PARAMETRES PRIX VARIABLES
11
0.0
1

SLIDER
923
42
1066
75
tauxDecroissance
tauxDecroissance
0
1
0.031
0.001
1
NIL
HORIZONTAL

TEXTBOX
675
511
899
539
PARAMETRES ADAPTATION AGRICULTEURS
11
0.0
1

SLIDER
781
459
886
492
resistants
resistants
0
100
0
1
1
NIL
HORIZONTAL

SLIDER
742
354
779
493
aversesRisque
aversesRisque
0
100
10
1
1
NIL
VERTICAL

INPUTBOX
788
531
838
597
inertie
10
1
0
Number

SLIDER
704
354
741
494
sous-optimisateurs
sous-optimisateurs
0
100
0
1
1
NIL
VERTICAL

PLOT
1092
468
1390
660
Comportements
temps
% total cultures
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"VT" 1.0 0 -16777216 true "" "ifelse count agriculteurs with [culture != 0] = 0 [plot 0 ][plot 100 * (count agriculteurs with [culture != 0 and typeComportement = \"VT\"]) / count agriculteurs with [culture != 0]]"
"SO" 1.0 0 -7500403 true "" "ifelse count agriculteurs with [culture != 0] = 0 [plot 0 ][plot 100 * (count agriculteurs with [culture != 0 and typeComportement = \"SO\"]) / count agriculteurs with [culture != 0]]"
"AR" 1.0 0 -2674135 true "" "ifelse count agriculteurs with [culture != 0] = 0 [plot 0 ][plot 100 * (count agriculteurs with [culture != 0 and typeComportement = \"AR\"]) / count agriculteurs with [culture != 0]]"
"OI" 1.0 0 -955883 true "" "ifelse count agriculteurs with [culture != 0] = 0 [plot 0 ][plot 100 * (count agriculteurs with [culture != 0 and typeComportement = \"OI\"]) / count agriculteurs with [culture != 0]]"
"EA" 1.0 0 -6459832 true "" "ifelse count agriculteurs with [culture != 0] = 0 [plot 0 ][plot 100 * (count agriculteurs with [culture != 0 and typeComportement = \"EA\"]) / count agriculteurs with [culture != 0]]"
"F" 1.0 0 -1184463 true "" "ifelse count agriculteurs with [culture != 0] = 0 [plot 0 ][plot 100 * (count agriculteurs with [culture != 0 and typeComportement = \"F\"]) / count agriculteurs with [culture != 0]]"
"R" 1.0 0 -10899396 true "" "ifelse count agriculteurs with [culture != 0] = 0 [plot 0 ][plot 100 * (count agriculteurs with [culture != 0 and typeComportement = \"R\"]) / count agriculteurs with [culture != 0]]"

PLOT
1094
172
1391
292
Nombre total de cultures
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"." 1.0 0 -16777216 true "" "plot count agriculteurs with [culture != 0]"

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

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

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
NetLogo 5.0.1
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

extensions [gis]
globals [ lalist dalist mylist patchsurface cumBio-div firstStep joueurName joueurID]
breed [Collembolas Collembola]
breed [parcelles parcelle]


patches-own [ pop1 pop2 pop3 land-type land-use surfaceID  maparcelle owner state old-state]


breed [bestioles bestiole]
breed [clients client]

bestioles-own [ parcelleID specialist surface K N myland-type ]
parcelles-own [   parcelleID start-land-use  powner bio-div ]


clients-own 
[
  user-id     ;; hubnet identifier
  user-color  ;; color assigned to this user (though colors may be reused)
  user-role
  user-pen-size ; taille du crayon
  user-current-action
  portefeuille
  nb-coups-restants
  user-alert
  user-selection-parcelle
  userName
]


to startup-game
  hubnet-reset  
  set firstStep true
  setup-participative
  draw-display
 
end



;; determines which client sent a command, and what the command was
to listen-to-clients
  every 2
  [
    display
  ]
  
  while [ hubnet-message-waiting? ]
  [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [
      show "new client"
      create-new-client hubnet-message-source
      draw-individual-preferences
    ]
    [
      ifelse hubnet-exit-message?
        [ remove-client hubnet-message-source ]
        [ execute-command hubnet-message ]
    ]
  ]
end

to setup-client
  let nbClients count clients
  
  ifelse nbClients = 1
  [
    set user-role "Forestier"
    setup-forestier self
  ]
  [
    ifelse nbClients = 2
    [
      set user-role "Aménageur"
      setup-planner self
    ]
    [
      set user-role "Agriculteur"
            setup-farmer self

    ]      
  ]
  set userName item joueurID joueurName 
  set joueurID joueurID + 1
end

to setup-farmer [ a ]
   set portefeuille crédit-agriculteur
   let nb-farmer count clients with [user-role  = "Agriculteur" ]
   let choosenParcelle parcelles with [(matchpreference "culture" start-land-use) = true and powner = -1]
   let nb-parcelles (count choosenParcelle) / nombre-agriculteurs
   show (word nb-parcelles " " (count choosenParcelle))
   if nb-farmer < nombre-agriculteurs 
   [
     set choosenParcelle n-of nb-parcelles choosenParcelle 
   ]
  
ask choosenParcelle 
  [
    let monState 0
    if random 1000 > 500
    [
     set monState 1 
    ]
    
    ask patches with [maparcelle = myself ]
    [
      set owner a
      set state monState 
    ]
   set powner a 
   set hidden? true
  ]
end




to setup-planner [ a ]
   set portefeuille crédit-aménageur
 
   ask parcelles with [(matchpreference "urbain" start-land-use) = true]
  [
    ask patches with [maparcelle = myself ]
    [
      set owner a
    ]
     set powner a 
  
   set hidden? true
  ] 
end


to setup-forestier [ a ]
 set portefeuille crédit-forestier

 ask parcelles with [(matchpreference "foret" start-land-use) = true]
  [
    ask patches with [maparcelle = myself ]
    [ 
      set owner a
    ]
     set powner a 
  
   set hidden? true
   
  ] 
end

to create-new-client [ id ]
  create-clients 1
  [
    set user-id id
    setup-client
    set user-pen-size 6 
    set user-selection-parcelle true
    
    hubnet-send id "role" (word user-role " (" userName ")")
    hubnet-send id "selection-parcelle" user-selection-parcelle
    
   ; send-system-info
  ]
end

to remove-client [ id ]
  ask clients with [id = user-id]
  [
    die
  ]  
end

to nouveau-tour

  if  firstStep = false
  [
    gain-actor
     ask clients [hubnet-send user-id "informations" "Veuillez patientier, les calculs de biodiversité sont en cours"]
    let i 0
    while [i < tps-calcul-biodiv]
    [ 
      gogo
      set i i + 1
    ]
  ]
  
  set firstStep false
  ask clients
  [
   set nb-coups-restants  nombre-coups-tour
   set user-alert "Un nouveau tour vient de débuter."
   update-client-monitors
   hubnet-send user-id "biodiv-moyen" round (100 * biodiv-joueur self)
  ]
  display
end


to update-client-monitors
  hubnet-send user-id "nombre-coups-restants" nb-coups-restants
  hubnet-send user-id "collemboyard" round portefeuille
  hubnet-send user-id "informations" user-alert
  set user-alert ""
end


to execute-command [ messagetg]
  ask clients with [ user-id = hubnet-message-source  ]
  [
    show user-role
   ifelse nb-coups-restants > 0 
    [
      ifelse  user-role = "Forestier"
      [
        execute-command-forester messagetg
      ]
      [
        ifelse  user-role = "Agriculteur"
        [
          execute-command-farmer messagetg
        ]
        [
          if  user-role = "Aménageur"
          [
            show "coucou"
            execute-command-planner messagetg
          ]
        ]
      ]
    ]
    [
     set user-alert "Tour déjà terminé!!! patientez au prochain tour." 
    ]
     update-client-monitors
     
  ]
draw-display
end

to-report action-cost-forester [action-name]
  let cost 0
  ifelse action-name =  "Planter"
  [
    set cost  achat-plantation-for
  ]
  [
   
      ifelse action-name =  "Acheter"
      [
        set cost  achat-parcelle-for
      ] 
      [
        
      ]
  ]
  
  
  
  report cost
end


to execute-command-forester [ messagetg]
  let myacction user-current-action
     ifelse hubnet-message-tag = "View"
     [
       let isModified? false
       let xmin  (round item 0 hubnet-message) - (user-pen-size / 2)
       let ymin  (round item 1 hubnet-message) - ( user-pen-size / 2 )

; modification pour limiter le choix au crayon des patches qui sont dans la parcelle cliquée
       let temp-patch   one-of patches with [ pxcor =  (round item 0 hubnet-message) and pycor = (round item 1 hubnet-message)  ]         
       let choosenPatches patches with [(surfaceID = [surfaceID] of temp-patch   ) and (( ( owner = myself and  not (myacction =  "Acheter") ) or (state = 2 and myacction =  "Acheter" ) )  and pxcor >= xmin and pxcor <= (xmin + [user-pen-size] of myself)  and pycor >= ymin and pycor <= (ymin + [user-pen-size] of myself) )]
       if user-selection-parcelle = true
       [

        if temp-patch != nobody      [
        set choosenPatches patches with [ surfaceID = [surfaceID] of temp-patch   and  (owner = myself and  not (myacction =  "Acheter")   and (((not (myacction =  "Annuler la vente")) or( myacction =  "Annuler la vente" and state = 2))) or (state = 2 and myacction =  "Acheter" )) ]
        ]
        ]
       
         if myacction =  "Planter"
         [
          ask choosenPatches
          [
           set state  0
           
           set pop1 0
           set pop2 0
           set pop3 0
           
          ]
          draw-patches-to-client  hubnet-message-source choosenPatches violet
          set isModified? true
         ]
        if myacction =  "Couper et mettre en friche"
         [
          ask choosenPatches
          [
           set state  1
          ]
          draw-patches-to-client  hubnet-message-source choosenPatches (violet + 3)
          set portefeuille portefeuille + (count  choosenPatches) *  coupe-parcelle-for
          set isModified? true          
         ]

         if myacction =  "Vendre"
         [
           hubnet-clear-override user-id choosenPatches "pcolor"  
          ask choosenPatches
          [
           set old-state state
           set state  2
           set pcolor yellow
          ]
          set isModified? true
         ]

         if myacction =  "Annuler la vente"
         [
          ask choosenPatches
          [show land-use
           set state  old-state
          ]
          if any? choosenPatches with [state =  0] [draw-patches-to-client  hubnet-message-source choosenPatches violet]
          if any? choosenPatches  with [state =  1] [draw-patches-to-client  hubnet-message-source choosenPatches violet + 3]
          set isModified? true
         ]
          
         if myacction =  "Acheter"
         [           
          let curOwner nobody
          show choosenPatches
          ask choosenPatches
          [
           set state  1
           set land-type "foret"
           set land-use 6
           set curOwner owner
           set owner myself
           set isModified? true
           
           set pop1 0
           set pop2 0
           set pop3 0
           
          ]
         ; draw-patches-to-client [user-id] of curOwner choosenPatches violet + 3
          if not (curOwner = nobody)
          [ask curOwner 
           [
             if user-role = "Forestier"
            [
             set portefeuille  portefeuille + vente-parcelle-for
            ]
            if user-role = "Agriculteur"
            [
             set portefeuille  portefeuille + vente-parcelle-agr
            ]
             set user-alert "Votre terrain vient d'être acheté"
             update-client-monitors
           ]]
          
          draw-patches-to-client  hubnet-message-source choosenPatches (violet + 3)
         ]
 
        if isModified?
         [
           reduce-action-count
           set portefeuille portefeuille - action-cost-forester myacction
         ]
       
     ]
     [
       ifelse  hubnet-message-tag =  "taille-crayon"
       [
         set user-pen-size hubnet-message
         show (word "taille" user-pen-size)
       ]
       [
         ifelse  hubnet-message-tag =  "actions du forestier"
         [
           set user-current-action hubnet-message
           show (word "current action " user-current-action)
         ]
         [
          if  hubnet-message-tag =  "selection-parcelle"
          [
            set user-selection-parcelle hubnet-message
          ]
         ]
       ]
     ]    
end

to-report action-cost-farmer [action-name]
  let cost 0
  ifelse action-name =  "Mettre en culture"
  [
    set cost  achat-culture-agr
  ]
  [
    if action-name =  "Acheter"
    [
      set cost  achat-parcelle-agr
    ]
  ]
  report cost
end

to execute-command-farmer [ messagetg]
    let myacction user-current-action
  
     ifelse hubnet-message-tag = "View"
     [
       let isModified? false
       let xmin  (round item 0 hubnet-message) - (user-pen-size / 2)
       let ymin  (round item 1 hubnet-message) - ( user-pen-size / 2 )
; modification pour limiter le choix au crayon des patches qui sont dans la parcelle cliquée
       let temp-patch   one-of patches with [ pxcor =  (round item 0 hubnet-message) and pycor = (round item 1 hubnet-message)  ]
       let choosenPatches patches with [(surfaceID = [surfaceID] of temp-patch   ) and (( ( owner = myself and  not (myacction =  "Acheter") ) or (state = 2 and myacction =  "Acheter" ) )  and pxcor >= xmin and pxcor <= (xmin + [user-pen-size] of myself)  and pycor >= ymin and pycor <= (ymin + [user-pen-size] of myself) )]
       if user-selection-parcelle = true
       [
        if temp-patch != nobody
        [
          show [surfaceID] of temp-patch 
          set choosenPatches patches with [ surfaceID = [surfaceID] of temp-patch   and  (owner = myself and  not (myacction =  "Acheter")   and ((not (myacction =  "Annuler la vente" or myacction =  "Acheter")) or ( myacction =  "Annuler la vente" and state = 2)) or (state = 2 and myacction =  "Acheter" )) ]
                
        ]
       ]

       
       
       if myacction =  "Mettre en culture"
         [
           ask choosenPatches
          [
           set state  0
           
           set pop1 0
           set pop2 0
           set pop3 0
           
          ]
          draw-patches-to-client  hubnet-message-source choosenPatches violet
          set isModified? true
          set portefeuille portefeuille - achat-culture-agr
         ]
         if myacction =  "Mettre en friche"
         [
          ask choosenPatches
          [
           set state  1
          ]
          draw-patches-to-client  hubnet-message-source choosenPatches (violet + 3)
          set isModified? true
         ]
         if myacction =  "Vendre"
         [
           hubnet-clear-override user-id choosenPatches "pcolor"  
           ask choosenPatches
          [
           set old-state state
           set state  2
           set pcolor yellow
          ]
        
          set isModified? true
         ]
         
         if myacction =  "Annuler la vente"
         [
          ask choosenPatches
          [show land-use
           set state  old-state
          ]
          if any? choosenPatches with [state =  0] [draw-patches-to-client  hubnet-message-source choosenPatches violet]
          if any? choosenPatches  with [state =  1] [draw-patches-to-client  hubnet-message-source choosenPatches violet + 3]
          set isModified? true
         ]
         
         if myacction =  "Acheter"
         [
          let curOwner nobody
          ask choosenPatches
          [
           set state  1
           set land-type "agriculture"
           set land-use 4
           set curOwner owner
           set owner myself
           set isModified? true 
           
           set pop1 0
           set pop2 0
           set pop3 0
           
          ]
         if not (curOwner = nobody)
         [
          ask curOwner 
           [
           if user-role = "Forestier"
            [
             set portefeuille  portefeuille + vente-parcelle-for
            ]
            if user-role = "Agriculteur"
            [
             set portefeuille  portefeuille + vente-parcelle-agr
            ]
             set user-alert "Votre terrain vient d'être acheté"
             update-client-monitors
            
           ]
         ]
         draw-patches-to-client  hubnet-message-source choosenPatches  (violet + 3)
         ]
            
         if isModified?
         [
           reduce-action-count
           set portefeuille portefeuille - (action-cost-farmer myacction)
         ]
     ]
     [
       ifelse  hubnet-message-tag =  "taille-crayon"
       [
          set user-pen-size hubnet-message
          show (word "taille" user-pen-size)
       ]
       [
         ifelse  hubnet-message-tag =  "actions de l'agriculteur"
         [
           set user-current-action hubnet-message
           show (word "current action " user-current-action)
         ]
         [
          if  hubnet-message-tag =  "selection-parcelle"
          [
            set user-selection-parcelle hubnet-message
          ]
         ]
       ]   
     ]
end

to reduce-action-count
  set nb-coups-restants nb-coups-restants  - 1
    update-client-monitors 
end

to-report action-cost-planner [action-name]
  let cost 0
  ifelse action-name =  "Construire des routes à collemboduc"
  [
    set cost  achat-collemboduc
  ]
  [
   
      ifelse action-name =  "Construire des routes"
      [
        set cost  construction-route
      ] 
      [
        if action-name =  "Acheter"
        [
          set cost  achat-parcelle-am
        ] 
      ]
  ]
  report cost
end


to planner-gain 
  let imp-collemboduc (count  patches with [ land-type = "surface artificielle" and state = 1 ]) *  impot-collemboduc
  let improute (count  patches with [ land-type = "surface artificielle" and state = 3 ]) *  impot-route
  
  set portefeuille portefeuille + impot-collemboduc + imp-collemboduc
end

to farmer-gain
  let gain-parcelle (count  patches with [  state = 0 and owner = myself]) *  culture-agr
 
  set portefeuille portefeuille + gain-parcelle 
end

to forest-gain
 ; let gain-parcelle (count  patches with [ state = 1 and owner = myself ]) *  coupe-parcelle-for
 
 ; set portefeuille portefeuille + gain-parcelle 
end

to gain-actor
 ask clients
 [ 
  ifelse user-role = "Agriculteur"
  [ 
    farmer-gain
  ]
  [
    ifelse user-role = "Forestier"
    [
        forest-gain
    ]
    [
       if user-role = "Aménageur"
       [
         planner-gain
       ]
    ]
  ]
  update-client-monitors
 ]
end

to execute-command-planner [ messagetg]
 let myacction user-current-action
    ifelse hubnet-message-tag = "View"
     [
       let isModified? false;
       let xmin  (round item 0 hubnet-message) - (user-pen-size / 2)
       let ymin  (round item 1 hubnet-message) - ( user-pen-size / 2 )
       let temp-patch   one-of patches with [ pxcor =  (round item 0 hubnet-message) and pycor = (round item 1 hubnet-message) and ( ( owner = myself and  not (myacction =  "Acheter") ) or (state = 2 and myacction =  "Acheter" ) ) ]  
       let choosenPatches patches with [state = 40000]
        if temp-patch != nobody
        [   set choosenPatches patches with [ ( ( owner = myself and not (myacction =  "Acheter") ) or (state = 2 and myacction =  "Acheter" and (surfaceID = [surfaceID] of temp-patch   ) ) )  and pxcor >= xmin and pxcor <= (xmin + [user-pen-size] of myself)  and pycor >= ymin and pycor <= (ymin + [user-pen-size] of myself) ]
        ]
       if user-selection-parcelle = true
       [
;         let temp-patch   one-of patches with [ pxcor >=  xmin and pxcor <=  xmin + 1 and pycor >= ymin and pycor <= ymin + 1 and ( ( owner = myself and  not (myacction =  "Acheter") ) or (state = 2 and myacction =  "Acheter" ) ) ]
         if temp-patch != nobody
        [
          if ( [owner] of temp-patch = self and not (myacction =  "Acheter")) 
            [ set choosenPatches patches with [surfaceID = [surfaceID] of temp-patch ] ]
          if ( [state] of temp-patch = 2 and (myacction =  "Acheter")) 
            [ set choosenPatches patches with [surfaceID = [surfaceID] of temp-patch  and state = 2 ]]

        ]
       ]
       if myacction =  "Construire des routes à collemboduc"
         [
          ask choosenPatches
          [
           set state  1
           
           set pop1 0
           set pop2 0
           set pop3 0
           
          ]
          draw-patches-to-client  hubnet-message-source choosenPatches red
           set isModified? true
         ]
       if myacction =  "Vendre"
         [
           hubnet-clear-override user-id choosenPatches "pcolor"  
           ask choosenPatches
           [
             set old-state state
             set state  2
             set pcolor yellow
           ]
          set isModified? true
           
       ] 
       if myacction =  "Construire des routes meurtières"
         [
          ask choosenPatches
          [
           set state  3
           
           set pop1 0
           set pop2 0
           set pop3 0
           
          ] 
          draw-patches-to-client  hubnet-message-source choosenPatches (red + 3)
          set isModified? true
         ]
       if myacction =  "Acheter"
         [
          
          let curOwner nobody
          ask choosenPatches
          [
           set state  0
           set land-type "urbain"
           set land-use 1
           set curOwner owner
           set owner myself
           set isModified? true 
           
           set pop1 0
           set pop2 0
           set pop3 0
           
          ]
         
         if not (curOwner = nobody)
         [
          ask curOwner 
           [
            if user-role = "Forestier"
            [
             set portefeuille  portefeuille + vente-parcelle-for
            ]
            if user-role = "Agriculteur"
            [
             set portefeuille  portefeuille + vente-parcelle-agr
            ]
             set user-alert "Votre terrain vient d'être acheté"
             update-client-monitors
            
           ]
         ]
         draw-patches-to-client  hubnet-message-source choosenPatches  (violet)
         ]
        
       if isModified?
         [
           reduce-action-count
           set portefeuille portefeuille - action-cost-planner myacction
         ]
    
     ]
     [
       ifelse  hubnet-message-tag =  "taille-crayon"
       [
            set user-pen-size hubnet-message
            show (word "taille" user-pen-size)
       ]
       [
        ifelse  hubnet-message-tag =  "actions de l'aménageur"
         [
           set user-current-action hubnet-message
           show (word "current action " user-current-action)
         ] 
         [
          if  hubnet-message-tag =  "selection-parcelle"
          [
            set user-selection-parcelle hubnet-message
          ]
         ]
         
       ]
     ]
end





;; initializes the display
;; but does not clear already created farmers
to setup-participative
  setup
 ;  hubnet-broadcast "server_comment:"  (word "Everyone starts with "  " goats.")
 ; hubnet-broadcast "num-goats-to-buy" 1
 ; broadcast-system-info
end


to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks         ;; tout effacer
  
  setup-globals     ;; régler les paramêtres globaux
   
  setup-environment    ;; régler les paramêtres de l'environnement
  
  setup-agent       ;; régler les paramêtres des agents
  
 ; graphique
 
  reset-ticks 
end

to setup-globals
  set patchsurface 16   ; la surface d'un patch est �gale � 16 m�
  set joueurName ["Joueur 1" "Joueur 2" "Joueur 3" "Joueur 4" "Joueur 5"]
  set joueurID 0
end

to setup-environment
  ;; importation des fichiers raster
  
  ask patches
  [
    
    set surfaceID -1
  ]
  
  LoadGISData
    
end

to LoadGISData

let commune-dataset gis:load-dataset "data/site4.shp"    ; charger la carte vecteur de commune dans la base
gis:set-world-envelope gis:envelope-of commune-dataset   ; fixer la cadre du monde au cadre de la carte vecteur de commune

ask patches 
[
  set surfaceID -1
]

; afficher la carte vectorielle des communes '

gis:set-drawing-color black
gis:draw commune-dataset 1

; creer les differentes communes et initialiser son espace d'occupation
foreach gis:feature-list-of commune-dataset     ; pour chaque vecteur dans la base
[
; creer nouvel agent commune
 ;   create-bestioles 1 [
      
      create-parcelles 1
      [
       set parcelleID  gis:property-value ? "id"
       set powner -1
       set hidden? true
       set start-land-use gis:property-value ? "level1"
       let coordinate gis:location-of gis:centroid-of ?
       setxy  (item 0 coordinate) (item 1 coordinate)]
      
      let currentParcelle one-of parcelles with [parcelleID = gis:property-value ? "id" ]
      ask ( patches with [ surfaceID = -1]  ) gis:intersecting ?       ; retrouver l'espace (cellules) de couvrage par la commune (vecteur polygone) courante
      [ 
        set pcolor green
        set surfaceID  gis:property-value ? "id"
        set land-use   gis:property-value ? "level1"
        set maparcelle currentParcelle 
        set state 0; ; state 0 c'est en culture  ; state 1 c'est en friche
       ]
      
      
      create-bestioles 1
      [
        set parcelleID gis:property-value ? "id"
        let coordinate gis:location-of gis:centroid-of ?
        setxy  (item 0 coordinate) (item 1 coordinate)
        set specialist "culture"
        set hidden? true
      ]
      create-bestioles 1
      [
        set parcelleID gis:property-value ? "id"
        let coordinate gis:location-of gis:centroid-of ?
        setxy  (item 0 coordinate) (item 1 coordinate)
        set specialist "generaliste"
        set hidden? true
      ]
      create-bestioles 1
      [
        set parcelleID gis:property-value ? "id"
        let coordinate gis:location-of gis:centroid-of ?
        setxy  (item 0 coordinate) (item 1 coordinate)
        set specialist "foret"
        set hidden? true
      ]
      
     
        ;  gis:property-value ? "FID" ]    ; assigner l'espace avec son identificateur de la commune 'who'
     ; set nom gis:property-value ? "nom"    ; assigner le nom de commune courant
       
  ]
  ;    ]
end



to setup-agent
   ask bestioles
   [
      set size 3 ;; r�gler la taille
   ] 
   ask patches 
   [
      if land-use = 6 or land-use = 7 or land-use = 8 or land-use = 10 or land-use = 12
      [
         set land-type "foret"
      ]
      if land-use = 2 or land-use = 3 or land-use = 4 or land-use = 5
      [
         set land-type "agriculture"
      ]
      if land-use = 1
      [
         set land-type "surface artificielle"
      ]
    
   ]
  
  initiatePop
  
end


to initiatePop
  
  ask patches
  [   
       set pop1 init-pop 
       set pop2 init-pop 
       set pop3 init-pop 
  ] 
  
  ask bestioles 
  [
    set N 0
    set myland-type [land-type] of one-of patches with [ surfaceID = [parcelleID] of myself]  ; pour une m�me parcelle, associe un patch � la tortue
 
  ]  
   
end



to gogo
  grow-population
  death-population
  diffuse-population
  reproduce-Collembolas
  update-biodiv
  set cumBio-div biodiv-totale 
tick
end

to update-biodiv
  ask parcelles
  [
   set bio-div biodiv-parcelle
  ]
end

to grow-population
  ask patches
  [ 
    if (land-type) = "foret"
    [
       set pop1 pop1 +  (pop1 * (growth-rate1 * (1 - (pop1 + pop2 + pop3) / maxpop)))
    ]
    if (land-type) = "agriculture"
    [
       set pop2 pop2 +  (pop2 * (growth-rate2 * (1 - (pop1 + pop2 + pop3) / maxpop)))
    ]
    set pop3 pop3 +  (pop3 * (growth-rate3 * (1 - (pop1 + pop2 + pop3) / maxpop)))
  ]

end

to death-population
  ask patches
  [
    if (land-type) = "foret" and state = 0
    [
       set pop2 pop2 * (1 - mortality)
    ]
        
    if (land-type) = "agriculture" and state = 0
    [
       set pop1 pop1 * (1 - mortality)
    ]
    
    
    if land-type = "surface artificielle" and state !=  1
      [
        set pop1 0
        set pop2 0
        set pop3 0
      ]     
  ]
  
  
end

to diffuse-population
  diffuse pop1 dispersion-rate
  diffuse pop2 dispersion-rate
  diffuse pop3 dispersion-rate
end


to-report getlandUse [mySurfaceId]
  report [land-use] of (one-of patches with [surfaceID = mySurfaceId]) 
end

to-report matchpop [myparcelleID mysurfaceID]
  report (myparcelleID = mysurfaceID)
end


to-report matchpreference [mypreference mylanduse] 
  report  (mypreference = "foret" and (mylanduse = 6 or mylanduse = 7 or mylanduse = 8 or mylanduse = 10)) 
          or (mypreference = "culture" and (mylanduse =  3 or mylanduse = 4 or mylanduse = 5))
          or (mypreference = "urbain" and (mylanduse = 1))
end




to draw-display
  ask patches
  [
   if (matchpreference "foret" land-use ) = true and state = 0
   [
     set pcolor green
   ]
   if (matchpreference "foret" land-use ) = true and state = 1
   [
     set pcolor green + 1.5
   ]
   if (matchpreference "culture" land-use) = true and state = 0
   [
     set pcolor brown
   ]
   if (matchpreference "culture" land-use) = true and state = 1
   [
     set pcolor brown + 1.5
   ]
   if (matchpreference "urbain" land-use) = true  and state = 0
   [
     set pcolor gray
   ]
   
   if (matchpreference "urbain" land-use) = true  and state = 1
   [
     set pcolor red
   ]
   
   if (matchpreference "urbain" land-use) = true  and state = 2
   [
     set pcolor red + 1.5
   ]

   if state = 2
   [
    set pcolor yellow 
   ]
    
  ]
end
to reproduce-Collembolas    
  
   ask bestioles with [specialist = "culture" ]
   [
     set N sum [pop2] of patches with [ [parcelleID] of myself = SurfaceID ]
   ]
   ask bestioles with [specialist = "foret" ]
   [
     set N sum [pop1] of patches with [[parcelleID] of myself = SurfaceID ]
   ]
   ask bestioles with [specialist = "generaliste" ]
   [
     set N sum [pop3] of patches with [[parcelleID] of myself = SurfaceID ]
   ]
end

to draw-individual-preferences
  ask clients
  [
    let currentClient self
    hubnet-send-override [user-id] of currentClient (patches with [ owner =  currentClient and state = 0]) "pcolor" [ violet ] 
    hubnet-send-override [user-id] of currentClient (patches with [ owner =  currentClient and state = 1]) "pcolor" [ violet  + 3 ] 
    hubnet-send-override [user-id] of currentClient (patches with [ owner =  currentClient and state = 2]) "pcolor" [ yellow ] 
   ] 
end

to draw-patches-to-client [currentClientName currentPatch currentColor]
 hubnet-send-override currentClientName currentPatch "pcolor" [ currentColor ] 
end



to-report biodiv-totale
  ;cette procedure est appelée par une procedure observeur!

let popindice1 0
set popindice1 (sum [N] of bestioles with [specialist = "foret"])

let popindice2 0
set popindice2 (sum [N] of bestioles with [specialist = "culture"])

let popindice3 0
set popindice3 (sum [N] of bestioles with [specialist = "generaliste"])

let poptot 0
set poptot popindice1 + popindice2 + popindice3

let shannon 0
let simpson 0
let biodiv-tot 0
if(poptot != 0)
  [
    set shannon  0 - (((popindice1 / poptot) * (ln (popindice1 / poptot))) + ((popindice2 / poptot) * (ln (popindice2 / poptot))) + ((popindice3 / poptot) * (ln (popindice3 / poptot))))
    set simpson (popindice1 * (popindice1 - 1) / (poptot * (poptot - 1))) + (popindice2 * (popindice2 - 1) / (poptot * (poptot - 1))) + (popindice3 * (popindice3 - 1) / (poptot * (poptot - 1)))
    set biodiv-tot 1 - (1 / simpson) / (exp (shannon))
  ]



report biodiv-tot

end

to-report biodiv-parcelle
  ; cette procedure est appelée par un ask de parcelle, qui met à jour son attribut "bio-div"
;  to mise-à-jour-biodiv
;    ask parcelles [ set bio-div biodiv-parc]
;  end
;  set size 10 set shape "bug" set color red set heading -120 forward 5

let popindice1 0
set popindice1 one-of ( [N] of bestioles with [ (specialist = "foret") and ( parcelleID = [parcelleID] of myself) ]) 
let popindice2 0
set popindice2 one-of ( [N] of bestioles with  [ (specialist = "culture") and ( parcelleID = [parcelleID] of myself) ] )
let popindice3 0
set popindice3 one-of ( [N] of bestioles with [ (specialist = "generaliste") and ( parcelleID = [parcelleID] of myself) ] )
let poptot 0
set poptot popindice1 + popindice2 + popindice3

let shannon 0
set shannon  0 - (((popindice1 / poptot) * (ln (popindice1 / poptot))) + ((popindice2 / poptot) * (ln (popindice2 / poptot))) + ((popindice3 / poptot) * (ln (popindice3 / poptot))))

let simpson 0
set simpson (popindice1 * (popindice1 - 1) / (poptot * (poptot - 1))) + (popindice2 * (popindice2 - 1) / (poptot * (poptot - 1))) + (popindice3 * (popindice3 - 1) / (poptot * (poptot - 1)))

let biodiv-parc 0
set biodiv-parc 1 - (1 / simpson) / (exp (shannon))

report biodiv-parc

end


to-report biodiv-joueur [myID]
  ; cette procedure est appelée par un ask de parcelle

 let indic-joueur 0
 ;show  parcelles with  [ powner = -1 ] ; and is-number? bio-div and powner = myID]
 ;show  [bio-div] of ( parcelles with  [ powner != -1  and is-number? bio-div and powner = myID] )
 set indic-joueur mean [bio-div] of ( parcelles with  [ powner != -1  and is-number? bio-div and powner = myID] )

report indic-joueur

end


to get-biodiv
   show "--------------------------------------------------------------------------"
   show "-------              BIODIVERSITE                             ----------"
   show "--------------------------------------------------------------------------"
   
 
    ask clients
  [
    
    show (word [user-role ] of self " " [user-id ] of self " "  biodiv-joueur self)
    
  ]

ifelse show-parcelles-biodiv? [ ask bestioles [set label  round (100 * [bio-div] of one-of parcelles with [parcelleID = [parcelleID] of myself])]]
[ask bestioles [set label  ""]]
   
end

to gamer-list
  ask clients
  [
    output-show user-id
  ]
end


to applyPenality
  doPenality acteur penalityValue
end

to doPenality [userID pena]
  ask clients with [userID = userName ]
  [
    set portefeuille portefeuille + penalityValue
    ifelse penalityValue > 0
    [
      set user-alert (word "Une prime de " penalityValue " Collemboyard vous a été octroyée")
    ]
    [
      set user-alert (word "Un impot de " penalityValue " Collemboyard vous est demandé")
    ]
    update-client-monitors
  ]
end

to applySell
  doSell vendeur acheteur prix_vente
end

to doSell [seller buyer price]
  ask clients with [userName = seller ]
  [
    set portefeuille portefeuille + price
    set user-alert (word "La vente de votre parcelle vous a rapporté " price " Collemboyard")
    update-client-monitors
  ]
  ask clients with [userName = buyer ]
  [
    set portefeuille portefeuille - price
    set user-alert (word "La vente de votre parcelle vous a couté" price " Collemboyard")
    update-client-monitors
  ]
  
end
to showMoney
  ask clients
  [
   show (word userName " -> " portefeuille) 
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
785
10
1197
443
-1
-1
2.0
1
10
1
1
1
0
0
0
1
0
200
0
200
1
1
1
ticks
30.0

BUTTON
31
142
186
175
Charger le jeu
setup\nstartup-game
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
1297
780
1469
813
Mortality
Mortality
0
1
0.15
0.05
1
NIL
HORIZONTAL

SLIDER
1522
798
1694
831
maxpop
maxpop
0
100000
100000
1000
1
NIL
HORIZONTAL

SLIDER
1523
756
1695
789
growth-rate
growth-rate
0
2
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
1523
600
1695
633
dispersion-rate
dispersion-rate
0
1
0.4
0.1
1
NIL
HORIZONTAL

BUTTON
29
218
161
251
Lancer le jeu
listen-to-clients
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1220
107
1370
125
Agriculteur\n
11
0.0
1

TEXTBOX
1338
17
1488
35
Dépenses
11
0.0
1

SLIDER
1303
95
1475
128
achat-parcelle-agr
achat-parcelle-agr
0
200
50
1
1
NIL
HORIZONTAL

TEXTBOX
1216
260
1366
278
Forestier
11
0.0
1

SLIDER
1301
264
1473
297
achat-parcelle-for
achat-parcelle-for
0
200
50
1
1
NIL
HORIZONTAL

SLIDER
1542
62
1717
95
vente-parcelle-agr
vente-parcelle-agr
0
200
50
1
1
NIL
HORIZONTAL

SLIDER
1542
106
1714
139
culture-agr
culture-agr
0
1
0.03
0.01
1
NIL
HORIZONTAL

SLIDER
1543
265
1715
298
coupe-parcelle-for
coupe-parcelle-for
0
10
0.5
0.5
1
NIL
HORIZONTAL

TEXTBOX
1214
475
1364
493
Amenageur\n
11
0.0
1

SLIDER
1296
407
1468
440
achat-parcelle-am
achat-parcelle-am
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
1295
463
1468
496
construction-route
construction-route
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
1296
524
1469
557
achat-collemboduc
achat-collemboduc
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
1531
430
1706
463
impot-collemboduc
impot-collemboduc
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
1530
499
1702
532
impot-route
impot-route
0
100
50
1
1
NIL
HORIZONTAL

TEXTBOX
1580
24
1730
42
Recettes\n
11
0.0
1

INPUTBOX
1215
154
1318
214
crédit-agriculteur
100
1
0
Number

INPUTBOX
1208
313
1326
373
crédit-forestier
100
1
0
Number

INPUTBOX
1191
573
1309
633
crédit-aménageur
1000
1
0
Number

SLIDER
1524
706
1704
739
nombre-coups-tour
nombre-coups-tour
1
10
5
1
1
NIL
HORIZONTAL

BUTTON
392
226
508
259
Nouveau tour
nouveau-tour
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
389
172
533
217
nombre de coups restants
sum [nb-coups-restants] of clients
17
1
11

MONITOR
28
587
152
632
min collemboyard
min [portefeuille] of clients
17
1
11

MONITOR
27
650
154
695
max collemboyard
max [portefeuille] of clients
17
1
11

MONITOR
27
713
154
758
sum collemboyard
sum [portefeuille] of clients
17
1
11

SLIDER
171
219
355
252
nombre-agriculteurs
nombre-agriculteurs
1
3
1
1
1
NIL
HORIZONTAL

SLIDER
1522
651
1694
684
init-pop
init-pop
0
10000
4458
1
1
NIL
HORIZONTAL

PLOT
385
588
585
738
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
"default" 1.0 0 -16777216 true "" "plot sum [pop1] of patches"
"pen-1" 1.0 0 -7500403 true "" "plot sum [pop2] of patches"
"pen-2" 1.0 0 -2674135 true "" "plot sum [pop3] of patches"
"pen-3" 1.0 0 -955883 true "" "plot cumBio-div"

SLIDER
1297
737
1469
770
growth-rate1
growth-rate1
0
1
0.75
0.01
1
NIL
HORIZONTAL

SLIDER
1298
695
1470
728
growth-rate2
growth-rate2
0
1
0.38
0.01
1
NIL
HORIZONTAL

SLIDER
1299
644
1471
677
growth-rate3
growth-rate3
0
1
0.1
0.01
1
NIL
HORIZONTAL

PLOT
178
588
378
738
plot 1
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
"default" 1.0 0 -16777216 true "" "plot cumBio-div"

SLIDER
1302
52
1474
85
achat-culture-agr
achat-culture-agr
0
100
10
1
1
NIL
HORIZONTAL

SLIDER
1299
224
1475
257
achat-plantation-for
achat-plantation-for
0
100
15
1
1
NIL
HORIZONTAL

SLIDER
1542
225
1714
258
vente-parcelle-for
vente-parcelle-for
0
100
50
1
1
NIL
HORIZONTAL

BUTTON
238
526
342
559
biodiversity
get-biodiv\n
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
529
228
701
261
tps-calcul-biodiv
tps-calcul-biodiv
1
20
20
1
1
NIL
HORIZONTAL

SWITCH
371
531
536
564
show-parcelles-biodiv?
show-parcelles-biodiv?
1
1
-1000

TEXTBOX
32
85
271
141
----------------------------------\n1. Lancer le serveur et attendre la \n    connexion des participants\n----------------------------------
11
0.0
1

OUTPUT
289
10
753
148
12

TEXTBOX
29
258
248
299
----------------------------------\n3. Attribuer des pénalités\n----------------------------------
11
0.0
1

TEXTBOX
30
177
251
218
----------------------------------\n2. Connecter les participants jeu\n----------------------------------
11
0.0
1

CHOOSER
29
302
167
347
penalityValue
penalityValue
-1000 -500 -250 -100 100 250 500 1000
0

CHOOSER
191
303
329
348
acteur
acteur
"Joueur 1" "Joueur 2" "Joueur 3" "Joueur 4" "Joueur 5"
0

BUTTON
391
312
481
345
appliquer
applyPenality
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
29
525
211
558
Afficher les portefeuilles
showMoney
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
28
365
265
410
----------------------------------\n4. Appliquer une vente négociée\n----------------------------------
11
0.0
1

CHOOSER
28
413
166
458
vendeur
vendeur
"Joueur 1" "Joueur 2" "Joueur 3" "Joueur 4" "Joueur 5"
1

CHOOSER
196
412
334
457
acheteur
acheteur
"Joueur 1" "Joueur 2" "Joueur 3" "Joueur 4" "Joueur 5"
2

INPUTBOX
366
397
521
457
prix_vente
200
1
0
Number

BUTTON
545
425
673
458
realiser la vente
applySell
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
29
475
330
521
----------------------------------\n5. indicateurs\n----------------------------------
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

Ce mod�le permet d'�tudier l'influence des capacit�s de dispersion des collemboles sur le maintien de la diversit� dans un paysage h�t�rog�ne.

## HOW IT WORKS

Le mod�le 

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
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="12"/>
    <enumeratedValueSet variable="N-initial">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-pop-number">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="growth-rate" first="0.2" step="0.3" last="2"/>
    <enumeratedValueSet variable="preference">
      <value value="&quot;foret&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxpop">
      <value value="40000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="12"/>
    <metric>[N] of turtles with [parcelleID = 9]</metric>
    <enumeratedValueSet variable="N-initial">
      <value value="1500000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degrade?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-pop-number">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="growth-rate" first="0.1" step="0.1" last="1.7"/>
    <enumeratedValueSet variable="Mortality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preference">
      <value value="&quot;foret&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersion-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxpop">
      <value value="40000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment3" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="12"/>
    <metric>[N] of turtles with [parcelleID = 9]</metric>
    <enumeratedValueSet variable="N-initial">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degrade?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-pop-number">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="growth-rate" first="0.1" step="0.1" last="1.7"/>
    <enumeratedValueSet variable="Mortality">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="preference">
      <value value="&quot;foret&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersion-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxpop">
      <value value="40000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Diffusion F-spe" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
reset-ticks</setup>
    <go>go
tick</go>
    <timeLimit steps="60"/>
    <metric>count turtles with [N &gt; 0]</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="preference">
      <value value="&quot;foret&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-initial">
      <value value="150000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-pop-number">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="1.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mortality">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersion-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxpop">
      <value value="40000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degrade?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Diffusion F-pref" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
reset-ticks</setup>
    <go>go
tick</go>
    <timeLimit steps="60"/>
    <metric>count turtles with [N &gt; 0]</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="preference">
      <value value="&quot;foret&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-initial">
      <value value="150000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-pop-number">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="1.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mortality">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersion-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxpop">
      <value value="40000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degrade?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Diffusion A-spe" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
reset-ticks</setup>
    <go>go
tick</go>
    <timeLimit steps="60"/>
    <metric>count turtles with [N &gt; 0]</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="preference">
      <value value="&quot;agriculture&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-initial">
      <value value="150000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-pop-number">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="1.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mortality">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersion-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxpop">
      <value value="40000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degrade?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Diffusion A-pref" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
reset-ticks</setup>
    <go>go
tick</go>
    <timeLimit steps="60"/>
    <metric>count turtles with [N &gt; 0]</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="preference">
      <value value="&quot;agriculture&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-initial">
      <value value="150000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-pop-number">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="1.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mortality">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersion-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxpop">
      <value value="40000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degrade?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Diffusion F-pref 2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
reset-ticks</setup>
    <go>go
tick</go>
    <timeLimit steps="60"/>
    <metric>count turtles with [N &gt; 0]</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="preference">
      <value value="&quot;foret&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-initial">
      <value value="150000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-pop-number">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mortality">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersion-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxpop">
      <value value="40000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degrade?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
MONITOR
55
38
246
87
role
NIL
3
1

MONITOR
56
173
153
222
collemboyard
NIL
3
1

CHOOSER
49
274
260
319
actions du forestier
actions du forestier
" " "Planter" "Couper et mettre en friche" "Vendre" "Acheter" "Annuler la vente"
0

CHOOSER
48
339
214
384
actions de l'agriculteur
actions de l'agriculteur
" " "Mettre en culture" "Mettre en friche" "Vendre" "Acheter" "Annuler la vente"
0

CHOOSER
48
410
326
455
actions de l'aménageur
actions de l'aménageur
" " "Construire des routes à collemboduc" "Construire des routes" "Acheter" "Vendre"
0

BUTTON
425
541
553
574
Passer son tour
NIL
NIL
1
T
OBSERVER
NIL
NIL

SLIDER
48
523
219
556
taille-crayon
taille-crayon
0
20
6
1
1
NIL
HORIZONTAL

VIEW
419
65
821
467
0
0
0
1
1
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

MONITOR
55
103
219
152
nombre-coups-restants
NIL
3
1

MONITOR
418
483
818
532
informations
NIL
3
1

SWITCH
49
480
218
513
selection-parcelle
selection-parcelle
0
1
-1000

MONITOR
724
15
811
64
biodiv-moyen
NIL
3
1

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

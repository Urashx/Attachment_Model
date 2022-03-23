breed [parents parent]
parents-own [energy social vision pahead children]

breed [childs child]
childs-own [energy social security vision pahead caregivers with-cg cry summean sumvar shyticks]

breed [ foods food ]
foods-own [ energy ]

to setup
  clear-all
  init-food
  init-groups
  reset-ticks
end

to go
  let save_name (word "FearStranger/results" date-and-time ".csv")
  if not any? parents or not any? childs [
    ;export-all-plots save_name
    ;setup
    stop
  ]
  ask foods [
    grow-food
  ]
  ask childs
  [
    update_patches
    winner_take_all
    death
    stay_with_caregiver
    update_val
    update_metrics
  ]
  ask parents
  [
    update_patches
    winner_take_all
    ;reproduce
    death
    update_val
  ]
  tick
  if ticks = 36000 [
    file-open "shyness.txt"
    file-print ( mean [ shyticks ] of childs )
    file-close
    ;export-all-plots save_name
    setup
  ]
end


to wander
   if random 10 < 3 [
   set heading heading + ((random 5) - 3) * 45
  ]
   nfd
end

to winner_take_all
  let foodinvision 0
  if any? foods-on vision
  [
    set foodinvision 1
  ]

  let socialinvisionparent 0
  if any? parents-on vision or any? childs-on vision
  [
    set socialinvisionparent 1
  ]
  let d_energy (2 - energy)
  let d_social (2 - social)
  let list_motivation list ( d_energy + incentive * d_energy * foodinvision) (d_social + incentive * d_social * socialinvisionparent)
  let list_deficit list d_energy d_social
  let action 0
  if breed = childs [

    let childinvision 0
    if any? childs-on vision
    [
      set childinvision 1
    ]
    let fearinvision 0
    let parents_in_vision other parents-on vision
    let finded 0
    let cgs caregivers
    let me self
    if any? parents_in_vision [
      ask parents_in_vision [
        if member? self cgs [
          set finded 1
        ]
      ]
    ]

    if finded = 0
    [
      if any? parents_in_vision [
        set fearinvision 1
        if with-cg = 1
        [
          set shyticks ( shyticks + 1 )
        ]
      ]
    ]

    let d_security (2 - security)
    set list_motivation (list ( d_energy + incentive * d_energy * foodinvision) (d_social + incentive * d_social * childinvision) (d_security + autonomy + incentive * d_security * fearinvision))
    set list_deficit (list d_energy d_social d_security)
  ]
  if breed = parents [
   if not (children = NOBODY) [
     ask children [
        if cry = 1 [
          set action -1
          ask myself [
            face children
            nfd
          ]
        ]
     ]
   ]
  ]
  if not (action = -1) [
    let max_motivation max list_motivation
    let max_deficit max list_deficit
    set action (position max_motivation list_motivation)

    ifelse max_deficit > 0 [
      if action = 0 [
        eat
        set color red
      ]
      if action = 1 [
        groom
        set color blue
      ]
      if action = 2 [
        find-caregiver
        set color violet
      ]
    ]
    [
      wander
      set color green
    ]
  ]

end

to find-caregiver
  let parents_in_vision other parents-on vision
  let finded 0
  let cgs caregivers
  let me self
  if any? parents_in_vision [
    ask parents_in_vision [
      if member? self cgs [
        let target self
        set finded 1
        ask me [ face target ]
      ]
    ]
  ]

  ifelse finded = 1
  [
    nfd
  ]
  [
    set cry 1
    ifelse any? parents_in_vision [
      face one-of parents_in_vision
      set heading heading + 180
      nfd
    ]
    [
      wander
    ]
  ]
end

to stay_with_caregiver
  ;if near the caregiver add security
  let distance_cg 999
  let me self
  ask my-links [
      set distance_cg min list distance_cg link-length
  ]

  ifelse distance_cg <= 2 [
    set security security + 0.05
    set with-cg 1
    set cry 0
  ]
  [
    set with-cg 0
  ]
end

to find-agent
  let child_in_vision other childs-on vision
  let parents_in_vision other parents-on vision

  ifelse any? child_in_vision [
    face one-of child_in_vision
    nfd
  ]
  [
    ifelse breed = parents and any? parents_in_vision
    [
      face one-of parents_in_vision
      nfd
    ]
    [
      wander
    ]
  ]

end

to groom
  let childs_ahead other childs-on pahead
  let parents_ahead other parents-on pahead
  ifelse count childs_ahead > 0
  [
    set social social + 0.05
    ask childs_ahead [
      set social social + 0.05
    ]
  ]
  [
    ifelse breed = parents and count parents_ahead > 0
    [
      set social social + 0.05
      ask parents_ahead [
        set social social + 0.05
      ]
    ]
    [ find-agent ]
  ]

end

to find-food
  ifelse any? foods-on vision [
    face one-of other foods-on vision
    nfd
  ]
  [
   wander
  ]
end

to eat

 ifelse count foods-on pahead > 0
  [
    ;ifelse breed = childs [
      ;ifelse with-cg = 0 [
       ; set cry 1
      ;]
      ;[
       ; set energy energy + 0.5
      ;  ask foods-on pahead [
       ;   set energy energy - 0.5
       ;   death
       ; ]
      ;]
   ; ]
    ;[
      set energy energy + 0.05
      ask foods-on pahead [
        set energy energy - 0.05
        death
    ;  ]
    ]
  ]
  [
    find-food
  ]


end

to reproduce
  ;; give birth to a new rabbit, but it takes lots of energy
  if energy > 2
    [
      set energy energy / 2
      hatch 1 [
        wander
        wander
        set heading (random 8) * 45
        set energy random-float 1
        set social random-float 1
        set security random-float 1
      ]
      wander
      wander
  ]
end

to death

  if energy < 0 [ die ]

end

to update_patches
  if breed = childs [
    set vision patches in-cone 10 120
    set pahead patches in-cone 2 120
  ]

  if breed = parents [
    set vision patches in-cone 20 120
    set pahead patches in-cone 2 120
  ]
end

to init-food
  create-foods 1 [
    set color yellow
    setxy -20 -20
    set energy 15 + random-float 3
    set size 3
    set shape "circle"
  ]

    create-foods 1 [
    set color yellow
    setxy 20 20
    set energy 15 + random-float 3
    set size 3
    set shape "circle"
  ]


  create-foods 1 [
    set color yellow
    setxy 20 -20
    set energy 15 + random-float 3
    set size 3
    set shape "circle"
  ]

    create-foods 1 [
    set color yellow
    setxy -20 20
    set energy 15 + random-float 3
    set size 3
    set shape "circle"
  ]
end


to init-groups
  repeat number_of_groups [
    let x round random-xcor
    let y round random-ycor
    let c 0
    let p1 0
    let p2 0
    let cgs []
    create-childs 1 [
      set color red
      setxy (x + round random 10)  (y + round random 10)
      set heading (random 8) * 45
      set energy 0.75 + random-float 0.5
      set social 0.75 + random-float 0.5
      set security 0.75 + random-float 0.5
      set size 3
      set c self
      set with-cg 0
      set cry 0
      set summean 0
      set sumvar  0
      set shyticks 0
    ]
    create-parents number_of_cgs [
      set color red
      setxy (x + round random 10)  (y + round random 10)
      set heading (random 8) * 45
      set energy 0.75 + random-float 0.5
      set social 0.75 + random-float 0.5
      set size 4
      create-link-with c
      set cgs lput self cgs
      set children c
      ]

    ask c [
     set caregivers (turtle-set cgs )
    ]



  ]
end

to nrt
  set heading round( heading / 45) * 45
end

to nfd
  nrt
  ifelse (heading mod  90) = 0
  [ fd 1]
  [ fd sqrt 2]
end


to grow-food
  set energy energy + 0.05
  set label precision energy 3
end

to update_val
  set energy energy - 0.001
  set social social - 0.001
  if breed = childs [
    set security security - 0.001

    let parents_in_vision other parents-on vision
    let finded 0
    let cgs caregivers
    let me self
    if any? parents_in_vision [
      ask parents_in_vision [
        if member? self cgs [
          set finded 1
        ]
      ]
    ]

    if finded = 0
    [
      if any? parents_in_vision [
        set security security - 0.05
      ]
    ]

    if security > 2.01 [
      set security 2.01
    ]
  ]

  if energy > 2.01 [
    set energy 2.01
  ]

  if social > 2.01 [
    set social 2.01
  ]
end

to update_metrics
  let moy (( energy + social + security - 6) / 3)
  let var ((( energy - 2 - moy ) ^ 2 + ( social - 2 - moy ) ^ 2 + ( security - 2 - moy ) ^ 2 ) / 3)
  set summean summean + moy
  set sumvar sumvar + var
end

; Copyright 2001 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
296
13
1096
814
-1
-1
8.0
1
10
1
1
1
0
1
1
1
-49
49
-49
49
1
1
1
ticks
30.0

BUTTON
48
215
103
248
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
113
215
168
248
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
0

SLIDER
35
42
261
75
number_of_groups
number_of_groups
0.0
500.0
5.0
1.0
1
NIL
HORIZONTAL

MONITOR
141
321
230
366
count childs
count childs
1
1
11

BUTTON
172
216
238
249
Go (1)
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

PLOT
1109
24
1442
280
Energy Adults
NIL
NIL
0.0
4.0
0.0
4.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ energy ] of parents"

PLOT
1462
26
1795
277
Social Adults
NIL
NIL
0.0
4.0
0.0
4.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ social ] of parents"

PLOT
1807
290
2138
536
Security Childs
NIL
NIL
0.0
10.0
0.0
4.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ security ] of childs"

MONITOR
150
393
207
438
Time (s)
ticks / 30
2
1
11

MONITOR
144
449
214
494
Time (min)
ticks / 30 / 60
2
1
11

PLOT
1109
286
1442
541
Energy Childs
NIL
NIL
0.0
10.0
0.0
4.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ energy ] of childs"

PLOT
1463
288
1792
536
Social Childs
NIL
NIL
0.0
10.0
0.0
4.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ social ] of childs"

PLOT
1808
27
2136
279
Populations
Time
Pop
0.0
100.0
0.0
111.0
true
true
"set-plot-y-range 0 number_of_groups + 1" ""
PENS
"Parents" 1.0 0 -2674135 true "" "plot count parents"
"Childs" 1.0 0 -955883 true "" "plot count childs"

MONITOR
141
270
241
315
count parents
count parents
17
1
11

PLOT
1109
548
1442
801
Mean Error
NIL
NIL
0.0
1.0
0.0
0.3
true
true
"" "ask childs [\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color color\n  plotxy ticks summean / (ticks + 1)\n]"
PENS

PLOT
1463
548
1791
801
Mean Variance
NIL
NIL
0.0
1.0
0.0
0.3
true
true
"" "ask childs [\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color color\n  plotxy ticks sumvar / (ticks + 1)\n]"
PENS

SLIDER
35
87
260
120
number_of_cgs
number_of_cgs
0
2
2.0
1
1
NIL
HORIZONTAL

SLIDER
35
128
260
161
autonomy
autonomy
-1
1
0.0
0.05
1
NIL
HORIZONTAL

SLIDER
35
171
260
204
incentive
incentive
0
1
0.1
0.05
1
NIL
HORIZONTAL

PLOT
1807
549
2137
804
Number of ticks with shyness-like behaviour
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" "ask childs [\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color color\n  plotxy ticks shyticks\n]"
PENS

MONITOR
8
518
291
563
Mean number of ticks with shyness-like behaviour
mean[shyticks] of childs
17
1
11

PLOT
6
585
288
809
Mean number of thicks with shyness-like behaviour
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
"default" 1.0 0 -16777216 true "" "plot mean [shyticks] of childs"

@#$#@#$#@
## WHAT IS IT?

This project explores a simple ecosystem made up of rabbits, grass, and weeds. The rabbits wander around randomly, and the grass and weeds grow randomly.   When a rabbit bumps into some grass or weeds, it eats the grass and gains energy. If the rabbit gains enough energy, it reproduces. If it doesn't gain enough energy, it dies.

The grass and weeds can be adjusted to grow at different rates and give the rabbits differing amounts of energy.  The model can be used to explore the competitive advantages of these variables.

## HOW TO USE IT

Click the SETUP button to setup the rabbits (red), grass (green), and weeds (violet). Click the GO button to start the simulation.

The NUMBER slider controls the initial number of rabbits. The BIRTH-THRESHOLD slider sets the energy level at which the rabbits reproduce.  The GRASS-GROWTH-RATE slider controls the rate at which the grass grows.  The WEEDS-GROWTH-RATE slider controls the rate at which the weeds grow.

The model's default settings are such that at first the weeds are not present (weeds-grow-rate = 0, weeds-energy = 0).  This is so that you can look at the interaction of just rabbits and grass.  Once you have done this, you can start to add in the effect of weeds.

## THINGS TO NOTICE

Watch the COUNT RABBITS monitor and the POPULATIONS plot to see how the rabbit population changes over time. At first, there is not enough grass for the rabbits, and many rabbits die. But that allows the grass to grow more freely, providing an abundance of food for the remaining rabbits. The rabbits gain energy and reproduce. The abundance of rabbits leads to a shortage of grass, and the cycle begins again.

The rabbit population goes through a damped oscillation, eventually stabilizing in a narrow range. The total amount of grass also oscillates, out of phase with the rabbit population.

These dual oscillations are characteristic of predator-prey systems. Such systems are usually described by a set of differential equations known as the Lotka-Volterra equations. NetLogo provides a new way of studying predatory-prey systems and other ecosystems.

## THINGS TO TRY

Leaving other parameters alone, change the grass-grow-rate and let the system stabilize again.  Would you expect that there would now be more grass?  More rabbits?

Change only the birth-threshold of the rabbits.  How does this affect the steady-state levels of rabbits and grass?

With the current settings, the rabbit population goes through a damped oscillation. By changing the parameters, can you create an undamped oscillation? Or an unstable oscillation?

In the current version, each rabbit has the same birth-threshold. What would happen if each rabbit had a different birth-threshold? What if the birth-threshold of each new rabbit was slightly different from the birth-threshold of its parent? How would the values for birth-threshold evolve over time?

Now add weeds by making the sliders WEEDS-GROW-RATE the same as GRASS-GROW-RATE and WEEDS-ENERGY the same as GRASS-ENERGY.  Notice that the amount of grass and weeds is about the same.

Now make grass and weeds grow at different rates.  What happens?

What if the weeds grow at the same rate as grass, but they give less energy to the rabbits when eaten (WEEDS-ENERGY is less than GRASS-ENERGY)?

Think of other ways that two plant species might differ and try them out to see what happens to their relative populations.  For example, what if a weed could grow where there was already grass, but grass couldn't grow where there was a weed?  What if the rabbits preferred the plant that gave them the most energy?

Run the model for a bit, then suddenly change the birth threshold to zero.  What happens?

## NETLOGO FEATURES

Notice that every black patch has a random chance of growing grass or
weeds each turn, using the rule:

    if random-float 1000 < weeds-grow-rate
      [ set pcolor violet ]
    if random-float 1000 < grass-grow-rate
      [ set pcolor green ]

## RELATED MODELS

Wolf Sheep Predation is another interacting ecosystem with different rules.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (2001).  NetLogo Rabbits Grass Weeds model.  http://ccl.northwestern.edu/netlogo/models/RabbitsGrassWeeds.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2001 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.

<!-- 2001 -->
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

rabbit
false
0
Circle -7500403 true true 76 150 148
Polygon -7500403 true true 176 164 222 113 238 56 230 0 193 38 176 91
Polygon -7500403 true true 124 164 78 113 62 56 70 0 107 38 124 91

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
NetLogo 6.2.2
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

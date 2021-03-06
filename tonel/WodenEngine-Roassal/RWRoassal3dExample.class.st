"
RWRoassal3dExample new installTitle: 'MatrixHandling' 
		code:
		'
| v es |
v := RWView new.
es := RWCube elementsOn: (1 to: 10).
v addAll: es.
RWCubeLayout on: es.

es when: RWMouseButtonDown do: [ :evt |
        | node |
        node := evt element sceneNode.
          node shapeMatrix: (WDMatrix4 scale: 1.1) * (node shapeMatrix )
         ].

^	 v'
	
"
Class {
	#name : #RWRoassal3dExample,
	#superclass : #RWAbstractExample,
	#category : 'WodenEngine-Roassal-Examples'
}

{ #category : #sources }
RWRoassal3dExample >> exampleClickAddAbove [

	| v e cube position action |
	cube := RWCube new.
	v := RWView new.
	action := nil.
	action := [ :ev |
			position := ev element position.
			position y: position y + 1.05. 
			e := cube element.
			e translateTo: position;
				when: RWMouseButtonDown do: action.
			v add: e
	].
	
	1 to: 1024 do: [ :i |
		e := cube element.
		e when: RWMouseButtonDown do: action.
		v add: e.
	].
	(RWXZGridLayout gap: 0.05) on: v elements.
	v addInteraction: RWMouseKeyControl.
	v camera position: (WMVector3F x: 0.0 y: 3.0 z: 0.0).
^ v
]

{ #category : #sources }
RWRoassal3dExample >> exampleClickLeds [

	| v e colors cube |
	colors := {  Color gray . Color red . Color green . Color blue . Color yellow . Color white}.
	cube := RWCube new.
	cube color: [ :val | colors at: val ].
	
	v := RWView new.
	
	1 to: 1024 do: [ :i |
		e := cube elementOn: 1.
		e when: RWMouseButtonDown do: [ :ev |
			ev element model: ev element model + 1.
			ev element model > colors size ifTrue: [ ev element model: 1 ].
			ev element changed.
		].
		e when: RWMouseButtonUp do: [ :ev |
			ev element model: ev element model + 1.
			ev element model > colors size ifTrue: [ ev element model: 1 ].
			ev element changed.
		].

		v add: e.
	].
	(RWXZGridLayout gap: 0.05) on: v elements.
	v addInteraction: RWMouseKeyControl.
	v camera position: (WMVector3F x: 0.0 y: 3.0 z: 0.0).

^ v
]

{ #category : #sources }
RWRoassal3dExample >> exampleClickToGetGreen [

	| v e |
	v := RWView new.

	1 to: 100 do: [ :i |
		e := RWCube element.
		e when: RWMouseButtonDown do: [ :ev |
			ev element shape color: Color green.
			ev element changed.
		].
		v add: e.
	].
	RWXZGridLayout on: v elements.
	v addInteraction: RWMouseKeyControl.
	v camera position: (WMVector3F x: 0.0 y: 0.0 z: 3.0).

^ v
]

{ #category : #sources }
RWRoassal3dExample >> exampleCone [

	| v |
	v := RWView new.
	v add: RWCone element.
	v camera position: (WMVector3F x: 0.0 y: 0.0 z: 3.0). 
	v  @ RWMouseKeyControl.

	^ v
]

{ #category : #sources }
RWRoassal3dExample >> exampleCylinder [

	| v |
	v := RWView new.
	v add: RWCylinder element.
	v  @ RWMouseKeyControl.
	

^	 v
]

{ #category : #sources }
RWRoassal3dExample >> exampleHighlighting [
	| v es |
	v := RWView new.
	es := ((RWCube new size: 1)) elementsOn: (1 to: 16).

	es @ (RWHighlightable highlight: [ :vv | | arr |
		
		arr := OrderedCollection new.
		arr add: vv - 1.
		arr add: vv.
		arr add: vv + 1.
		arr add: vv - 4.
		arr add: vv + 4.
		arr]).

	RWXYGridLayout on: es.
	v addAll: es.
^	 v
]

{ #category : #sources }
RWRoassal3dExample >> exampleIncreasingCubeSize [

| e v |
v := RWView new.

e := RWCube element.

v add: e.

e when: RWMouseButtonDown do: [ :evt | 
	evt element shape width: 2.
	evt element shape height: 2.
	evt element shape color: Color green.
	
	e changed.
].
^	 v
]

{ #category : #sources }
RWRoassal3dExample >> exampleLine [

| es v |

v := RWView new.
es := RWCube elementsOn: (1 to: 20).
v addAll: es.
RWCircleLayout on: es.
es @ RWPopup.

2 to: 20 do: [ :i |  
	v add: (RWLine edgeFrom: (v elementFromModel: i) to: (v elementFromModel: 1))
].

^	 v
]

{ #category : #sources }
RWRoassal3dExample >> exampleManyCubes [

| v cubes |
v := RWView new.
cubes := RWCube elementsOn: (1 to: 100).

v addAll: cubes.
RWCubeLayout on: cubes.
^ v
]

{ #category : #sources }
RWRoassal3dExample >> exampleMatrixHandling [

| v es |
v := RWView new.
es := RWCube elementsOn: (1 to: 10).
v addAll: es.
RWCubeLayout on: es.

es when: RWMouseButtonDown do: [ :evt |
        | node |
        node := evt element sceneNode.
          node shapeMatrix: (WMMatrix4F scale: 1.1) * (node shapeMatrix )
         ].

^	 v
]

{ #category : #sources }
RWRoassal3dExample >> exampleMenu [

| classes v n shape es |

classes := RTObject withAllSubclasses.
v := RWView new.
n := RTMultiLinearColorForIdentity new objects: classes.
shape := RWUVSphere new size: [ :c | (c numberOfMethods / 100) + 1 ] ; color: [ :cls | (n rtValue: cls) ].
es := shape elementsOn: classes.
es @ (RWMenuActivable new action: #inspect; item: 'browse class' action: [ :e | e model browse ]).
v addAll: es.
RWCubeLayout on: es.

^	 v
]

{ #category : #sources }
RWRoassal3dExample >> examplePopup [

| v es shape |
v := RWView new.

shape := RWCube new color: [ :m | Color random ].
es := shape elementsOn: (1 to: 100).
RWCubeLayout on: es.
v addAll: es.

es do: [ :e | e addInteraction: RWPopup ].

^	 v
]

{ #category : #sources }
RWRoassal3dExample >> exampleRedLight [

	| v |
	v := RWView new.
	v add: (RWCube element).
	v add: (RWPointLight new color: Color red).
	v add: (RWCube element).
	v add: (RWCube element).
	RWXLineLayout on: v elements.
	v addInteraction: RWMouseKeyControl.

^	 v
]

{ #category : #sources }
RWRoassal3dExample >> exampleSimpleCube [

| v c |
v := RWView new.
c := RWCube new.
v add: c element.
^ v
]

{ #category : #sources }
RWRoassal3dExample >> exampleSpheres [

	| view shape |
	view := RWView new.
	shape := RWUVSphere new .
	shape width: [ :v | (v log + 1) ];
		height: [ :v | (v log + 2)];
		depth: [ :v | (v log + 3) ].

	view addAll: ( shape elementsOn: (1 to: 1000)).

	RWCubeLayout on: view elements.
	view @ RWMouseKeyControl .

^	 v
]

{ #category : #icons }
RWRoassal3dExample >> exampleSpheresIcon [
	^ 'iVBORw0KGgoAAAANSUhEUgAAAGQAAAA8CAYAAACQPx/OAAAXgElEQVR4XuXcVa80VdoG4Pof
aJCg4RR3d5khBIIFSYDg7jY4gw4wuLu7u7u7uwwOAwQOqMlV+e6dtdfu6u79vidfwkGlu6ur
1iP3Y0ubCy+8sL3gggva888/vz3vvPPac889d+I655xz2rPPPrs966yz2jPPPLP997//3V1n
nHFGe/rpp7ennXZae+qpp7annHJKe/LJJ7cnnXRSe+KJJ7b//Oc/2+OOO6495phj2qOOOqo9
4ogj2sMOO6w95JBD2oMOOqg94IAD2v3226/dZ5992r322qvdc8892913373dZZddJi503n77
7fbbb79t//zzz/a1115rn3322fbhhx9ub7/99vbyyy/v+Ft22WXbpmkmrsMPP7yT56abbmrv
v//+9umnn27feOON9ueff25/++237l5Jx7XHHnt0fOy7777t/vvv3x544IHtwQcf3B566KFd
e/gnx9FHH90ee+yx7fHHH9/JSFYyk50O6IJO6IaOyEBv9EeP0Ss90zc+6T/XRRdd1DaDwCDo
KDD+9a9/DQTjhBNO6BjGOAGOPPLI9h//+EcnHCEJS2iA7L333p0igLHrrrtOUhLB7rnnnvbD
Dz9sP//88/all15qn3jiiU6hN998c3vJJZd0ilpuueUmAeIeGa6//vru/ccee6x9/vnn2w8+
+KB98cUX27vvvnsKIOjjg4Hgi8H0gcLIGBsZyVqCQh/0gvcAUoJCp6NAaQaBUQJRg4HYMDBq
7wDGKO/YbbfdpiiJQu+77772xhtvbB9//PHO0h966KH2rrvuaq+99tpOGEpbe+21JwGCFwZz
1VVXtbfddlv7wAMPdEB61z3vk6mkhT4+GAi+GExAwTf+ycG4SlDI2gdK6SWueMkgUEpgmj4w
XINCVAkGJgaBEe9gVayr9g6hgfAJVbV3uCjxwQcf7MITRd55552ddd9yyy3tZZddNsHTGmus
MQkQtPHCg4AKAO0AVlsBqC9s4SuhCyiMqAYloSugBBDXOKGrBKX2lmY6+SJglF6RnMGFSzDG
8Q5KGOQdLh7xyCOPdGFHPsCwUHX11Vd330NvpZVWmgQI60WXLPKMdwHqU1va1DYeB3lJQleZ
T6YDSvJJQhfd1aEroNTe4mpmBox4RZRDGckbM+MdLOW5557rLJlFx0skPW6NJwpCZ/HFF58E
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
EDkm9n/fnHqnAjVgugAAAABJRU5ErkJggg=='
]

{ #category : #sources }
RWRoassal3dExample >> exampleThreeCubesAndLightWithShadows [

	
	| v floor light|
	v := RWView new.
	v add: (RWCube element).
	v add: (RWCube element).
	v add: (RWCube element).
	RWXLineLayout on: v elements.
	
	floor := RWCube new width: 10.0; depth: 5.0; height: 0.1; element.
	floor translateByY: -0.6.
	v add: floor.
	
	light := RWSpotLight new.
	light lookDown;
		translateByX: 2.0 y: 3.0 z: 0.0;
		influenceRadius: 10.0;
		castShadows: true.
	v add: light.
	v addInteraction: RWMouseKeyControl.
	v withShadows.

^	 v
]

{ #category : #sources }
RWRoassal3dExample >> exampleTransparencAlphay [

| v els shape |
"Alpha over transparency"

v := RWView new.
shape := RWCube new alphaOverTranslucent color: (Color red a: 0.8).
els := shape elementsOn: (1 to: 20).
v addAll: els.
RWCubeLayout on: els.
v addInteraction: RWMouseKeyControl.
^	 v
]

{ #category : #sources }
RWRoassal3dExample >> exampleTransparency [

| v els shape |
"Additive blending"
v := RWView new.
shape := RWCube new color: (Color gray).
els := shape elementsOn: (1 to: 10).
v addAll: els.

shape := RWCube new translucent color: (Color red a: 0.5).
els := shape elementsOn: (11 to: 20).
v addAll: els.

RWCubeLayout on: els.
v addInteraction: RWMouseKeyControl.
^	 v
]

{ #category : #accessing }
RWRoassal3dExample >> label [
	^ 'Roassal 3d'
]

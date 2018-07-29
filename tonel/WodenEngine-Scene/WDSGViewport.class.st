"
I represent a rendering viewport.
"
Class {
	#name : #WDSGViewport,
	#superclass : #Object,
	#instVars : [
		'camera',
		'cameraState',
		'bounds',
		'submode',
		'filter',
		'renderTarget',
		'resolveRenderTarget',
		'cameraTransformFunction',
		'cameraTransform',
		'overlayRenderer',
		'pompeiiCanvasSafeZoneTransform'
	],
	#pools : [
		'AGPUConstants'
	],
	#category : #'WodenEngine-Scene-Graph'
}

{ #category : #accessing }
WDSGViewport >> applyPompeiiCanvasSafeZoneTransform: aPompeiiCanvasTransform [
	aPompeiiCanvasTransform loadIdentity.
	pompeiiCanvasSafeZoneTransform ifNotNil: [ pompeiiCanvasSafeZoneTransform value: aPompeiiCanvasTransform ]
]

{ #category : #accessing }
WDSGViewport >> bounds [
	^ bounds
]

{ #category : #accessing }
WDSGViewport >> bounds: anObject [
	bounds := anObject
]

{ #category : #accessing }
WDSGViewport >> camera [
	^ camera
]

{ #category : #accessing }
WDSGViewport >> camera: anObject [
	camera := anObject
]

{ #category : #accessing }
WDSGViewport >> cameraState [
	^ cameraState
]

{ #category : #accessing }
WDSGViewport >> cameraState: anObject [
	cameraState := anObject
]

{ #category : #accessing }
WDSGViewport >> cameraTransform [
	^ cameraTransform ifNil: [ cameraTransform := cameraTransformFunction value: camera renderTransform ]
]

{ #category : #accessing }
WDSGViewport >> cameraTransformFunction [
	^ cameraTransformFunction
]

{ #category : #accessing }
WDSGViewport >> cameraTransformFunction: anObject [
	cameraTransformFunction := anObject
]

{ #category : #accessing }
WDSGViewport >> filter [
	^ filter
]

{ #category : #accessing }
WDSGViewport >> filter: anObject [
	filter := anObject
]

{ #category : #initialization }
WDSGViewport >> initialize [
	super initialize.
	filter := [ :object | true ].
	cameraTransformFunction := [ :x | x ]
]

{ #category : #accessing }
WDSGViewport >> overlayRenderer [
	^ overlayRenderer
]

{ #category : #accessing }
WDSGViewport >> overlayRenderer: anObject [
	overlayRenderer := anObject
]

{ #category : #accessing }
WDSGViewport >> pompeiiCanvasSafeZoneTransform [
	^ pompeiiCanvasSafeZoneTransform
]

{ #category : #accessing }
WDSGViewport >> pompeiiCanvasSafeZoneTransform: anObject [
	pompeiiCanvasSafeZoneTransform := anObject
]

{ #category : #accessing }
WDSGViewport >> renderTarget [
	^ renderTarget
]

{ #category : #accessing }
WDSGViewport >> renderTarget: anObject [
	renderTarget := anObject
]

{ #category : #accessing }
WDSGViewport >> resolveRenderTarget [
	^ resolveRenderTarget
]

{ #category : #accessing }
WDSGViewport >> resolveRenderTarget: anObject [
	resolveRenderTarget := anObject
]

{ #category : #accessing }
WDSGViewport >> submode [
	^ submode
]

{ #category : #accessing }
WDSGViewport >> submode: anObject [
	submode := anObject
]
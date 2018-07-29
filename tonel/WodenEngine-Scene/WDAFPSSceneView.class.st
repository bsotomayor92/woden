"
I am a sample scene view that uses first person shooter game style controls for movement.
"
Class {
	#name : #WDAFPSSceneView,
	#superclass : #WDASceneViewWithPompeii,
	#instVars : [
		'cameraVelocity',
		'cameraSpeed',
		'cameraAngle',
		'cameraAngularVelocity',
		'cameraAngularSpeed',
		'lastFrameRateDrawing',
		'lastFrameRateCountFrame',
		'lastFrameDeltaTime'
	],
	#category : #'WodenEngine-Scene-Application'
}

{ #category : #accessing }
WDAFPSSceneView >> cameraAngle [
	^ cameraAngle
]

{ #category : #accessing }
WDAFPSSceneView >> cameraAngle: anObject [
	cameraAngle := anObject
]

{ #category : #accessing }
WDAFPSSceneView >> cameraAngularSpeed [
	^ cameraAngularSpeed
]

{ #category : #accessing }
WDAFPSSceneView >> cameraAngularSpeed: anObject [
	cameraAngularSpeed := anObject
]

{ #category : #accessing }
WDAFPSSceneView >> cameraAngularVelocity [
	^ cameraAngularVelocity
]

{ #category : #accessing }
WDAFPSSceneView >> cameraAngularVelocity: anObject [
	cameraAngularVelocity := anObject
]

{ #category : #accessing }
WDAFPSSceneView >> cameraSpeed [
	^ cameraSpeed
]

{ #category : #accessing }
WDAFPSSceneView >> cameraSpeed: anObject [
	cameraSpeed := anObject
]

{ #category : #accessing }
WDAFPSSceneView >> cameraVelocity [
	^ cameraVelocity
]

{ #category : #accessing }
WDAFPSSceneView >> cameraVelocity: anObject [
	cameraVelocity := anObject
]

{ #category : #'drawing 2d' }
WDAFPSSceneView >> computeFrameDeltaTime [
	| currentTime |
	self flag: 'TODO: Use GPU timestamp query.'.
	lastFrameRateDrawing ifNil: [ lastFrameRateDrawing := Time microsecondClockValue ].
	lastFrameRateCountFrame ~~ engine frameBufferingDriver frameIndex ifTrue: [
		currentTime := Time microsecondClockValue.
		lastFrameDeltaTime := (currentTime - lastFrameRateDrawing) / 1000.0.
		lastFrameRateDrawing := currentTime.
		lastFrameRateCountFrame := engine frameBufferingDriver frameIndex
	].

	^ lastFrameDeltaTime



]

{ #category : #'drawing 2d' }
WDAFPSSceneView >> drawFrameRateOn: canvas [
	| deltaTime builder mesh |
	deltaTime := self computeFrameDeltaTime.
	
	builder := canvas driver mesh2DBuilder.
	builder text
		color: Color green;
		font: self pompeiiDefaultFont;
			position: (0 @ self pompeiiDefaultFont getPreciseAscent);
			draw: ('CPU Frame Rate {1} ms / {2} FPS' format: {
				deltaTime printShowingDecimalPlaces: 3 .
				1000.0 / (deltaTime max: 0.01) printShowingDecimalPlaces: 3}).
	mesh := builder mesh.
	
	canvas draw: mesh.
]

{ #category : #rendering }
WDAFPSSceneView >> drawOnPompeiiCanvas: canvas [
	self drawFrameRateOn: canvas
]

{ #category : #initialization }
WDAFPSSceneView >> initialize [
	super initialize.

	cameraVelocity := WMVector3F new.
	cameraSpeed := 1.0.
	
	cameraAngle := WMVector3F new.
	cameraAngularVelocity := WMVector3F new.
	cameraAngularSpeed := 1.0.
]

{ #category : #'rendering process stages' }
WDAFPSSceneView >> updateForFrameDelta: delta [
	| orientation |
	cameraAngle := cameraAngle + (cameraAngularVelocity * (cameraAngularSpeed * delta)).
	screenDisplayMode isVR ifTrue: [ 
		orientation := WMMatrix3F yrot: cameraAngle y.
	] ifFalse: [ 
		orientation := (WMMatrix3F yrot: cameraAngle y) * (WMMatrix3F xrot: cameraAngle x).
	].

	"vrSensorReader ifNotNil: [ 
		sensorState := vrSensorReader sensorState.
		orientation := sensorState orientation asWMMatrix3F * orientation.
		camera vrTransform translation: sensorState translation
	]."

	self camera transform
		orthonormal: orientation;
		translateBy: (orientation transformVector3: (cameraVelocity * (cameraSpeed * delta))).

]

{ #category : #visiting }
WDAFPSSceneView >> visitKeyDownEvent: anEvent [
	anEvent repeat > 0 ifTrue: [ ^ 0 ].
	anEvent symbol = OSK_F11 ifTrue: [ self toggleFullscreen ].

	anEvent symbol = OSK_a ifTrue: [ cameraVelocity x: -1.0 ].
	anEvent symbol = OSK_d ifTrue: [ cameraVelocity x: 1.0 ].
	anEvent symbol = OSK_w ifTrue: [ cameraVelocity z: -1.0 ].
	anEvent symbol = OSK_s ifTrue: [ cameraVelocity z: 1.0 ].
	anEvent symbol = OSK_LCTRL ifTrue: [ cameraVelocity y: -1.0 ].
	anEvent symbol = OSK_SPACE ifTrue: [ cameraVelocity y: 1.0 ].

	anEvent symbol = OSK_UP ifTrue: [ cameraAngularVelocity x: 1.0 ].
	anEvent symbol = OSK_DOWN ifTrue: [ cameraAngularVelocity x: -1.0 ].
	anEvent symbol = OSK_LEFT ifTrue: [ cameraAngularVelocity y: 1.0 ].
	anEvent symbol = OSK_RIGHT ifTrue: [ cameraAngularVelocity y: -1.0 ].
	
	anEvent symbol = OSK_LSHIFT ifTrue: [ cameraSpeed := 3.0 ].
	
	screenDisplayMode vrSensorReader ifNotNil: [ :sensor |
		anEvent symbol = OSK_1 ifTrue: [ sensor recenter ]. 
		anEvent symbol = OSK_2 ifTrue: [ sensor calibrate ].
	].
	
	(anEvent modifiers leftAlt and: [ anEvent symbol = OSK_i ]) ifTrue: [ self inspect ].
]

{ #category : #visiting }
WDAFPSSceneView >> visitKeyUpEvent: anEvent [
	anEvent symbol = OSK_a ifTrue: [ cameraVelocity x < 0 ifTrue: [ cameraVelocity x: 0.0 ] ].
	anEvent symbol = OSK_d ifTrue: [ cameraVelocity x > 0 ifTrue: [ cameraVelocity x: 0.0 ] ].
	anEvent symbol = OSK_w ifTrue: [ cameraVelocity z < 0 ifTrue: [ cameraVelocity z: 0.0 ] ].
	anEvent symbol = OSK_s ifTrue: [ cameraVelocity z > 0 ifTrue: [ cameraVelocity z: 0.0 ] ].

	anEvent symbol = OSK_UP ifTrue: [ cameraAngularVelocity x > 0 ifTrue: [ cameraAngularVelocity x: 0.0 ] ].
	anEvent symbol = OSK_DOWN ifTrue: [ cameraAngularVelocity x < 0 ifTrue: [ cameraAngularVelocity x: 0.0 ] ].
	anEvent symbol = OSK_LEFT ifTrue: [ cameraAngularVelocity y > 0 ifTrue: [ cameraAngularVelocity y: 0.0 ] ].
	anEvent symbol = OSK_RIGHT ifTrue: [ cameraAngularVelocity y < 0 ifTrue: [ cameraAngularVelocity y: 0.0 ] ].
	
	anEvent symbol = OSK_LCTRL ifTrue: [ cameraVelocity y < 0 ifTrue: [ cameraVelocity y: 0.0 ] ].
	anEvent symbol = OSK_SPACE ifTrue: [ cameraVelocity y > 0 ifTrue: [ cameraVelocity y: 0.0 ] ].
	anEvent symbol = OSK_LSHIFT ifTrue: [ cameraSpeed := 1.0 ].
]
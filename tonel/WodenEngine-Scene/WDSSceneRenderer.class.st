Class {
	#name : #WDSSceneRenderer,
	#superclass : #Object,
	#instVars : [
		'currentScene',
		'stateTracker',
		'engine',
		'shaderSignature',
		'cameraStates',
		'visibleObjects',
		'visibleLightSources',
		'mainCamera',
		'currentTime',
		'objectsPerViewport',
		'currentCameraStates',
		'shadowCastingLights',
		'shadowCastingLightCount',
		'shadowMapBuffer',
		'shadowMapRenderTargets',
		'useLateLatching',
		'currentCameraViewports'
	],
	#pools : [
		'AGPUConstants'
	],
	#category : #'WodenEngine-Scene-Rendering'
}

{ #category : #'instance creation' }
WDSSceneRenderer class >> for: aWDCEngine [
	^ self new initializeWithEngine: aWDCEngine
]

{ #category : #accessing }
WDSSceneRenderer class >> maxShadowCastingLightCount [
	^ 4
]

{ #category : #'shadow mapping' }
WDSSceneRenderer class >> shadowMapExtent [
	^ 512 @ 512
]

{ #category : #initialization }
WDSSceneRenderer >> cameraStateFramebufferingCount [
	^ useLateLatching ifTrue: [ 1 ] ifFalse: [ engine frameBufferingCount ]
]

{ #category : #'rendering preparations' }
WDSSceneRenderer >> collectVisibleObjectsFor: camera [
	visibleObjects removeAll.
	visibleLightSources removeAll.
	currentScene roots do: [ :r |
		self collectVisibleObjectsFor: camera from: r
	]
	
]

{ #category : #'rendering preparations' }
WDSSceneRenderer >> collectVisibleObjectsFor: camera from: node [
	node visible ifFalse: [ ^ self ].
	
	visibleObjects add: node.
	node isLightSource ifTrue: [ self tryToCollectLightSource: node for: camera ].
	
	node isInstanceGroup ifFalse: [
		node children do: [:child |
			self collectVisibleObjectsFor: camera from: child
		]
	]
]

{ #category : #accessing }
WDSSceneRenderer >> currentTime [
	^ currentTime
]

{ #category : #accessing }
WDSSceneRenderer >> currentTime: anObject [
	currentTime := anObject
]

{ #category : #initialization }
WDSSceneRenderer >> ensureCameraStatesFor: requiredNumberOfCameras [
	| pool currentNumberOfCameras missingNumberOfCameras |
	cameraStates ifNil: [ 
		cameraStates := (1 to: self cameraStateFramebufferingCount) collect: [ :f | #() ].
	].
	
	currentNumberOfCameras := cameraStates first size.
	missingNumberOfCameras := requiredNumberOfCameras - currentNumberOfCameras.
	
	pool := engine resourceCache streamingUniformBufferPoolFor: WTCameraState.
	
	cameraStates := cameraStates collect: [ :oldFrameStates |
		oldFrameStates , ((pool allocate: missingNumberOfCameras) collect: [ :bufferElement |
			self shaderSignature newCameraState
				bind: 0 uniformBufferElement: bufferElement;
				yourself
		])
	].
]

{ #category : #initialization }
WDSSceneRenderer >> initializeWithEngine: aWDCEngine [
	engine := aWDCEngine.
	currentTime := 0.0.
	
	visibleObjects := OrderedCollection new.
	visibleLightSources := OrderedCollection new.
	useLateLatching := false.
	
]

{ #category : #'rendering preparations' }
WDSSceneRenderer >> prepareScene: scene renderingForViewports: viewports [
	| fullFrameIndex |
	currentScene := scene.
	viewports ifEmpty: [ ^ self ].
	mainCamera := viewports first camera.

	self collectVisibleObjectsFor: mainCamera.
	fullFrameIndex := engine frameBufferingDriver frameIndex.
	visibleObjects select: [:obj | obj useViewportCamera not ] thenDo: [ :obj | obj updateGpuStateForFrame: fullFrameIndex camera: mainCamera].
	objectsPerViewport := viewports collect: [ :viewport |
		visibleObjects select: viewport filter thenCollect: [ :element |
			element useViewportCamera ifTrue: [
				element updateGpuStateForFrame: fullFrameIndex camera: viewport camera
			].
			element
		]
	].
	self sortObjects: objectsPerViewport perViewports: viewports.
	
	self
		updateRenderingStatesFor: viewports
]

{ #category : #accessing }
WDSSceneRenderer >> renderMode [
	^ self subclassResponsibility
]

{ #category : #rendering }
WDSSceneRenderer >> renderScene: scene viewports: viewports [
	^ self renderScene: scene viewports: viewports composeWith: nil
]

{ #category : #rendering }
WDSSceneRenderer >> renderScene: scene viewports: viewports composeWith: aBlock [
	viewports ifEmpty: [ ^ nil ].

	^ self renderScene: scene viewports: viewports composeWith: aBlock mainResolveRenderTarget: viewports first resolveRenderTarget
]

{ #category : #rendering }
WDSSceneRenderer >> renderScene: scene viewports: viewports composeWith: aBlock mainResolveRenderTarget: resolveRenderTarget [
	| resolveFramebuffer |
	(viewports isEmpty and: [aBlock isNil]) ifTrue: [ ^ nil ].

	self prepareScene: scene renderingForViewports: viewports.	

	resolveFramebuffer := resolveRenderTarget currentFramebuffer.
	resolveFramebuffer validCommandAllocator reset.

	^ self stateTracker commandList: resolveFramebuffer validCommandList rebuildWith: [
		self renderViewports: viewports composeWith: aBlock.
	].

]

{ #category : #rendering }
WDSSceneRenderer >> renderScene: scene viewports: viewports intoStateTracker: aStateTracker [
	viewports isEmpty ifTrue: [ ^ nil ].

	stateTracker := aStateTracker.
	self prepareScene: scene renderingForViewports: viewports.	

	self setupStateTracker.
	viewports doWithIndex: [ :viewport :index | self renderViewport: viewport index: index ].
]

{ #category : #rendering }
WDSSceneRenderer >> renderViewport: viewport index: viewportIndex [
	| renderTarget resolveTarget renderPass |
	self setupStateTracker.
	renderTarget := viewport renderTarget.
	resolveTarget := viewport resolveRenderTarget.

	renderPass := renderTarget validMainRenderPass.
	renderPass setColorClearValue: 0 value: currentScene backgroundColor asAGPUColor4f.
	
	"Begin rendering into the viewport"
	stateTracker
		beginRenderPass: renderPass renderTarget: renderTarget bounds: viewport bounds.
	self setupViewportRendering: viewport index: viewportIndex.
	
	"Render the viewport objects"
	(objectsPerViewport at: viewportIndex) do: [ :object |
		object renderOn: stateTracker
	].

	"Render the overlays"
	viewport overlayRenderer ifNotNil: [ 
		viewport overlayRenderer renderViewport: viewport overlayWith: stateTracker 
	].
	
	"End rendering into the viewport"
	stateTracker endRenderPass.
	
	"Resolve the target"
	renderTarget ~~ resolveTarget ifTrue: [
		stateTracker resolveRenderTarget: renderTarget into: resolveTarget
	]

]

{ #category : #rendering }
WDSSceneRenderer >> renderViewports: viewports composeWith: aBlock [
	shadowCastingLightCount ~= 0 ifTrue: [ self renderShadowMaps ].
	
	viewports doWithIndex: [ :viewport :index | self renderViewport: viewport index: index ].
	aBlock ifNotNil: [ aBlock cull: stateTracker ]
]

{ #category : #'rendering preparations' }
WDSSceneRenderer >> selectShadowCastingLights [
	| lightSource |
	shadowCastingLights := Array new: self maxShadowCastingLightCount.
	shadowCastingLightCount := 0.
	visibleLightSources do: [ :l |
		lightSource := l first.
		lightSource isSpotLight ifTrue: [
			shadowCastingLightCount := shadowCastingLightCount + 1.
			shadowCastingLights at: shadowCastingLightCount put: lightSource.
			shadowCastingLightCount = shadowCastingLights ifTrue: [ ^ self ]
		]
	]
]

{ #category : #rendering }
WDSSceneRenderer >> setupStateTracker [
	stateTracker
		reset;
		mode: self renderMode;
		shaderSignature: self shaderSignature;
		useShaderResources: self shaderSignature defaultSamplers;
		
		frontFaceWinding: AGPU_COUNTER_CLOCKWISE;
		cullMode: AGPU_CULL_MODE_BACK;
		depthEnabled: true;
		depthWriteMask: true;
		depthFunction: AGPU_GREATER_EQUAL;

		blendingAllMode: WDCBlendingMode replace.

]

{ #category : #rendering }
WDSSceneRenderer >> setupViewportRendering: viewport index: viewportIndex [
	stateTracker 
		mode: self renderMode;
		submode: viewport submode.
	stateTracker
		useShaderResources: (currentCameraStates at: viewportIndex)
]

{ #category : #accessing }
WDSSceneRenderer >> shaderSignature [
	^ shaderSignature ifNil: [ shaderSignature := self shaderSignatureClass for: engine ]
]

{ #category : #accessing }
WDSSceneRenderer >> shaderSignatureClass [
	self subclassResponsibility
]

{ #category : #'rendering preparations' }
WDSSceneRenderer >> sortObjects: objectList perViewports: viewports [
	| viewport forwardDirection translucentSortedPriority |
	translucentSortedPriority := WDSGNode renderPriorityTranslucentSorted.
	
	objectList doWithIndex: [ :objects :index |
		viewport := viewports at: index.
		forwardDirection := viewport camera renderTransform matrix thirdColumn negated.
		objects sort: [ :a :b |
			a renderPriority = b renderPriority ifFalse: [
				a renderPriority < b renderPriority
			] ifTrue: [
				a renderPriority >= translucentSortedPriority ifTrue: [ 
					(forwardDirection dot: a renderTransform translation) > (forwardDirection dot: b renderTransform translation)
				] ifFalse: [ false ]
			]
		]
	].

]

{ #category : #accessing }
WDSSceneRenderer >> stateTracker [
	^ stateTracker ifNil: [ stateTracker := WDCStateTracker for: engine ].
]

{ #category : #'rendering preparations' }
WDSSceneRenderer >> submitCurrentCameraStates [
	| cameraState gpuCameraState |
	currentCameraViewports doWithIndex: [ :viewport :index |
		cameraState := viewport cameraState.
		cameraState
			transform: viewport cameraTransform;
			currentTime: currentTime.
				
		gpuCameraState := (currentCameraStates at: index) slotValueAt: 0.
		gpuCameraState atomicSetValue: cameraState.
	].

]

{ #category : #'rendering preparations' }
WDSSceneRenderer >> tryToCollectLightSource: lightSource for: camera [
	"Nothing required here."
]

{ #category : #'rendering preparations' }
WDSSceneRenderer >> updateFrameCameraStates: viewports [
	self ensureCameraStatesFor: viewports size.
	currentCameraStates := useLateLatching
		ifTrue: [ cameraStates first ]
		ifFalse: [ cameraStates at: engine bufferingFrameIndex ].
	currentCameraViewports := viewports.
	self submitCurrentCameraStates
]

{ #category : #'rendering preparations' }
WDSSceneRenderer >> updateRenderingStatesFor: viewports [
	self
		updateFrameCameraStates: viewports
]

{ #category : #accessing }
WDSSceneRenderer >> useLateLatching [
	^ useLateLatching
]

{ #category : #accessing }
WDSSceneRenderer >> useLateLatching: anObject [
	useLateLatching := anObject
]
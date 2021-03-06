Class {
	#name : #WDSLightedSceneRenderer,
	#superclass : #WDSSceneRenderer,
	#instVars : [
		'shadowCastingLights',
		'shadowCastingLightCount',
		'shadowMapBuffer',
		'shadowMapRenderTargets',
		'shadowSceneRenderer',
		'usedLights',
		'debugRenderMesh',
		'debugRenderShadowMapViewport',
		'intermediateRenderTarget',
		'debugRenderTargetIndex',
		'activeDebugRenderingViewport'
	],
	#classVars : [
		'RenderTargetDebugDrawingMethod',
		'RenderTargetIndex_AmbientOcclusion',
		'RenderTargetIndex_Count',
		'RenderTargetIndex_DepthBuffer',
		'RenderTargetIndex_None',
		'RenderTargetIndex_ShadowMap'
	],
	#category : #'WodenEngine-Scene-Rendering'
}

{ #category : #'class initialization' }
WDSLightedSceneRenderer class >> initialize [
	RenderTargetIndex_None := 0.
	RenderTargetIndex_ShadowMap := 1.
	RenderTargetIndex_AmbientOcclusion := 2.
	RenderTargetIndex_DepthBuffer := 3.
	RenderTargetIndex_Count := 3.
	
	RenderTargetDebugDrawingMethod := Dictionary newFromPairs: {
		RenderTargetIndex_ShadowMap . #debugDrawShadowMapsOnBabylonCanvas:.
		RenderTargetIndex_DepthBuffer . #debugDrawDepthBufferOnBabylonCanvas:.
		RenderTargetIndex_AmbientOcclusion . #debugDrawAmbientOcclusionOnBabylonCanvas:.
	}
]

{ #category : #accessing }
WDSLightedSceneRenderer class >> maxShadowCastingLightCount [
	^ 4
]

{ #category : #'shadow mapping' }
WDSLightedSceneRenderer class >> shadowMapExtent [
	^ 512 @ 512
]

{ #category : #'debug rendering' }
WDSLightedSceneRenderer >> applyDebugRenderShadowMapViewport [
	| shadowLight cameraState gpuCameraState |
	(debugRenderShadowMapViewport between: 1 and: shadowCastingLightCount) ifFalse: [ ^ self ].

	shadowLight := (shadowCastingLights at: debugRenderShadowMapViewport) first.

	cameraState := renderingViewports first viewport cameraState copy.
	cameraState
		transform: shadowLight renderTransform;
		projectionMatrix: shadowLight shadowProjectionMatrix.
			
	gpuCameraState := renderingViewports first cameraStateShaderBindings slotValueAt: 0.
	gpuCameraState atomicSetValue: cameraState.
]

{ #category : #'ambient occlusion' }
WDSLightedSceneRenderer >> computeScreenSpaceAmbientOcclusionFor: renderingViewport [
	| aoShaderShaderSignature |
	aoShaderShaderSignature := WDCAmbientOcclusionShaderSignature for: engine.
	
	stateTracker 
		"Ambient occlusion main compuation."
		shaderSignature: aoShaderShaderSignature;
		useShaderResources: aoShaderShaderSignature defaultSamplers;
		useShaderResources: renderingViewport cameraStateShaderBindings;
		applyFullScreenPass: renderingViewport ambientOcclusionComputationArguments;
		
		"Horizontal blur pass"
		applyFullScreenPass: renderingViewport ambientOcclusionHorizontalBlurArguments;
		
		"Vertical blur pass"
		applyFullScreenPass: renderingViewport ambientOcclusionVerticalBlurArguments.

]

{ #category : #'debug rendering' }
WDSLightedSceneRenderer >> debugDrawAmbientOcclusionOnBabylonCanvas: canvas [
	| builder description |
	
	builder := canvas driver mesh2DBuilder.
	description := activeDebugRenderingViewport ambientOcclusionTexture description.
	builder fill
		grayTexture: activeDebugRenderingViewport ambientOcclusionTexture rectangle: (0@0 extent: 
	description width @ description height).
	
	^ builder mesh

]

{ #category : #'debug rendering' }
WDSLightedSceneRenderer >> debugDrawDepthBufferOnBabylonCanvas: canvas [
	^ nil
]

{ #category : #'debug rendering' }
WDSLightedSceneRenderer >> debugDrawOnBabylonCanvas: canvas [
	self
		drawDebugRenderTargetOnBabylonCanvas: canvas
]

{ #category : #'debug rendering' }
WDSLightedSceneRenderer >> debugDrawShadowMapsOnBabylonCanvas: canvas [
	| builder column row |
	shadowCastingLightCount = 0 ifTrue: [ ^  nil ].
	
	builder := canvas driver mesh2DBuilder.
	0 to: shadowCastingLightCount - 1 do: [ :i |
		column := i % 2.
		row := i // 2.
			
		builder fill
			grayTextureArray: shadowMapBuffer element: i rectangle: ((column*256)@(row*256) extent: 256@256).
	].

	^ builder mesh

]

{ #category : #'debug rendering' }
WDSLightedSceneRenderer >> debugNextRenderTarget [
	debugRenderTargetIndex := (debugRenderTargetIndex + 1) % RenderTargetIndex_Count.
	debugRenderMesh := nil.
]

{ #category : #'debug rendering' }
WDSLightedSceneRenderer >> debugRenderNextShadowMapViewport [
	shadowCastingLightCount ifNotNil: [ 
		debugRenderShadowMapViewport := (debugRenderShadowMapViewport + 1) % (shadowCastingLightCount + 1)
	]

]

{ #category : #testing }
WDSLightedSceneRenderer >> depthStencilFormat [
	^ self isStencilRequired
		ifTrue: [ engine preferredDepthStencilFormat ]
		ifFalse: [ engine preferredDepthFormat ]
]

{ #category : #'debug rendering' }
WDSLightedSceneRenderer >> drawDebugRenderTargetOnBabylonCanvas: canvas [
	| selector |
	selector := RenderTargetDebugDrawingMethod at: debugRenderTargetIndex ifAbsent: [ ^ nil ].
	debugRenderMesh := self perform: selector with: canvas.
	debugRenderMesh ifNotNil: [ canvas draw: debugRenderMesh ]
]

{ #category : #'rendering preparations' }
WDSLightedSceneRenderer >> endPreparingRendering [
	super endPreparingRendering.
	self prepareShadowMapRendering
]

{ #category : #rendering }
WDSLightedSceneRenderer >> gbufferRenderMode [
	^ WDCStateTrackerDepthNormalRenderMode uniqueInstance
]

{ #category : #initialization }
WDSLightedSceneRenderer >> initialize [
	super initialize.
	debugRenderTargetIndex := RenderTargetIndex_None.
	debugRenderShadowMapViewport := 0.
]

{ #category : #testing }
WDSLightedSceneRenderer >> isStencilRequired [
	^ false
]

{ #category : #'shadow mapping' }
WDSLightedSceneRenderer >> maxShadowCastingLightCount [
	^ self class maxShadowCastingLightCount
]

{ #category : #'rendering preparations' }
WDSLightedSceneRenderer >> prepareLightSource: lightSource forViewportCamera: viewportCamera [
	| shadowMapIndex lightRenderingState |
	shadowMapIndex := -1.
	(engine shadowMappingEnabled and:
	 [lightSource isShadowCasting and:
	 [ shadowCastingLightCount + lightSource shadowLayerCount <= shadowCastingLights size ]]) ifTrue: [
		shadowMapIndex := shadowCastingLightCount
	].

	lightRenderingState := lightSource setupRenderingWithShadowMap: shadowMapIndex mainCamera: viewportCamera engine: engine.
	shadowMapIndex >= 0 ifTrue: [
		lightRenderingState cascades do: [ :cascade | 
			shadowCastingLightCount := shadowCastingLightCount + 1.
			shadowCastingLights at: shadowCastingLightCount put: {cascade. viewportCamera}
		]
	].

	^ lightRenderingState
]

{ #category : #'shadow mapping' }
WDSLightedSceneRenderer >> prepareShadowMapRendering [
	
	| viewports shadowCastingLightAndViewer |
	shadowCastingLightCount = 0 ifTrue: [ ^ self ].
	
	viewports := (1 to: shadowCastingLightCount) collect: [ :i |
		shadowCastingLightAndViewer := shadowCastingLights at: i.
		shadowCastingLightAndViewer first viewportForShadowMap: (shadowMapRenderTargets at: i) camera: shadowCastingLightAndViewer second
	].
	
	self shadowSceneRenderer
		currentTime: currentTime;
		beginPreparingRendering;
		prepareRenderingForViewports: viewports;
		endPreparingRendering.
]

{ #category : #'shadow mapping' }
WDSLightedSceneRenderer >> renderShadowMaps [
	shadowCastingLightCount = 0 ifTrue: [ ^ self ].

	self shadowSceneRenderer
		renderSceneViewportsIntoStateTracker: stateTracker
]

{ #category : #rendering }
WDSLightedSceneRenderer >> renderViewport: renderingViewport index: viewportIndex [
	| resolveTarget viewport |
	activeDebugRenderingViewport := renderingViewport.
	viewport := renderingViewport viewport.
	resolveTarget := viewport resolveRenderTarget.

	"First pass: g-buffer rendering. Normal and depth-only rendering."
	self setupStateTrackerForRenderMode: self gbufferRenderMode.
	stateTracker
		beginRenderPass: renderingViewport validGBufferRenderPass renderTarget: renderingViewport gbufferRenderTarget bounds: viewport bounds.
	self
		setupRenderingViewportStates: renderingViewport;
		renderViewportVisibleObjects: renderingViewport.
	stateTracker endRenderPass.
	
	engine ssaoEnabled ifTrue: [ 
		self computeScreenSpaceAmbientOcclusionFor: renderingViewport.
	].

	"Second pass: main scene rendering"
	self setupStateTracker.
	stateTracker
		beginRenderPass: renderingViewport validSceneRenderPass renderTarget: renderingViewport sceneRenderTarget bounds: viewport bounds.
	self
		setupRenderingViewportStates: renderingViewport;
		renderViewportVisibleObjects: renderingViewport.
	
	"Render the overlays"
	viewport overlayRenderer ifNotNil: [ 
		viewport overlayRenderer renderViewport: viewport overlayWith: stateTracker 
	].
	
	"End rendering into the viewport"
	stateTracker endRenderPass.
		
	"Resolve the target"
	renderingViewport sceneRenderTarget ~~ resolveTarget ifTrue: [
		stateTracker resolveRenderTarget: renderingViewport sceneRenderTarget into: resolveTarget
	]

]

{ #category : #rendering }
WDSLightedSceneRenderer >> renderViewports: viewports composeWith: aBlock [
	shadowCastingLightCount ~= 0 ifTrue: [ self renderShadowMaps ].
	
	^ super renderViewports: viewports composeWith: aBlock
]

{ #category : #abstract }
WDSLightedSceneRenderer >> sceneRendererViewportClass [
	^ WDSLightedSceneRendererViewport
]

{ #category : #accessing }
WDSLightedSceneRenderer >> shaderSignatureClass [
	^ WDCSceneRenderingShaderSignature
]

{ #category : #'shadow mapping' }
WDSLightedSceneRenderer >> shadowMapBuffer [
	| shadowMapExtent description shadowMapFormat view subresourceRange |
	shadowMapBuffer ifNotNil: [ ^ shadowMapBuffer ].
	shadowMapExtent := self shadowMapExtent.
	
	shadowMapFormat := engine preferredDepthFormat.
	description := AGPUTextureDescription new
		type: AGPU_TEXTURE_2D;
		format: shadowMapFormat;
		width: shadowMapExtent x;
		height: shadowMapExtent y;
		depthOrArraySize: self maxShadowCastingLightCount;
		miplevels: 1;
		sample_count: 1;
		sample_quality: 0;
		flags: AGPU_TEXTURE_FLAG_RENDERBUFFER_ONLY | AGPU_TEXTURE_FLAG_DEPTH |AGPU_TEXTURE_FLAG_RENDER_TARGET;
		yourself.
		
	shadowMapBuffer := (WDCTexture for: engine)
			description: description;
			checkSession;
			yourself.

	view := shadowMapBuffer fullTextureView.
	
	subresourceRange := view subresource_range.
	subresourceRange layer_count: 1.
	
	shadowMapRenderTargets := (1 to: self maxShadowCastingLightCount) collect: [ :i |
		subresourceRange base_arraylayer: i - 1.
		(WDCRenderTarget for: engine extent: shadowMapExtent)
			colorAttachmentFormats: #();
			depthStencilFormat: shadowMapFormat;
			hasDepth: true;
			createFramebuffersWithColorAttachments: #() views: #() depthStencilAttachment: shadowMapBuffer view: view;
			yourself
	].
	
	^ shadowMapBuffer
]

{ #category : #'shadow mapping' }
WDSLightedSceneRenderer >> shadowMapExtent [
	^ self class shadowMapExtent
]

{ #category : #'shadow mapping' }
WDSLightedSceneRenderer >> shadowRenderModeName [
	^ #shadow
]

{ #category : #accessing }
WDSLightedSceneRenderer >> shadowSceneRenderer [
	^ shadowSceneRenderer ifNil: [shadowSceneRenderer := WDSShadowSceneRenderer for: engine].

]

{ #category : #'rendering preparations' }
WDSLightedSceneRenderer >> sortAndPrepareLights [
	| lightRenderingStates viewportCamera lightSource recyclatedStates |
	renderingViewports do: #sortAndSelectLights.
	shadowCastingLights := Array new: self maxShadowCastingLightCount.
	shadowCastingLightCount := 0.
	perCameraRenderingViewports do: [ :perCameraViewports | 
		"This camera represents the head."
		viewportCamera := perCameraViewports camera.
		recyclatedStates := IdentityDictionary new.
		
		"These viewports represent the different eyes of the camera."
		perCameraViewports renderingViewports do: [ :renderingViewport | 
			lightRenderingStates := renderingViewport selectedLights collect: [ :lightSourceAndDistance | 
				lightSource := lightSourceAndDistance first.
				recyclatedStates at: lightSource ifAbsentPut: [
					self prepareLightSource: lightSource forViewportCamera: viewportCamera
				]
			].
			
			renderingViewport lightRenderingStates: lightRenderingStates
		]
	]
]

{ #category : #rendering }
WDSLightedSceneRenderer >> submitCurrentCameraStates [
	super submitCurrentCameraStates.
	self applyDebugRenderShadowMapViewport

]

{ #category : #'rendering preparations' }
WDSLightedSceneRenderer >> updateGPUStatesForRenderingViewports [
	super updateGPUStatesForRenderingViewports.
	self sortAndPrepareLights
]

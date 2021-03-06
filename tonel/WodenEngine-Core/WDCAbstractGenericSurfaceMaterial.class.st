Class {
	#name : #WDCAbstractGenericSurfaceMaterial,
	#superclass : #WDCMaterial,
	#instVars : [
		'albedoTexture',
		'normalTexture',
		'resourceBindingsAreUpdated',
		'resourceBinding',
		'materialState',
		'stateUniformBuffer',
		'isSkinned',
		'depthNormalFragmentShader',
		'forwardFragmentShader',
		'shaderLibrary'
	],
	#classVars : [
		'VertexShaderVariantTable'
	],
	#category : #'WodenEngine-Core-Material'
}

{ #category : #'class initialization' }
WDCAbstractGenericSurfaceMaterial class >> initialize [
	super initialize.
	VertexShaderVariantTable := Dictionary newFromPairs: #(
		"skinned color tangent"
		(true true true) skinnedColorNormal_vertex
		(true true false) skinnedColor_vertex
		(true false true) skinnedNormal_vertex
		(true false false) skinned_vertex

		(false true true) colorNormal_vertex
		(false true false) color_vertex
		(false false true) normal_vertex
		(false false false) flat_vertex
	)
]

{ #category : #rendering }
WDCAbstractGenericSurfaceMaterial >> activateDepthNormalOn: stateTracker [
	self validateCache.
	stateTracker
		vertexShader: (self depthNormalVertexShaderFor: stateTracker);
		fragmentShader: self depthNormalFragmentShader.
		
	normalTexture ifNotNil: [ 
		resourceBinding ifNotNil: [ 
			stateTracker useShaderResources: resourceBinding.
		].
	].
	^ true
]

{ #category : #rendering }
WDCAbstractGenericSurfaceMaterial >> activateDepthOnlyOn: stateTracker [
	self validateCache.
	stateTracker
		vertexShader: self depthVertexShader;
		fragmentShader: nil.
	^ true
]

{ #category : #rendering }
WDCAbstractGenericSurfaceMaterial >> activateForwardOn: stateTracker [
	self validateCache.
	
	stateTracker
		vertexShader: (self vertexShaderFor: stateTracker);
		fragmentShader: self forwardFragmentShader.
	
	stateTracker submode == #solid ifTrue: [
		stateTracker fragmentShader: self solidFragmentShader
	].
	stateTracker submode == #wire ifTrue: [
		stateTracker
			materialPolygonMode: AGPU_POLYGON_MODE_LINE;
			materialCullMode: AGPU_CULL_MODE_NONE;
			fragmentShader: self wireFragmentShader
	].

	resourceBinding ifNotNil: [ 
		stateTracker useShaderResources: resourceBinding.
	].
	
	^ true
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> albedoColor [
	^ materialState albedo
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> albedoColor: aColor [
	materialState albedo: aColor asWMVector4F.
	self uploadMaterialStateData.
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> albedoTexture [
	^ albedoTexture
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> albedoTexture: anObject [
	albedoTexture := anObject.
	self invalidateCache.
]

{ #category : #'state binding' }
WDCAbstractGenericSurfaceMaterial >> bindResources [
	| signature |
	resourceBinding ifNil: [ 
		signature := WDCSceneRenderingShaderSignature for: engine.
		resourceBinding := signature newMaterialState.
	].

	stateUniformBuffer ifNil: [
		self flag: 'Use a memory pool here.'.
		stateUniformBuffer := engine createStreamingUniformBuffer: (self materialStateClass structureSize alignedTo: 256).
		self uploadMaterialStateData.
	].

	resourceBinding bind: 0 uniformBuffer: stateUniformBuffer.
	albedoTexture ifNotNil: [ resourceBinding bind: 2 texture: albedoTexture].
	normalTexture ifNotNil: [ resourceBinding bind: 3 texture: normalTexture].
	"fresnelTexture ifNotNil: [ resourceBinding bind: 4 texture: fresnelTexture]."
]

{ #category : #'as yet unclassified' }
WDCAbstractGenericSurfaceMaterial >> concretizeMaterial [
	| resourceCache |
	super concretizeMaterial.
	resourceCache := engine resourceCache.
	albedoTexture := engine resourceCache concretizeTexture: albedoTexture.
	normalTexture := engine resourceCache concretizeTexture: normalTexture.
]

{ #category : #shaders }
WDCAbstractGenericSurfaceMaterial >> depthNormalFragmentShader [
	^ depthNormalFragmentShader ifNil: [
		depthNormalFragmentShader := self shaderLibrary getFragmentStage: #depthNormal_fragment
	]

]

{ #category : #shaders }
WDCAbstractGenericSurfaceMaterial >> depthNormalVertexShaderFor: stateTracker [
	^ self depthVertexShader
]

{ #category : #shaders }
WDCAbstractGenericSurfaceMaterial >> depthVertexShader [
	^ isSkinned
			ifTrue: [ self shaderLibrary getVertexStage: #depthSkinned_vertex ]
			ifFalse: [ self shaderLibrary getVertexStage: #depth_vertex ]
]

{ #category : #rendering }
WDCAbstractGenericSurfaceMaterial >> forwardFragmentShader [
	self subclassResponsibility
]

{ #category : #initialization }
WDCAbstractGenericSurfaceMaterial >> initialize [
	materialState := self materialStateClass new
		albedo: Color white asWMVector4F;
		yourself.
	isSkinned := false.
	self invalidateCache.
]

{ #category : #'state binding' }
WDCAbstractGenericSurfaceMaterial >> invalidateCache [
	resourceBindingsAreUpdated := false.
	forwardFragmentShader := nil.
	depthNormalFragmentShader := nil.
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> isSkinned [
	^ isSkinned
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> isSkinned: anObject [
	isSkinned := anObject.
]

{ #category : #'state binding' }
WDCAbstractGenericSurfaceMaterial >> materialStateClass [
	self subclassResponsibility
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> normalTexture [
	^ normalTexture
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> normalTexture: anObject [
	normalTexture := anObject.
	self invalidateCache.

]

{ #category : #parsing }
WDCAbstractGenericSurfaceMaterial >> parse: materialFileReference data: data [
	materialState albedo: (self parse: data at: materialFileReference srgbColor: 'albedo-color' ifAbsent: [ Color white ]).
	albedoTexture := self parse: data at: materialFileReference optionalSRGBTexture: 'albedo-texture'.
	normalTexture := self parse: data at: materialFileReference optionalTexture: 'normal-texture'.
	isSkinned := data at: 'skinned' ifAbsent: [ false ].
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> resourceBinding [
	^ resourceBinding
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> resourceBinding: anObject [
	resourceBinding := anObject
]

{ #category : #rendering }
WDCAbstractGenericSurfaceMaterial >> shaderLibrary [
	self subclassResponsibility
]

{ #category : #shaders }
WDCAbstractGenericSurfaceMaterial >> solidFragmentShader [
	^ self forwardFragmentShader
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> stateUniformBuffer [
	^ stateUniformBuffer
]

{ #category : #accessing }
WDCAbstractGenericSurfaceMaterial >> stateUniformBuffer: anObject [
	stateUniformBuffer := anObject
]

{ #category : #preview }
WDCAbstractGenericSurfaceMaterial >> thumbnail [
	albedoTexture ifNotNil: [ ^ WDCResourceThumbnail type: self thumbnailType value: albedoTexture thumbnail ].
	^ WDCResourceThumbnail type: self thumbnailType value: self albedoColor asColor
]

{ #category : #preview }
WDCAbstractGenericSurfaceMaterial >> thumbnailType [
	isSkinned ifTrue: [ ^ #skinned ].
	^ #generic
]

{ #category : #'state binding' }
WDCAbstractGenericSurfaceMaterial >> uploadMaterialStateData [
	stateUniformBuffer ifNotNil: [ 
		materialState storeBytesIn: stateUniformBuffer validPointer getHandle.
	]
	
]

{ #category : #'state binding' }
WDCAbstractGenericSurfaceMaterial >> validateCache [
	resourceBindingsAreUpdated ifFalse: [ self bindResources ].
	resourceBindingsAreUpdated := true.
]

{ #category : #shaders }
WDCAbstractGenericSurfaceMaterial >> vertexShaderFor: stateTracker [
	^ shaderLibrary getVertexStage: (VertexShaderVariantTable at: { isSkinned . stateTracker hasVertexColors . stateTracker hasVertexTangents })
]

{ #category : #shaders }
WDCAbstractGenericSurfaceMaterial >> wireFragmentShader [
	^ self forwardFragmentShader
]

"
I represent the light rendering state for a light that uses cascaded shadow maps.
"
Class {
	#name : #WDSGCascadeDirectionalLightRenderingState,
	#superclass : #WDSGAbstractLightRenderingState,
	#instVars : [
		'cascades',
		'frustumDivisions'
	],
	#category : #'WodenEngine-Scene-Rendering'
}

{ #category : #accessing }
WDSGCascadeDirectionalLightRenderingState >> cascades [
	^ cascades
]

{ #category : #'shadow mapping' }
WDSGCascadeDirectionalLightRenderingState >> computeFrustumDivisions [
	"Parallel split shadow mapping split schema from GPU Gems chapter 3: 	https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch10.html
	"
	| n f lambda m uniformSplit logarithmicSplit |
	n := mainCamera nearDistance.
	f := mainCamera farDistance.
	lambda := 0.5.
	m := 3.
	^ (0 to: m) collect: [ :i |
		uniformSplit := n + ((f - n)*(i/m)).
		logarithmicSplit := n*(f/n raisedTo: (i/m) asFloat).
		(lambda*logarithmicSplit) + ((1 - lambda)*uniformSplit)
	].

]

{ #category : #'shadow mapping' }
WDSGCascadeDirectionalLightRenderingState >> setupShadowMappingTransforms [
	frustumDivisions := self computeFrustumDivisions.
	cascades := (1 to: 3) collect: [ :i |
		WDSGDirectionalLightRenderingState new
		light: light;
		mainCamera: mainCamera;
		engine: engine;
		nearDistance: (frustumDivisions at: i) farDistance: (frustumDivisions at: i + 1);
		setupShadowMapWithIndex: shadowMapIndex + i - 1;
		yourself
	]
]

{ #category : #'as yet unclassified' }
WDSGCascadeDirectionalLightRenderingState >> viewStateForCameraTransform: cameraTransform [
	| state |
	state := light viewStateForRenderingState: self cameraTransform: cameraTransform.
	state
		cascadeSplitOffsets: (WMVector4F x: frustumDivisions first y: frustumDivisions second z: frustumDivisions third w: frustumDivisions fourth);
		cascadeFrustumPlane: (WMVector4F x: 0.0 y: 0.0 z: -1.0 w: 0.0);

		shadowMapLayer: shadowMapIndex asFloat;
		shadowMapTransform: (cascades first shadowMapMatrixForCameraTransform: cameraTransform);
		shadowMapTransform2: (cascades second shadowMapMatrixForCameraTransform: cameraTransform);
		shadowMapTransform3: (cascades third shadowMapMatrixForCameraTransform: cameraTransform).
	^ state
]

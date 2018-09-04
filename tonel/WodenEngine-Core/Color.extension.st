Extension { #name : #Color }

{ #category : #'*WodenEngine-Core' }
Color >> asVisualizationColor [
	^ self
]

{ #category : #'*WodenEngine-Core' }
Color >> resultForLinearInterpolation [
	^ Color r: self red encodeSRGBComponent g: self green encodeSRGBComponent b: self blue encodeSRGBComponent alpha: self alpha
]

{ #category : #'*WodenEngine-Core' }
Color >> valueForLinearInterpolation [
	^ Color r: self red decodeSRGBComponent g: self green decodeSRGBComponent b: self blue decodeSRGBComponent alpha: self alpha
]
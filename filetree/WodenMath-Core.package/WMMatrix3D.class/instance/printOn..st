converting
printOn: aStream
	aStream nextPutAll: 'WMMatrix3D newFrom: #('; cr;
		tab; print: m11; space; print: m12; space; print: m13; cr;
		tab; print: m21; space; print: m22; space; print: m23; cr;
		tab; print: m31; space; print: m32; space; print: m33; cr;
		nextPut: $)
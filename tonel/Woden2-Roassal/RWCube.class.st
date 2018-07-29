Class {
	#name : #RWCube,
	#superclass : #RWSimpleShape,
	#category : 'Woden2-Roassal-Core'
}

{ #category : #hooks }
RWCube >> baseShapeName [
	^ (transparencyMode , #CubeShape) asSymbol
]

{ #category : #hooks }
RWCube >> buildCollisionShapeFor: element [
	| w h d |
	w := self widthFor: element.
	h := self heightFor: element.
	d := self depthFor: element.
	^ WTBoxCollisionShape halfExtent: (WMVector3F x: w *0.5 y: h*0.5 z: d*0.5).
]

{ #category : #hooks }
RWCube >> createBaseShapeNodeForView: aView [
	| engine node renderable |
	node := WTSSpatialObjectInstanceGroup new.
	node updatedPerFrame: false.
	engine := aView engine.
	
	"We create a cube of size 1, the size of the cube is then changed by a matrix transformation.
	The matrix is computed in #shapeMatrixFor:"
	renderable := (WTGenericMeshBuilder for: engine)
		material: (self wodenMaterialForView: aView);
		addCubeWithWidth: 1.0 height: 1.0 depth: 1.0;
		computeBoundingBox;
		mesh.
	self setupTransparency: node renderable: renderable.
	node renderable: renderable.
	^ node
]
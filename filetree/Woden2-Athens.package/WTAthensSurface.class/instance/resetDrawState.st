private
resetDrawState
	deferredDrawCommands removeAll.
	vertices removeAll.
	indices removeAll.
	startIndex := 0.
	baseVertex := 0.
	
	currentShapeType := nil.
	currentPipelineState := nil.
	currentTexture := nil.
	currentFont := nil.
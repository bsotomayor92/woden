event handling
onDragStartEvent: anEvent
	| element |
	toolController ifNil: [
		anEvent isLeftButtonDrag ifTrue: [
			element := self findBestElementAtGlobalCoord: anEvent position.
			element ifNil: [
				self startDragController: WTGEDragMakeSelectionBox new event: anEvent.
			] ifNotNil: [
				self startDragController: (element value view: self dragControllerFor: anEvent) event: anEvent.
			]
		].

		anEvent isRightButtonDrag ifTrue: [
			self startDragController: WTGEDragCameraTranslate new event: anEvent.
		].

		anEvent isCenterButtonDrag ifTrue: [
			self startDragController: WTGEDragCameraRotate new event: anEvent.
		].
	].

	toolController ifNotNil: [ toolController onDragStartEvent: anEvent ].
	editor captureMouse.
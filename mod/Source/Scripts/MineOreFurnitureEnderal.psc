Scriptname MineOreFurnitureEnderal extends ObjectReference  Conditional
{script for furniture which the player can use to get resources}


objectReference property lastActivateRef auto Hidden
{tracks the last triggeringRef}

bool property isRegisteredForEvents = false auto hidden
{bool to track if this is registered for events}

bool property canBeActivated = true auto hidden

idle property PickaxeExit auto

bool property playerIsLeavingFurniture = false auto hidden

Actor Property PlayerREF Auto

;===================================================================
;;EVENT BLOCK
;===================================================================
Event OnLoad()
	BlockActivation(true)

	If !PlayerREF ; Just in case
		PlayerREF = Game.GetForm(0x14) as Actor
	EndIf

	if isFurnitureInUse()
		goToState("busy")
	endif
endEvent

Event OnUnload()
	; safety measures
	If !PlayerREF ; Just in case
		PlayerREF = Game.GetForm(0x14) as Actor
	EndIf

	UnregisterForEvents()
	lastActivateRef = None
	playerIsLeavingFurniture = False
endEvent

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
 	; debug.trace(self + ": animation event received = " + asEventName)
	
	;if the animation event we've recieved is addToInventory activate our mineOreVein with
	;the furniture as the activator to tell it to pay out ore
	; Enderal AllTogether: only pay out for an ore vein this game activated (in co-op the events can arrive with none
	; set: None.Activate() spam).
	if asEventName == "AddToInventory" && lastActivateRef
		;PlayerREF.AddItem(Resource, ResourceCount)
		lastActivateRef.activate(self)
	endif	

	
	if asEventName == "IdleFurnitureExit" || asEventName == "IdlePickaxeExit" || asEventName == "IdlePickaxeFloorExit" || asEventName == "IdlePickaxeTableExit"
		UnregisterForEvents(True)
	endif
endEvent

;===================================================================
;;STATE BLOCK
;===================================================================

auto STATE normal
	event onBeginState()
		canBeActivated = true
		; debug.Trace(self + " is in state normal")
	endEvent
	
	Event OnActivate(ObjectReference akActionRef)
		if canBeActivated
			; gotoState must be before canBeActivated = False because onBeginState in "busy" resets the flag
			gotoState("busy") 
			canBeActivated = False
 			; debug.trace(self + ", normal: OnActivate by " + akActionRef)
			if akActionRef == PlayerREF && !isFurnitureInUse()
 				; debug.trace(self + ", normal: was activated by the player in state normal, furniture not in use")
				RegisterForEvents()
				Activate(akActionRef, true)
		
			elseif akActionRef == PlayerREF
 				; debug.Trace(self + ", normal: has been activated by the player while in use")
				;just activate it
				;goToState("busy")
				Activate(akActionRef, true)
 				; debug.trace(self + ", normal: NPC activation END")
			else
				;goToState("busy")
				Activate(akActionRef, true)
 				; debug.trace(self + ", normal: NPC (other) activation END")
			endif
			canBeActivated = true
		endif
	endEvent
endState

STATE busy
	; do nothing
	event onBeginState()
		canBeActivated = True
	endEvent
	
	event onActivate(objectReference akActionRef)
		If isFurnitureInUse()
			If canBeActivated
				canBeActivated = False
	 			; debug.Trace(self + ", busy: has recieved activation in busy state from " + akActionRef)
				if isRegisteredForEvents
					if lastActivateRef && akActionRef == lastActivateRef
	 					; debug.Trace(self + ", busy: is trying to kick player out of furniture")
						; PlayerREF.PlayIdle(PickaxeExit)
						; Activate(PlayerREF, true)
						playerIsLeavingFurniture = True
						goToState("reseting")
					elseif akActionRef == PlayerREF
	 					; debug.Trace(self + ", busy: player is trying to leave furniture")
						; PlayerREF.PlayIdle(PickaxeExit)
						; Activate(PlayerREF, true)
						playerIsLeavingFurniture = True
						goToState("reseting")
					endif
				elseif akActionRef == PlayerREF
					; debug.trace(self + ", busy: player is trying to leave furniture, not registered for events")
					Activate(PlayerREF, true)
				else
					; debug.trace(self + ", busy: player is trying to leave furniture, not registered for events")
					;Activate(akActivator, true)
				endif
				canBeActivated = true
			EndIf
		Else ; not in use
			If akActionRef == PlayerREF
				; debug.trace(self + ", busy: activated by the player, furniture not in use")
				RegisterForEvents()
				Activate(akActionRef, true)
			endif
		EndIf
	endEvent
endState

state reseting
	event onBeginState()
 		; debug.Trace(self + ", reseting: onBeginState START")
		if playerIsLeavingFurniture
			playerIsLeavingFurniture = false
			PlayerREF.PlayIdle(PickaxeExit)
		else
			UnregisterForEvents(True)
		endif
		;Activate(PlayerREF, true)
		
		;UnregisterForEvents()
	endEvent

	
	event onActivate(objectReference akActionRef)
		; UnregisterForEvents()
	endEvent
endState

state Depleted
	event onBeginState()
		isRegisteredForEvents = True ; Force unregister
		UnregisterForEvents()
	endEvent
	
	event onActivate(objectReference akActionRef)
; 		debug.Trace(self + ": has recieved activation in state Depleted from " + akActionRef)
	endEvent
endState

;===================================================================
;;FUNCTION BLOCK
;===================================================================

function goToDepletedState()
	goToState("Depleted")
endFunction

function RegisterForEvents()
	; centralize this
	if !isRegisteredForEvents
		isRegisteredForEvents = True
		RegisterForAnimationEvent(PlayerREF, "AddToInventory")
		RegisterForAnimationEvent(PlayerREF, "IdlePickaxeExit")
		RegisterForAnimationEvent(PlayerREF, "IdlePickaxeFloorExit")
		RegisterForAnimationEvent(PlayerREF, "IdlePickaxeTableExit")
		RegisterForAnimationEvent(PlayerREF, "IdleFurnitureExit")
	endif
endFunction

function UnregisterForEvents(Bool bNotifyLastActivateRef = False)
	; centralize this
	
	; It is perfectly safe to unregister for events you never registered for, however
	; this function is called as part of OnUnload, and if this object isn't persistent
	; then it may be deleted by the time OnUnload runs, and these function calls will
	; fail. Since RegisterForAnimationEvent persists us, we know it will be safe to
	; call Unregister if we've previously Registered, even if called as a part of
	; OnUnload
 	; debug.Trace(self + " is attempting to unregister for anim events")
	if isRegisteredForEvents
		isRegisteredForEvents = false
		UnRegisterForAnimationEvent(PlayerREF, "AddToInventory")
		UnRegisterForAnimationEvent(PlayerREF, "IdlePickaxeExit")
		UnRegisterForAnimationEvent(PlayerREF, "IdlePickaxeFloorExit")
		UnRegisterForAnimationEvent(PlayerREF, "IdlePickaxeTableExit")
		UnRegisterForAnimationEvent(PlayerREF, "IdleFurnitureExit")

		If bNotifyLastActivateRef && lastActivateRef
			(lastActivateRef as MineOreEnderal).OnFurnitureExit()
		EndIf
 		; debug.Trace(self + " should be unregistered for anim events")
	endif
	gotoState("normal")
	canBeActivated = True
endFunction

Scriptname _00E_FS_BlueprintContainerSC extends ObjectReference  

;=====================================================================================
;              							 EVENTS                   					 
;=====================================================================================

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	bDropped = (akNewContainer == None)
	
	If akNewContainer == PlayerREF && !bDone
		bDone = true
		_00E_FS_LeveledListBlueprintContainer.Revert()
		VendorItemsBanker.RemoveAddedForm(VendorItemFSBlueprintContainer)
		_00E_FS_BlueprintContainerBookOwned.SetValue(1)
		;we need the following two lines to get the Event triggered properly, gj Beth
		PlayerREF.AddItem(_00E_FS_OnContainerChangedFakeItem, 1, true)
		PlayerREF.RemoveItem(_00E_FS_OnContainerChangedFakeItem, 1, true)
	EndIf

EndEvent

Event OnRead()
	; Enderal AllTogether: Skyrim Souls / unpaused menus keep the game running while you read; wait until
	; the book is closed, as in vanilla. A second read during the wait is ignored, so nothing runs twice.
	If STR_ReadPending
		Return
	EndIf
	STR_ReadPending = True
	While UI.IsMenuOpen("Book Menu")
		Utility.WaitMenuMode(0.2)
	EndWhile
	STR_ReadPending = False
	If bDropped == False
		If !PlayerREF.IsInCombat()
			Game.DisablePlayerControls()
			Game.EnablePlayerControls()
			_00E_FS_BlueprintContainerSpell.Cast(PlayerREF)
		Else
			_00E_FS_BlueprintContainerNotInCombat.Show()
		EndIf
	EndIf
EndEvent

;=====================================================================================
;              							 PROPERTIES                  					 
;=====================================================================================

Bool bDropped
bool bDone
Book Property _00E_FS_OnContainerChangedFakeItem Auto
GlobalVariable Property _00E_FS_BlueprintContainerBookOwned Auto
Actor Property PlayerREF Auto
Spell Property _00E_FS_BlueprintContainerSpell Auto
Message Property _00E_FS_BlueprintContainerNotInCombat Auto
Keyword Property VendorItemFSBlueprintContainer Auto
FormList Property VendorItemsBanker Auto
LeveledItem Property _00E_FS_LeveledListBlueprintContainer Auto

Bool STR_ReadPending = False ; Enderal AllTogether

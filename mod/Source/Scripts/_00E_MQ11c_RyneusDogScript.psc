Scriptname _00E_MQ11c_RyneusDogScript extends ReferenceAlias  

Event OnActivate(ObjectReference akActionRef)
	; Enderal AllTogether: Skyrim Together replays this activation on the other games with the user's copy as the
	; activator; only the player who really used it may run it, or it would act on whoever is local there.
	If akActionRef != Game.GetPlayer()
		Return
	EndIf

if (MQ11c.GetCurrentStageID() == 120)
	;Game.GetPlayer().AddItem(_00E_MQ11c_RyneusTeddy, 1)
	Actor PlayerREF = Game.GetPlayer()
	MQ11cTeddyContainer.RemoveAllItems(PlayerREF, false, true)
	
	If PlayerREF.GetItemCount(_00E_MQ11c_RyneusTeddy) < 1
		PlayerREF.AddItem(_00E_MQ11c_RyneusTeddy, 1)
	EndIf
	
	_00E_NPCDogIdleWhineM.Play(Self.GetReference())
	MQ11c.SetCurrentStageID(125)
	Self.GetActorReference().SetOutfit(_00E_MQ11c_RyneusDogOutfit)
EndIf

EndEvent

Quest Property MQ11c Auto
MiscObject Property _00E_MQ11c_RyneusTeddy Auto
Sound Property _00E_NPCDogIdleWhineM Auto
Outfit Property _00E_MQ11c_RyneusDogOutfit Auto
ObjectReference Property MQ11cTeddyContainer Auto

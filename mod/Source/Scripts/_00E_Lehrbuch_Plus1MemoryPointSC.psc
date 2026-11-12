Scriptname _00E_Lehrbuch_Plus1MemoryPointSC extends activemagiceffect  

Event OnEffectStart(actor akTarget, Actor akCaster)
	; Skyrim Together mirrors this effect onto the user's copy on the other players' games, where the code
	; below would act on THAT player. Only the player who actually used it is affected.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf

	TalentPoints.Mod(1)
	Game.GetPlayer().SetActorValue("dragonsouls", TalentPoints.GetValueInt())
	
EndEvent

GlobalVariable Property TalentPoints Auto

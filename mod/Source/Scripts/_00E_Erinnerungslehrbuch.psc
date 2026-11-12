Scriptname _00E_Erinnerungslehrbuch extends activemagiceffect   


Int Property Value = 1 Auto
GlobalVariable Property Talentpoints auto


Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Skyrim Together mirrors this effect onto the user's copy on the other players' games, where the code
	; below would act on THAT player. Only the player who actually used it is affected.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf

	Talentpoints.SetValue(Talentpoints.GetValue() + Value)
	Game.GetPlayer().SetActorValue("dragonsouls", TalentPoints.GetValueInt())
	_00E_MQP03_sMemoryPointGained.Show(Value)
	
endEvent

Message Property _00E_MQP03_sMemoryPointGained Auto
_00E_NQ02_NewHorizons_Library Property NQ02 Auto
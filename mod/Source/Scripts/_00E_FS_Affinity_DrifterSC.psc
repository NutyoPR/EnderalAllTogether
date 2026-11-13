Scriptname _00E_FS_Affinity_DrifterSC extends activemagiceffect  

GlobalVariable Property _00E_FS_Theriantrophist_MaxChymikums Auto
Perk Property _00E_Affinity_AbDrifterPerk_BoostChymikumEffectiveness Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Enderal AllTogether: Skyrim Together copies this to the other games (effect on the player's copy, or a replayed
	; activation); only the player it's really for may run it, or it would act on whoever is local there.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf
	_00E_FS_Theriantrophist_MaxChymikums.SetValue(_00E_FS_Theriantrophist_MaxChymikums.GetValueInt() + 1)
	Game.GetPlayer().AddPerk(_00E_Affinity_AbDrifterPerk_BoostChymikumEffectiveness)
Endevent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	; Enderal AllTogether: Skyrim Together copies this to the other games (effect on the player's copy, or a replayed
	; activation); only the player it's really for may run it, or it would act on whoever is local there.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf
	_00E_FS_Theriantrophist_MaxChymikums.SetValue(_00E_FS_Theriantrophist_MaxChymikums.GetValueInt() - 1)
	Game.GetPlayer().RemovePerk(_00E_Affinity_AbDrifterPerk_BoostChymikumEffectiveness)
Endevent
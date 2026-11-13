Scriptname _00E_FS_Affinity_DruidSC extends activemagiceffect  

_FS_TheriantrophistControlQuest Property controlQuest Auto
Perk Property _00E_Affinity_AbDruidPerk_BoostElementalChymikumEffectiveness Auto
Explosion Property _00E_FS_Affinity_Druid_FrostnovaExp Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Enderal AllTogether: Skyrim Together copies this to the other games (effect on the player's copy, or a replayed
	; activation); only the player it's really for may run it, or it would act on whoever is local there.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf
	Game.GetPlayer().AddPerk(_00E_Affinity_AbDruidPerk_BoostElementalChymikumEffectiveness)
	controlQuest.GetAffinityControl().RegisterForDruidAffinityEvents(self)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	; Enderal AllTogether: Skyrim Together copies this to the other games (effect on the player's copy, or a replayed
	; activation); only the player it's really for may run it, or it would act on whoever is local there.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf
	Game.GetPlayer().RemovePerk(_00E_Affinity_AbDruidPerk_BoostElementalChymikumEffectiveness)
	controlQuest.GetAffinityControl().UnRegisterForDruidAffinityEvents()
EndEvent

Function OnTransformToWolf()
	self.GetTargetActor().PlaceAtMe(_00E_FS_Affinity_Druid_FrostnovaExp)
EndFunction
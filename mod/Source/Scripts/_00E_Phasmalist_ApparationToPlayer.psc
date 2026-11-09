Scriptname _00E_Phasmalist_ApparationToPlayer extends activemagiceffect  

_FS_Phasmalist_ControlQuest Property controlQuest auto
Message Property _00E_Phasmalist_Tutorial_Teleport Auto
Message Property _00E_Phasmalist_NoApparitionCurrentlySummoned Auto
GlobalVariable Property _00E_Phasmalist_TeleportTutorialShown Auto
GlobalVariable Property _00E_DisableSkillTutorials Auto
GlobalVariable Property _00E_Phasmalist_TankMode Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Skyrim Together: STR mirrors this talent onto the caster's puppet on the other client, where it would
	; toggle/teleport THAT player's apparition. Only the actual caster's apparition is affected.
	if akTarget != Game.GetForm(0x14) as Actor
		return
	endif
	If _00E_Phasmalist_TeleportTutorialShown.GetValueInt() == 0 && _00E_DisableSkillTutorials.GetValueInt() == 0
		_00E_Phasmalist_TeleportTutorialShown.SetValueInt(1)
		_00E_Phasmalist_Tutorial_Teleport.ShowAsHelpMessage("_00E_Phasmalist_Tutorial_Teleport", 5, 1, 1)
	EndIf

	If controlQuest.IsApparitionSpawned() == False || _00E_Phasmalist_TankMode.GetValue() != 0 || ! controlQuest.GetApparitionFailsafeRef()
		_00E_Phasmalist_NoApparitionCurrentlySummoned.Show()
	Else
		controlQuest.TeleportApparitionToPlayer(True)
	EndIf
EndEvent

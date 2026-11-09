Scriptname _00E_Phasmalist_ControlSummon extends activemagiceffect
; script that is attached to the magic effect that summons the apparition. Since it should be an aimed spell, this effect just checks wether the summon is legal and 
; eventually casts a spell whose explosion places a marker that really summons the apparition (_00E_Phasmalist_SummonApparitionSC)

Actor Property PlayerREF auto
_FS_Phasmalist_ControlQuest Property ControlQuest auto
Message Property _00E_Phasmalist_NoPhasmalistTrinket auto
{Message objects whose title is the message that is displayed when the player tries to summon an apparition but wears no phasmalist trinket object}
Message Property _00E_Phasmalist_CannotSummon auto
GlobalVariable Property _00E_Phasmalist_TankMode auto
Shout Property _00E_Phasmalist_A1_SummonApparationShout Auto

Spell Property spellToCastOnSuccess Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Skyrim Together: STR mirrors this talent onto the caster's puppet on the other client, where it would
	; toggle/teleport THAT player's apparition. Only the actual caster's apparition is affected.
	if akTarget != Game.GetForm(0x14) as Actor
		return
	endif
	If ControlQuest.IsApparitionChangingSummonStatus()
		; Do nothing
	ElseIf ControlQuest.IsApparitionSpawned()
		ControlQuest.UnsummonApparition()
		(PlayerREF as _00E_Game_TalentControlSC).SetTalentRecoveryTime(_00E_Phasmalist_A1_SummonApparationShout, 0)
	Else
		If ControlQuest.IsTrinketEquipped()
			If ControlQuest.IsBadApparitionLocation(PlayerREF.GetCurrentLocation()) || _00E_Phasmalist_TankMode.GetValue() != 0
				_00E_Phasmalist_CannotSummon.Show()
			Else
				spellToCastOnSuccess.Cast(PlayerREF)
			EndIf
		Else
			Debug.Notification(_00E_Phasmalist_NoPhasmalistTrinket.getName())
		EndIf
	EndIf
EndEvent

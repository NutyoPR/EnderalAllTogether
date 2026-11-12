Scriptname _00E_FS_A3_TalentBookSC extends activemagiceffect  

;=====================================================================================
;              							EVENTS                  					 
;=====================================================================================

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Skyrim Together mirrors this effect onto the user's copy on the other players' games, where the code
	; below would act on THAT player. Only the player who actually used it is affected.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf
	_00E_PlayerFunctions.GetSkillControl().ReadMemorySkillBook(sClass, iTier, talentMessage, fRecoveryTime02, fRecoveryTime03, selfRef, TaughtTalent, Word01, Word02, Word03, Perk01, Perk02, Perk03)
EndEvent

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

String Property sClass = "Rogue" Auto
{Set this to either "Rogue", "Warrior", or "Mage". It will determine which skills are required for the player to unlock.}

int Property iTier Auto
{Set this to 1, 2 or 3.}

float Property fRecoveryTime02 Auto
float Property fRecoveryTime03 Auto
{Set this to the respective Cooldown of the second or third word of a Shout.}

Shout Property TaughtTalent Auto

Potion Property selfRef Auto
{Set this to the talent tome this effect belongs to.}

WordOfPower Property Word01 Auto
WordOfPower Property Word02 Auto
WordOfPower Property Word03 Auto

Message Property talentMessage Auto 

Perk Property Perk01 Auto
Perk Property Perk02 Auto
Perk Property Perk03 Auto

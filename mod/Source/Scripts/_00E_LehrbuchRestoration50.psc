Scriptname _00E_LehrbuchRestoration50 extends activemagiceffect   

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Skyrim Together: STR mirrors this book's effect onto the reader's puppet on the other client,
	; where the skill-book code would act on THAT player. Only the actual reader learns from it.
	if akTarget != Game.GetForm(0x14) as Actor
		return
	endif
	_00E_PlayerFunctions.GetSkillControl().ReadPrimarySkillBook("Restoration", 50, _00E_LehrbuchRestorationTo50, _00E_Levelsystem_sSkillNameRestoration)
EndEvent

Potion Property _00E_LehrbuchRestorationTo50 Auto
Message Property _00E_Levelsystem_sSkillNameRestoration Auto

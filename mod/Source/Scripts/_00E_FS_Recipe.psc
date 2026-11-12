Scriptname _00E_FS_Recipe extends ObjectReference  
{Will teach the player the some of the effects of the given ingredients}

Ingredient Property ing0 = None Auto
Ingredient Property ing1 = None Auto
Ingredient Property ing2 = None Auto
Ingredient Property ing3 = None Auto
Ingredient Property ing4 = None Auto
Ingredient Property ing5 = None Auto

MagicEffect Property effect0 = None Auto
MagicEffect Property effect1 = None Auto
MagicEffect Property effect2 = None Auto
MagicEffect Property effect3 = None Auto

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
	if SKSE.GetVersion() == 0
		If ing0 != None
			ing0.LearnAllEffects()
		EndIf
		If ing1 != None
			ing1.LearnAllEffects()
		EndIf
		If ing2 != None
			ing2.LearnAllEffects()
		EndIf
		If ing3 != None
			ing3.LearnAllEffects()
		EndIf
		If ing4 != None
			ing4.LearnAllEffects()
		EndIf
		If ing5 != None
			ing5.LearnAllEffects()
		Endif
		return
	endif

	MagicEffect[] effects = new MagicEffect[4]
	effects[0] = effect0
	effects[1] = effect1
	effects[2] = effect2
	effects[3] = effect3
	If ing0 != None
		_TeachEffects(ing0, effects)
	EndIf
	If ing1 != None
		_TeachEffects(ing1, effects)
	EndIf
	If ing2 != None
		_TeachEffects(ing2, effects)
	EndIf
	If ing3 != None
		_TeachEffects(ing3, effects)
	EndIf
	If ing4 != None
		_TeachEffects(ing4, effects)
	EndIf
	If ing5 != None
		_TeachEffects(ing5, effects)
	Endif
EndEvent

Function _TeachEffects(Ingredient ing, MagicEffect[] effects)
	int i = ing.getNumEffects()
	While i > 0
		i -= 1
		if effects.Find(ing.getNthEffectMagicEffect(i)) != -1
			ing.LearnEffect(i)
		Endif
	EndWhile
EndFunction

Bool STR_ReadPending = False ; Enderal AllTogether

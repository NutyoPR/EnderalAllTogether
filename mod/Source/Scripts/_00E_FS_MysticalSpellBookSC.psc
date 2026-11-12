Scriptname _00E_FS_MysticalSpellBookSC extends ObjectReference  

;=====================================================================================
;              							EVENTS                  					 
;=====================================================================================

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)

	If akNewContainer == PlayerREF
		bIsInInventory = True
	Else
		bIsInInventory = False
	EndIf

EndEvent

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

	If bIsInInventory

		If !PlayerREF.HasPerk(requiredPerk) || PlayerREF.GetActorValue(sSchool) < 90
			_00E_FS_MysticalSpellBookMSG.Show()
		ElseIf PlayerREF.HasSpell(spellToTeach)
			_00E_FS_AlreadyKnowMysticalSpellMSG.Show()
		Else
			PlayerREF.RemoveItem(selfRef, 1)
			PlayerREF.AddSpell(spellToTeach, true)
			UISpellLearnedM.Play(PlayerREF)
			
			If _00E_MysticalSpellAchievementUnlocked.GetValueInt() == 0
				Steam.UnlockAchievement("END_MYTHICAL_SPELL_01")
				_00E_MysticalSpellAchievementUnlocked.SetValueInt(1)
			EndIf
			
		EndIf
		
	EndIf

EndEvent

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

bool bIsInInventory
String Property sSchool Auto
Perk Property requiredPerk Auto
Actor Property PlayerREF Auto
Message Property _00E_FS_MysticalSpellBookMSG Auto
Message Property _00E_FS_AlreadyKnowMysticalSpellMSG Auto
Sound Property UISpellLearnedM Auto
Book Property selfRef Auto ;needs property because the objectreference can't be obtained and removed in the inventory
Spell Property spellToTeach Auto
GlobalVariable Property _00E_MysticalSpellAchievementUnlocked Auto

Bool STR_ReadPending = False ; Enderal AllTogether

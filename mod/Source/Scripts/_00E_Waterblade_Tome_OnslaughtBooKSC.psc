Scriptname _00E_Waterblade_Tome_OnslaughtBooKSC extends activemagiceffect  

Import _00E_TalentLibrary

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Skyrim Together mirrors this effect onto the user's copy on the other players' games, where the code
	; below would act on THAT player. Only the player who actually used it is affected.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf


	if TalentPoints.GetValueInt() > 0
	
		TalentPoints.SetValueInt(TalentPoints.GetValueInt() - 1)
		PlayerREF.SetActorValue("dragonsouls", TalentPoints.GetValueInt())

		int iPlayerTalentLevel = GetPlayerTalentLevel(_00E_Class_WarriorPerk_Talent_Onslaught, _00E_Class_WarriorPerk_Talent_Onslaught2, _00E_Class_WarriorPerk_Talent_Onslaught3)

		if iPlayerTalentLevel == 0
		
			PlayerREF.AddShout(_00E_A1_Onslaught)
			PlayerREF.AddPerk(_00E_Class_WarriorPerk_Talent_Onslaught)
			Game.UnlockWord(_00E_A1_OnslaughtWord01)
			Game.TeachWord(_00E_A1_OnslaughtWord01)
			
		ElseIf iPlayerTalentLevel == 1
		
			PlayerREF.AddPerk(_00E_Class_WarriorPerk_Talent_Onslaught2)
			Game.UnlockWord(_00E_A1_OnslaughtWord02)
			Game.TeachWord(_00E_A1_OnslaughtWord02)
		
		Else
		
			PlayerREF.AddPerk(_00E_Class_WarriorPerk_Talent_Onslaught3)
			Game.UnlockWord(_00E_A1_OnslaughtWord03)
			Game.TeachWord(_00E_A1_OnslaughtWord03)
			
		EndIf
		
	Else

		
		PlayerREF.AddItem(_00E_Waterblade_Tome_OnslaughtBook, 1)
		_00E_Waterblade_Tome_OnslaughtBook_NotEnoughTalentPoints.Show()
		
	EndIf
	
EndEvent

Actor Property PlayerREF Auto

Message Property _00E_Waterblade_Tome_OnslaughtBook_NotEnoughTalentPoints Auto

Shout Property _00E_A1_Onslaught Auto

Potion Property _00E_Waterblade_Tome_OnslaughtBook Auto

GlobalVariable Property TalentPoints Auto

WordOfPower Property _00E_A1_OnslaughtWord01 Auto
WordOfPower Property _00E_A1_OnslaughtWord02 Auto
WordOfPower Property _00E_A1_OnslaughtWord03 Auto

Perk Property _00E_Class_WarriorPerk_Talent_Onslaught Auto
Perk Property _00E_Class_WarriorPerk_Talent_Onslaught2 Auto
Perk Property _00E_Class_WarriorPerk_Talent_Onslaught3 Auto
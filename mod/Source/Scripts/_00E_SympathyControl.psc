Scriptname _00E_SympathyControl extends Quest

int function _GetScriptVersion() Global
	return 1
endFunction

;=====================================================================================
;   		      						SYMPATHY            					 
;=====================================================================================

Function ModSympathyNG(Actor akSympathyActor, int iSympathyMod, bool bIsFlirt = False, bool bStringOverride = False, String sOverride = "") 

	Levelsystem_SympathyActor.ForceRefTo(akSympathyActor)

	ActorBase sympathyBase = akSympathyActor.GetActorBase()

	If sympathyBase == _00E_MC_Jespar
		SympathyJespar.Mod(iSympathyMod)
	ElseIf sympathyBase == _00E_MC_Calia
		SympathyCalia.Mod(iSympathyMod)
	ElseIf sympathyBase == _00E_CapitalCityMaelGroschenfrst
		SympathyMaelGroschenfuerst.Mod(iSympathyMod)
	ElseIf sympathyBase == _00E_SC_Dijaam
		SympathyDijaam.Mod(iSympathyMod)
	ElseIf sympathyBase == _00E_SC_Tharael
		SympathyTharael.Mod(iSympathyMod)
	ElseIf sympathyBase == _00E_MQ11c_Ryneus
		SympathyRyneus.Mod(iSympathyMod)
	ElseIf sympathyBase == _00E_MC_Yuslan
		SympathyYuslan.Mod(iSympathyMod)
	ElseIf sympathyBase == _00E_FS_NQ02_Esme
		SympathyEsme.Mod(iSympathyMod)
	EndIf
	
	If bIsFlirt 
		If sympathyBase == _00E_MC_Jespar
			JesparFlirtCounter.SetValueInt(JesparFlirtCounter.GetValueInt() + 1)
		ElseIf sympathyBase == _00E_MC_Calia
			CaliaFlirtCounter.SetValueInt(CaliaFlirtCounter.GetValueInt() + 1)
		ElseIf sympathyBase == _00E_SC_Dijaam
			DijaamFlirtCounter.SetValueInt(DijaamFlirtCounter.GetValueInt() + 1)
		ElseIf sympathyBase == _00E_SC_Tharael
			TharaelFlirtCounter.SetValueInt(TharaelFlirtCounter.GetValueInt() + 1)
		EndIf
	EndIf
	
	If ! bStringOverride || ! SKSE.GetVersion()
		ShowSympathyFeedback(akSympathyActor, iSympathyMod)
	ElseIf SKSE.GetVersion()
		; TODO: Use a vanilla message
		String sActorName = sympathyBase.GetName()
		Debug.Notification(sActorName + sOverride)
	EndIf

	; Enderal AllTogether: the partner's game shows the same "<name> approves/dislikes" (the value itself is synced)
	If EnderalAllTogether.IsLoaded()
		EnderalAllTogether.ShareSympathy(akSympathyActor, iSympathyMod)
	EndIf
	
EndFunction

; The "<name> approves/dislikes" message for a sympathy change, without changing the value. Enderal AllTogether also
; calls this on the party's games when a change was made in someone else's conversation.
Function ShowSympathyFeedback(Actor akSympathyActor, int iSympathyMod)
	Levelsystem_SympathyActor.ForceRefTo(akSympathyActor)
	If (iSympathyMod > 0) && (iSympathyMod <= 5) 
		_00E_Levelsystem_sApproves.Show()
	ElseIf (iSympathyMod > 5) && (iSympathyMod <= 10) 
		_00E_Levelsystem_sAppreciates.Show()
	ElseIf (iSympathyMod > 10) && (iSympathyMod <= 20) 
		_00E_Levelsystem_sAppreciatesALot.Show()
	ElseIf (iSympathyMod < 0) && (iSympathyMod >= -5) 
		_00E_Levelsystem_sDislikes.Show()
	ElseIf (iSympathyMod < -5) && (iSympathyMod >= -10) 
		_00E_Levelsystem_sHurt.Show()
	ElseIf (iSympathyMod < -10) && (iSympathyMod >= -20) 
		_00E_Levelsystem_sVeryHurt.Show()
	ElseIf iSympathyMod < -20
		_00E_Levelsystem_sExtremelyHurt.Show()
	EndIf
EndFunction

Function ShowFailedMessage(String companionName = "Jespar")

	if companionName == "Jespar" && _00E_DisableQuestTutorials.GetValueInt() == 0
		_00E_Tutorial_Companions02_Jespar.Show()
	ElseIf _00E_DisableQuestTutorials.GetValueInt() == 0
		_00E_Tutorial_Companions02_Calia.Show()
	EndIf
	
EndFunction


;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

ActorBase Property _00E_MC_Jespar Auto
ActorBase Property _00E_MC_Calia Auto
ActorBase Property _00E_SC_Tharael Auto
ActorBase Property _00E_SC_Dijaam Auto
ActorBase Property _00E_MQ11c_Ryneus Auto
ActorBase Property _00E_CapitalCityMaelGroschenfrst Auto
ActorBase Property _00E_MC_Yuslan Auto
ActorBase Property _00E_FS_NQ02_Esme Auto

GlobalVariable Property SympathyTharael Auto
GlobalVariable Property SympathyJespar Auto
GlobalVariable Property SympathyDijaam Auto
GlobalVariable Property SympathyMaelGroschenfuerst Auto
GlobalVariable Property SympathyCalia Auto
GlobalVariable Property SympathyYuslan Auto
GlobalVariable Property SympathyEsme Auto
GlobalVariable Property SympathyRyneus auto

GlobalVariable Property CaliaFlirtCounter Auto
GlobalVariable Property DijaamFlirtCounter Auto
GlobalVariable Property JesparFlirtCounter Auto
GlobalVariable Property TharaelFlirtCounter Auto

GlobalVariable Property _00E_DisableQuestTutorials Auto
GlobalVariable Property _00E_DisableSkillTutorials Auto

ReferenceAlias Property Levelsystem_SympathyActor Auto

Actor Property PlayerREF Auto

Message Property _00E_Tutorial_Companions02_Jespar Auto
Message Property _00E_Tutorial_Companions02_Calia Auto

Message Property _00E_Levelsystem_sApproves Auto
Message Property _00E_Levelsystem_sAppreciates Auto
Message Property _00E_Levelsystem_sAppreciatesALot Auto
Message Property _00E_Levelsystem_sDislikes Auto
Message Property _00E_Levelsystem_sHurt Auto
Message Property _00E_Levelsystem_sVeryHurt Auto
Message Property _00E_Levelsystem_sDoesNotTrust Auto
Message Property _00E_Levelsystem_sExtremelyHurt Auto

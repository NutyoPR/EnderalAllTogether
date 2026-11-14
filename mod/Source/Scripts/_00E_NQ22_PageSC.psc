Scriptname _00E_NQ22_PageSC extends ObjectReference  

;=====================================================================================
;              							EVENTS                  					 
;=====================================================================================

Event OnCellAttach()

	; Enderal AllTogether: a party member took this page while you were elsewhere
	If !bDone && EnderalAllTogether.IsLoaded() && EnderalAllTogether.GetSharedValue("nq22page:" + Self.GetFormID(), 0) == 1
		TakenByParty()
		Return
	EndIf

	If Self.Is3DLoaded() && Self.IsEnabled()
		Self.SetMotionType(4)
		_00E_QuestshaderNew.Play(Self)
	EndIf

EndEvent

Event OnActivate(ObjectReference akActionRef)

	; Enderal AllTogether: when another player picks the page up, Skyrim Together replays it here with them as the
	; activator. Only remove it: the count arrives through the synced NQ22_PagesFound, and the page is theirs.
	If !bDone && akActionRef != Game.GetPlayer() && (akActionRef as Actor)
		bDone = True
		Self.Disable()
		Return
	EndIf

	If !bDone
	
		bDone = True

		if NQ22.GetCurrentStageID() < 10
			NQ22.SetCurrentStageID(10)
		EndIf
		
		Game.GetPlayer().AddItem(_00E_NQ22_DiaryPages.GetAt(iPageIndex - 1) as Book, 1)
		
		UpdatePageCount()
		
		Self.Disable()
		If EnderalAllTogether.IsLoaded()
			EnderalAllTogether.ShareValue("nq22page:" + Self.GetFormID(), 1) ; Enderal AllTogether: gone for the party too
		EndIf
		
	EndIf

EndEvent

;=====================================================================================
;              							FUNCTIONS                  					 
;=====================================================================================

Function UpdatePageCount()

	NQ22_PagesFound.SetValue(NQ22_PagesFound.GetValueInt() + 1)
	NQ22.UpdateCurrentInstanceGlobal(NQ22_PagesFound)
	
	int CurrentCount = NQ22_PagesFound.GetValueInt()

	if CurrentCount >= 7
		NQ22.SetObjectiveCompleted(15, 1)
		NQ22.SetCurrentStageID(35)
	ElseIf CurrentCount < 7
		NQ22.SetObjectiveCompleted(15,0)
		NQ22.SetObjectiveDisplayed(15, True, True)
	EndIf

EndFunction

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

int Property iPageIndex Auto

bool bDone

Formlist Property _00E_NQ22_DiaryPages Auto

EffectShader Property _00E_QuestshaderNew Auto

Quest Property NQ22 Auto

GlobalVariable Property NQ22_PagesFound Auto

; Enderal AllTogether: a party member took this page (it counts through the synced NQ22_PagesFound).
Function TakenByParty()
	If !bDone
		bDone = True
		Self.Disable()
	EndIf
EndFunction

scriptName _00E_MQ11_CritterObjectSCN extends ObjectReference

Event OnInit()
	RegisterForSingleUpdate(1.5)
EndEvent

EVENT onActivate(ObjectReference akActionRef)
	; Enderal AllTogether: Skyrim Together replays this activation on the other games with the user's copy as the
	; activator; only the player who really used it may run it, or it would act on whoever is local there.
	If akActionRef != Game.GetPlayer()
		Return
	EndIf

	If PlayerRef.GetItemCount(_00E_MQ11cSchmetterlingsglas) > 0 
		PlayerRef.AddItem(_00E_MQ11cSchmetterling, 1)
		PlayerRef.RemoveItem(_00E_MQ11cSchmetterlingsglas, 1)
		_00E_MQ11c_ButterfliesGlobal.SetValue(_00E_MQ11c_ButterfliesGlobal.GetValue()+1)
		MQ11c.UpdateCurrentInstanceGlobal(_00E_MQ11c_ButterfliesGlobal)

		int CurrentCount = _00E_MQ11c_ButterfliesGlobal.GetValueInt()
		
		If CurrentCount < 7
			MQ11c.SetObjectiveCompleted(45,0)
			MQ11c.SetObjectiveDisplayed(45, true, true)
		ElseIf CurrentCount == 7
			If DoOnce == False
				DoOnce = True
				Utility.Wait(1)
				Ryneus.MoveTo(RyneusPortMarket)
				Utility.Wait(1)
				MQ11c.SetObjectiveCompleted(45)
				MQ11c.SetObjectiveDisplayed(55)
				MQ11c.SetObjectiveDisplayed(50, true, true)
				MQ11c.SetCurrentStageID(190)
			EndIf
		ElseIf CurrentCount > 7 && CurrentCount <= 14
			MQ11c.SetObjectiveCompleted(50, false)
			MQ11c.SetObjectiveDisplayed(50, true, true) 
		ElseIf CurrentCount >= 15
			MQ11c.SetObjectiveCompleted(50)
		EndIf
		
	Else
		Self.PlaceAtMe(_00E_MQ11_critterSpawnInsects_Single)
	EndIf
	
EndEvent

Event OnUpdate()

	If PlayerREF.HasMagicEffect(_00E_MQ11c_Chaosohr)
		If PlayingShader == False
			_00E_Questshader.Play(Self)
			PlayingShader = True
		Else
			Return
		EndIf
	ElseIf !(PlayerREF.HasMagicEffect(_00E_MQ11c_Chaosohr))
		_00E_Questshader.Stop(Self)
	EndIf
	
EndEvent

bool PlayingShader
GlobalVariable Property _00E_MQ11c_ButterfliesGlobal Auto
Actor Property PlayerRef Auto
MiscObject Property _00E_MQ11cSchmetterlingsglas Auto
MiscObject Property _00E_MQ11cSchmetterling Auto
Activator Property _00E_MQ11_critterSpawnInsects_Single Auto
Quest Property MQ11c Auto
bool DoOnce = false
EffectShader Property _00E_Questshader Auto
MagicEffect Property _00E_MQ11c_Chaosohr Auto
Actor Property Ryneus Auto
ObjectReference Property RyneusPortMarket Auto
Scriptname _00E_NQ03_SkullSphereSC extends ObjectReference  

Event OnActivate(ObjectReference akActionRef)
	; Enderal AllTogether: Skyrim Together replays this activation on the other games with the user's copy as the
	; activator; only the player who really used it may run it, or it would act on whoever is local there.
	If akActionRef != Game.GetPlayer()
		Return
	EndIf
	
	If NQ03.GetCurrentStageID() == 30 && !PlayerREF.IsInCombat() && !bInteracting
		bInteracting = true
		If (GameHour.GetValue() >= 20) || (GameHour.GetValue() < 5)
			
			int iButton = _00E_NQ03_MasterSkullBox.Show()
			
			if iButton == 0
				_00E_MagicRandomM.Play(PlayerREF)
				AlchArmorMagickaFXS.Play(PlayerREF)
				FadeToBlackAndBackIMOD.Apply()
				Lernpunkte.SetValueInt(Lernpunkte.GetValueInt() + 2)
				_00E_EPHandler.GiveEP(75)
				PlayerREF.AddItem(_01E_CraftingPlan_01EUNI_SchattenfingerForged, 1)
				PlayerREF.RemoveItem(_00E_MasterTeacher, 1)
				_00E_MQP03_sLearningPointGained.Show(2)
				Utility.Wait(2)
				AlchArmorMagickaFXS.Stop(PlayerREF)
				Steam.UnlockAchievement("END_MASTER_SKULL_01")
				Self.Delete()
			EndIf
		Else
			_00E_MQ07_sWaitUntilNightfall.Show()
		EndIf
		bInteracting = false
	EndIf
	
EndEvent

bool bInteracting = false

Actor Property PlayerREF Auto

_00E_NQ03_Functions Property NQ03 Auto

EffectShader Property AlchArmorMagickaFXS Auto

Sound Property _00E_MagicRandomM Auto

MiscObject Property _00E_MasterTeacher Auto
MiscObject Property _01E_CraftingPlan_01EUNI_SchattenfingerForged Auto

Message Property _00E_NQ03_MasterSkullBox Auto
Message Property _00E_MQP03_sLearningPointGained Auto
Message Property _00E_MQ07_sWaitUntilNightfall Auto

GlobalVariable Property GameHour Auto
GlobalVariable Property Lernpunkte Auto

ImageSpaceModifier Property FadeToBlackAndBackIMOD Auto
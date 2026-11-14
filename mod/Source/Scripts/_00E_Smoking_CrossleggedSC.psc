Scriptname _00E_Smoking_CrossleggedSC extends ObjectReference  

Spell Property _00E_Smoking_CrossLeggedMarkerSP auto

Event OnActivate(ObjectReference akActionRef)
	; Enderal AllTogether: when the other player sits down, Skyrim Together replays it here on their copy, which animates
	; from their own game; running the smoking script on it as well fights that and can leave it stuck.
	If !(akActionRef as Actor)
		Return
	EndIf
	If EnderalAllTogether.IsLoaded() && EnderalAllTogether.InCoop() && SkyrimTogetherUtils.IsRemotePlayer(akActionRef as Actor)
		Return
	EndIf
	(akActionRef as Actor).AddSpell(_00E_Smoking_CrossLeggedMarkerSP, False)
EndEvent


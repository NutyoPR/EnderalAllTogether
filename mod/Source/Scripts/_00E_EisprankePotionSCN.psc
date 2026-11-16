Scriptname _00E_EisprankePotionSCN extends activemagiceffect

Event OnEffectStart(Actor akTarget, Actor akCaster)

	; Enderal AllTogether: in co-op the effect also lands on your copy of the player who ate it. Only their own game
	; raises their carry weight and shows the message.
	If akTarget != Game.GetPlayer()
		Return
	EndIf

	akTarget.ModActorValue("CarryWeight", 1)

	_00E_CarryWeightEispranke.Show(akTarget.GetActorValue("CarryWeight"))

EndEvent

Message Property _00E_CarryWeightEispranke  Auto  

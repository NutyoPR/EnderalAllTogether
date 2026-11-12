Scriptname _00E_FS_NQR05_TharaelTalentBookSC extends activemagiceffect  

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; Skyrim Together mirrors this effect onto the user's copy on the other players' games, where the code
	; below would act on THAT player. Only the player who actually used it is affected.
	If akTarget != Game.GetForm(0x14) as Actor
		Return
	EndIf

	Game.GetPlayer().AddShout(_00E_FS_TharaelFireShout)
	Game.UnlockWord(_00E_FS_NQR05_TharaelWord_01)
	Game.TeachWord(_00E_FS_NQR05_TharaelWord_01)
	Game.UnlockWord(_00E_FS_NQR05_TharaelWord_02)
	Game.TeachWord(_00E_FS_NQR05_TharaelWord_02)	
	Game.UnlockWord(_00E_FS_NQR05_TharaelWord_03)
	Game.TeachWord(_00E_FS_NQR05_TharaelWord_03)
EndEvent

Shout Property _00E_FS_TharaelFireShout Auto

WordOfPower Property _00E_FS_NQR05_TharaelWord_01 Auto
WordOfPower Property _00E_FS_NQR05_TharaelWord_02 Auto
WordOfPower Property _00E_FS_NQR05_TharaelWord_03 Auto
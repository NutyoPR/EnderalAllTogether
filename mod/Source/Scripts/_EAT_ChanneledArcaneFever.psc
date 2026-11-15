Scriptname _EAT_ChanneledArcaneFever extends ActiveMagicEffect
{Enderal AllTogether: arcane fever for the channeled Second Breath.
The old spell added its fever once per cast. The beam adds it while it heals, a little every second
(the effect's magnitude is fever per second), and shows one message with the total when you let go,
like Enderal's own channeled heals. Same fever per magicka as the old cast.}

Actor Property PlayerREF Auto
Perk Property _00E_Class_Thaumaturge_P07_MentalExpert Auto
Message Property _00E_Player_sArcaneFeverIncreased Auto
Sound Property _00E_FS_IncreaseArcaneFeverM Auto

float Property fTickSeconds = 1.0 AutoReadOnly

float fPerSecond
float fPerTick
float fTotal
float fLastTick
bool bActive

Event OnEffectStart(Actor akTarget, Actor akCaster)
	; The effect sits on whoever the beam hits; only the caster's own game counts the fever.
	If akCaster != PlayerREF
		return
	EndIf

	fPerSecond = GetMagnitude()
	If PlayerREF.HasPerk(_00E_Class_Thaumaturge_P07_MentalExpert)
		fPerSecond = fPerSecond * 0.67
	EndIf
	fPerTick = fPerSecond * fTickSeconds
	fTotal = 0.0
	fLastTick = Utility.GetCurrentRealTime()
	bActive = fPerTick > 0.0
	If bActive
		RegisterForSingleUpdate(fTickSeconds)
	EndIf
EndEvent

Event OnUpdate()
	If !bActive
		return
	EndIf
	AddFever(fPerTick)
	fLastTick = Utility.GetCurrentRealTime()
	RegisterForSingleUpdate(fTickSeconds)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	If !bActive
		return
	EndIf
	bActive = false
	; The part of a second since the last tick counts too, so short bursts aren't free.
	float fPartial = Utility.GetCurrentRealTime() - fLastTick
	If fPartial > fTickSeconds
		fPartial = fTickSeconds
	EndIf
	If fPartial > 0.0
		AddFever(fPerSecond * fPartial)
	EndIf
	If fTotal > 0.0
		_00E_Player_sArcaneFeverIncreased.Show(fTotal, -PlayerREF.GetActorValue("LastFlattered"))
		_00E_FS_IncreaseArcaneFeverM.Play(PlayerREF)
	EndIf
EndEvent

Function AddFever(float afAmount)
	; Arcane fever is stored as negative LastFlattered.
	PlayerREF.ModActorValue("LastFlattered", -afAmount)
	fTotal += afAmount
EndFunction

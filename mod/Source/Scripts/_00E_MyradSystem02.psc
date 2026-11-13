Scriptname _00E_MyradSystem02 extends Quest

import UIExtensions
import Utility

Actor akCurrentMyrad

Function CallMyradFlight(Actor akMyrad = None)
	akCurrentMyrad = akMyrad
	
	; If we call Message.Show() in a Goodbye script, dialogue menu will stay on screen
	; Registering for an update, we allow it to close before the location menu
	RegisterForSingleUpdate(0.1)
EndFunction

event OnUpdate()
	if SKSE.GetVersion()
		CallLocationList()
	else
		CallLocationListVanilla()
	endif
endevent

Function CallLocationList()
	
	UIListMenu listmenu = GetMenu("UIListMenu") as UIListMenu

	string[] MyradTravelList = new string[13]
	MyradTravelList[0] = "$Myradtravel00"
	MyradTravelList[1] = "$Myradtravel01"
	MyradTravelList[2] = "$Myradtravel02"
	MyradTravelList[3] = "$Myradtravel03"
	MyradTravelList[4] = "$Myradtravel04"
	MyradTravelList[5] = "$Myradtravel05"
	MyradTravelList[6] = "$Myradtravel06"
	MyradTravelList[7] = "$Myradtravel07"
	MyradTravelList[8] = "$Myradtravel08"
	MyradTravelList[9] = "$Myradtravel09"
	MyradTravelList[10] = "$Myradtravel10"
	MyradTravelList[11] = "$Myradtravel11"
	MyradTravelList[12] = "$Back"
		
	Int iLength = 0
	
	While iLength < MyradTravelList.length
		listmenu.AddEntryItem(MyradTravelList[iLength], -1, -1, false)
		iLength += 1
	EndWhile
	
	int iListMenu = listmenu.OpenMenu()
	int iListButton = listmenu.GetResultInt()
	
	If iListButton == 0	
		PortPlayer(ArkDestination)
	ElseIf iListButton == 1
		PortPlayer(ArkDestinationOutside)
	ElseIf iListButton == 2
		PortPlayer(RiverhomeDestination)
	Elseif iListButton == 3
		PortPlayer(HeartlandBorderregionDestination)
	Elseif iListButton == 4
		PortPlayer(HeartlandWatchtowerDestination)
	Elseif iListButton == 5
		PortPlayer(HeartlandNordicDestination)
	Elseif iListButton == 6
		PortPlayer(FarmerscoastDestination)
	ElseIf iListButton == 7
		PortPlayer(FrostcliffDestination)
	ElseIf iListButton == 8
		PortPlayer(DunehomeDestination)
	Elseif iListButton == 09
		PortPlayer(QuellwachtDestination)
	Elseif iListButton == 10
		PortPlayer(MisthomeDestination)
	Elseif iListButton == 11
		PortPlayer(DuestertalDesitnation)
	Elseif iListButton == 12
		return
	EndIf

EndFunction

Function CallLocationListVanilla()
	
	int iListButton = _00E_MyradFlightPage1.Show()
	
	If iListButton == 0	
		PortPlayer(ArkDestination)
	ElseIf iListButton == 1
		PortPlayer(ArkDestinationOutside)
	ElseIf iListButton == 2
		PortPlayer(RiverhomeDestination)
	Elseif iListButton == 3
		PortPlayer(HeartlandBorderregionDestination)
	Elseif iListButton == 4
		PortPlayer(HeartlandWatchtowerDestination)
	Elseif iListButton == 5
		PortPlayer(HeartlandNordicDestination)
	Elseif iListButton == 6
		PortPlayer(FarmerscoastDestination)
	elseif iListButton == 8 ; Exit
		return
	else ; More
	
		int iListButton2 = _00E_MyradFlightPage2.Show()
	
		If iListButton2 == 0
			PortPlayer(FrostcliffDestination)
		ElseIf iListButton2 == 1
			PortPlayer(DunehomeDestination)
		Elseif iListButton2 == 2
			PortPlayer(QuellwachtDestination)
		Elseif iListButton2 == 3
			PortPlayer(MisthomeDestination)
		Elseif iListButton2 == 4
			PortPlayer(DuestertalDesitnation)
		Elseif iListButton2 == 6 ; Exit
			return
		else ; Return
			CallLocationListVanilla()
		endif
	
	endif
	
endfunction

Function CallFlightAnimation(Actor akMyrad)

	FadeToBlackAndBackQuick.Apply()
	
	_00E_EquipControl.SheatheWeapon(PlayerREF as Actor)
	Wait(0.75)
	
	ObjectReference objTakeOffMarker = akMyrad.GetLinkedRef(_00E_FS_MyradTakeOffMarker)
	akMyrad.MoveTo(objTakeOffMarker)
	akMyrad.SetScale(1)
	_FS_TheriantrophistControlQuest.TransformBackIfTransformed()
	akMyrad.PlayIdleWithTarget(groundMountDragon, PlayerREF)
	Wait(4.0)
	akMyrad.PlayImpactEffect(FXDragonTakeoffImpactSet, "NPC Tail8", 0, 0, -1, 512, true, false)
	Wait(8.0)
	
EndFunction

Function ResetMyradAndPlayer(Actor akMyrad)

	Debug.SendAnimationEvent(PlayerREF, "IdleCartExitInstant")
	akMyrad.Disable()
	akMyrad.Enable()
	akMyrad.MoveTo(akMyrad.GetLinkedRef())
	akMyrad.EvaluatePackage()

EndFunction

Function PortPlayer(ObjectReference Destination)

	PlayerRef.RemoveItem(Gold001, MyradTripPrice.GetValue() as int)
	
	; Enderal AllTogether: the flight moves and animates the Myrad, which only the leader's game controls; on the others
	; it would fight the leader's game over the Myrad. Party members get the fade and the trip without the flight.
	Bool bFlight = akCurrentMyrad != None && (!EnderalAllTogether.IsLoaded() || EnderalAllTogether.IsDesignatedPlayer())
	if bFlight
		CallFlightAnimation(akCurrentMyrad)
	endif
	
	FadeToBlackImod.Apply()
	Game.SetHudCartMode(true)
	Wait(1)
	FadeToBlackHoldImod.ApplyCrossFade()
	Wait(0.5)
	PlayerRef.MoveTo(Destination)
	Wait(0.5)
	
	if bFlight
		ResetMyradAndPlayer(akCurrentMyrad)
	endif
	
	FadeToBlackBackImod.ApplyCrossFade()
	Game.SetHudCartMode(false)
	
	If MQ04.GetCurrentStageID() >= 10 && !bDone
		bDone = True
		MQ04.SetObjectiveCompleted(20)
		_00E_EPHandler.GiveEP(150)
	EndIf
	
	MyradFligthCounter += 1
	
	If MyradFligthCounter == 20
		Steam.UnlockAchievement("END_MYRAD_01")
	EndIf
	
	_FS_Phasmalist_ControlQuest.MoveApparitionToPlayer()
	If EnderalAllTogether.IsLoaded()
		EnderalAllTogether.ShareTravel(Destination) ; Enderal AllTogether: the party arrives with you
	EndIf
	
	Game.RequestAutoSave()
	
EndFunction

bool bDone
int MyradFligthCounter = 0

Quest Property MQ04 Auto

Keyword Property _00E_FS_MyradTakeOffMarker Auto

Message Property _00E_MyradFlightPage1 Auto
Message Property _00E_MyradFlightPage2 Auto
ObjectReference Property PlayerRef Auto
MiscObject Property Gold001 Auto
GlobalVariable Property MyradTripPrice Auto

Idle Property groundMountDragon Auto
ImpactDataSet Property FXDragonTakeoffImpactSet Auto

ObjectReference Property ArkDestination Auto
ObjectReference Property ArkDestinationOutside Auto
ObjectReference Property RiverhomeDestination Auto
ObjectReference Property HeartlandBorderregionDestination Auto
ObjectReference Property HeartlandWatchtowerDestination Auto
ObjectReference Property HeartlandNordicDestination Auto
ObjectReference Property FarmerscoastDestination Auto
ObjectReference Property FrostcliffDestination Auto
ObjectReference Property DunehomeDestination Auto
ObjectReference Property QuellwachtDestination Auto
ObjectReference Property MisthomeDestination Auto
ObjectReference Property DuestertalDesitnation Auto

ImageSpaceModifier Property FadeToBlackImod Auto
ImageSpaceModifier Property FadeToBlackHoldImod Auto
ImageSpaceModifier Property FadeToBlackBackImod Auto
ImageSpaceModifier Property FadeToBlackAndBackQuick Auto
Scriptname _00e_Ark_TravelCrossroadsSC extends ObjectReference  

import UIExtensions

;=====================================================================================
;										EVENTS							  
;=====================================================================================

Event OnActivate(ObjectReference akActionRef)

	if akActionRef == PlayerREF
		if MQ14.GetCurrentStageID() < 20 && MQ03.GetCurrentStageID() > 0 && !(MQ12b.GetCurrentStageID() >= 15 && MQ12c.GetCurrentStageID() < 5) && (_00E_TeleportGlobal.GetValueInt() == 0)
			if SKSE.GetVersion()
				ShowTravelMenu()
			else
				ShowTravelMenuVanilla()
			endif
		Elseif MQ12b.GetCurrentStageID() == 10 && SKSE.GetVersion()
			ShowMQ12bTravelMenu()
		Else
			_00E_FastTravel_Ark_CantTravelRightNow.Show()
		EndIf
	EndIf
	
EndEvent

;=====================================================================================
;										FUNCTIONS									   
;=====================================================================================

Function ShowTravelMenu()

	;setting up the menu, UIExtensions need to be imported first, see line 3
	UIListMenu listmenu = GetMenu("UIListMenu") as UIListMenu
	
	;setting up the strings, pulling them from the translate.txt to simplify the localization process
	string[] FastTravelList = new string[14]
	FastTravelList[0] = "$Fasttravel00"
	FastTravelList[1] = "$Fasttravel01"
	FastTravelList[2] = "$Fasttravel02"
	FastTravelList[3] = "$Fasttravel03"
	FastTravelList[4] = "$Fasttravel04"
	FastTravelList[5] = "$Fasttravel05"
	FastTravelList[6] = "$Fasttravel06"
	FastTravelList[7] = "$Fasttravel07"
	FastTravelList[8] = "$Fasttravel08"
	FastTravelList[9] = "$Fasttravel09"
	FastTravelList[10] = "$Fasttravel10"
	FastTravelList[11] = "$Fasttravel11"
	FastTravelList[12] = "$Fasttravel12"
	FastTravelList[13] = "$Back"
	
	;adding the strings to the list menu via a while loop
	Int iLength = 0	
	
	While iLength < FastTravelList.length
		listmenu.AddEntryItem(FastTravelList[iLength], -1, -1, false)
		iLength += 1
	EndWhile
	
	;setting up the different options from which the player can choose. It's working similar to messagebox options, besides these two lines right here:
	int iListMenu = listmenu.OpenMenu()
	int iListButton = listmenu.GetResultInt()
	If iListButton == 0	
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_Entrance)
	ElseIf iListButton == 1
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_StrangerQuarter)
	ElseIf iListButton == 2
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_Marketplace)
	Elseif iListButton == 3
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_SouthQuarter)
	Elseif iListButton == 4
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_NoblesQuarter)
	Elseif iListButton == 5
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_Harbour)
	Elseif iListButton == 6
		If MQ03.IsCompleted()
			STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_Suntemple)	
		Else
			_00E_FastTravel_Ark_NoTemple.Show()
		EndIf
	ElseIf iListButton == 7
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_Graveyard)
	ElseIf iListButton == 8
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_UndercityEntrance)
	Elseif iListButton == 09
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_UndercityBarracks)
	Elseif iListButton == 10
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_UndercityMarketplace)
	Elseif iListButton == 11
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_UndercityTarpit)
	Elseif iListButton == 12
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_UndercityArena)
	Elseif iListButton == 13
		return
	EndIf

	If !((iListButton == 5 || iListButton == 6) || (iListButton == 4 || iListButton == 5))
		If MQ04.GetCurrentStageID() > 5 && !(MQ04.IsCompleted()) && !(MQ04.IsObjectiveCompleted(25))
			_00E_EPHandler.GiveEP(100)
			MQ04.SetObjectiveCompleted(25)
		EndIf
	EndIf
	
EndFunction

Function ShowMQ12bTravelMenu()

	UIListMenu listmenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu
		
	string[] FastTravelList = new string[2]
	FastTravelList[0] = "$Fasttravel04"
	FastTravelList[1] = "$Quit"
	Int iLength = 0	
	
	While iLength < FastTravelList.length
		listmenu.AddEntryItem(FastTravelList[iLength], -1, -1, false)
		iLength += 1
	EndWhile

	int iListMenu = listmenu.OpenMenu()
	int iListButton = listmenu.GetResultInt()
	If iListButton == 0	
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_NoblesQuarter)
	ElseIf iListButton == 1
		return
	EndIf

EndFunction

function ShowTravelMenuVanilla()
	
	int iListButton = _00E_FastTravel_Ark_SelectionMenu_01.Show()
	
	if iListButton == 0
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_Entrance)
	ElseIf iListButton == 1
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_StrangerQuarter)
	ElseIf iListButton == 2
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_Marketplace)
	Elseif iListButton == 3
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_SouthQuarter)
	Elseif iListButton == 4
		STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_NoblesQuarter)
	elseif iListButton == 6 ; Exit
		return
	elseif iListButton == 5 ; More
		
		int iListButton2 = _00E_FastTravel_Ark_SelectionMenu_02.Show()

		if iListButton2 == 0
			STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_Harbour)
		ElseIf iListButton2 == 1
			STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_Graveyard)
		Elseif iListButton2 == 2
			If MQ03.IsCompleted()
				STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_Suntemple)	
			Else
				_00E_FastTravel_Ark_NoTemple.Show()
			EndIf
		elseif iListButton2 == 3
			STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_UndercityEntrance)
		elseif iListButton2 == 5 ; Exit
			return
		elseif iListButton2 == 4 ; More
		
			int iListButton3 = _00E_FastTravel_Ark_SelectionMenu_03.Show()
		
			if iListButton3 == 0
				STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_UndercityBarracks)
			ElseIf iListButton3 == 1
				STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_UndercityMarketplace)
			ElseIf iListButton3 == 2
				STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_UndercityTarpit)
			Elseif iListButton3 == 3
				STR_TravelTo(_00E_FastTravel_Ark_Marker_CapitalCity_UndercityArena)
			elseif iListButton3 == 5 ; Exit
				return
			elseif iListButton3 == 4 ; Return
				ShowTravelMenuVanilla()
				return
			endif
			
		endif
		
	endif
	
	If iListButton == 0 || iListButton == 1 || iListButton == 3
		If MQ04.GetCurrentStageID() > 5 && !(MQ04.IsCompleted()) && !(MQ04.IsObjectiveCompleted(25))
			_00E_EPHandler.GiveEP(100)
			MQ04.SetObjectiveCompleted(25)
		EndIf
	EndIf
	
endfunction


;=====================================================================================
;									   PROPERTIES								   
;=====================================================================================

Actor Property PlayerREF Auto

Quest Property MQ12b Auto
Quest Property MQ12c Auto
Quest Property MQ14 Auto
Quest Property MQ03 Auto
Quest Property MQ04 Auto

Message Property _00E_FastTravel_Ark_CantTravelRightNow Auto
Message Property _00E_FastTravel_Ark_NoTemple Auto
Message Property _00E_FastTravel_Ark_SelectionMenu_01 Auto
Message Property _00E_FastTravel_Ark_SelectionMenu_02 Auto
Message Property _00E_FastTravel_Ark_SelectionMenu_03 Auto
Message Property _00E_FastTravel_Ark_SelectionMenu_Restricted1 Auto

GlobalVariable Property _00E_TeleportGlobal Auto

ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_Entrance Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_StrangerQuarter Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_Marketplace Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_SouthQuarter Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_NoblesQuarter Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_Harbour Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_UndercityEntrance Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_Graveyard Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_Suntemple Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_UndercityBarracks Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_UndercityMarketplace Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_UndercityTarpit Auto
ObjectReference Property _00E_FastTravel_Ark_Marker_CapitalCity_UndercityArena Auto

; Enderal AllTogether: the party travels along (they fade and arrive at the same spot, unless busy in a scene).
Function STR_TravelTo(ObjectReference akMarker)
	PlayerREF.MoveTo(akMarker)
	If EnderalAllTogether.IsLoaded()
		EnderalAllTogether.ShareTravel(akMarker)
	EndIf
EndFunction

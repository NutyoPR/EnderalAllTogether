scriptName _00E_Game_Playerhouse_BoardSC extends ObjectReference conditional

;=====================================================================================
;              							FUNCTIONS                 					 
;=====================================================================================

function EnableFurniture(Int iLevel)

	FadeToBlackIMOD.Apply(1.00000)
	utility.Wait(2 as Float)
	FadeToBlackHoldIMOD.ApplyCrossFade(1 as Float)
	if iLevel == 1
		_00E_Game_Playerhouse_ArkMarket_Level01Linker.Enable()
	elseIf iLevel == 2
		_00E_Game_Playerhouse_ArkMarket_Level02Linker.Enable()
	elseIf iLevel == 3
		_00E_Game_Playerhouse_ArkMarket_Level03Linker.Enable()
	endIf
	FadeToBlackBackIMOD.ApplyCrossFade(1 as Float)
	
endFunction

function DisableFurniture()

	FadeToBlackIMOD.Apply(1.00000)
	utility.Wait(2 as Float)
	FadeToBlackHoldIMOD.ApplyCrossFade(1 as Float)
	_00E_Game_Playerhouse_ArkMarket_Level01Linker.Disable(false)
	_00E_Game_Playerhouse_ArkMarket_Level02Linker.Disable(false)
	_00E_Game_Playerhouse_ArkMarket_Level03Linker.Disable(false)
	FadeToBlackBackIMOD.ApplyCrossFade(1 as Float)
	
endFunction


function OnActivate(ObjectReference akActionRef)
	
	;backwards compatibility for saves prior patch 1.2.3.0
	If (_00E_Game_Playerhouse_ArkMarket_Level01Linker.IsEnabled()) && _00E_FurniturePurchased.GetValue() < 1 ; Enderal AllTogether: never downgrade
		_00E_FurniturePurchased.SetValue(1)
	EndIf
	;backwards compatibility for saves prior patch 1.2.3.0
	
	Int iButton = _00E_Game_PlayerHouse_ArkMarket_Board.Show(0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000)
	if iButton == 7
		return 
	elseIf iButton == 0
	
		If PlayerREF.GetParentCell() == CapitalCityPlayerhouse
			PlayerREF.RemoveItem(Gold001, 300)
		Else
			PlayerREF.RemoveItem(Gold001, 1250)
		EndIf
		
		_00E_FurniturePurchased.SetValue(1)
		self.EnableFurniture(1)
		ShareFurniture(1)
		
	elseIf iButton == 1
	
		If PlayerREF.GetParentCell() == CapitalCityPlayerhouse
			PlayerREF.RemoveItem(Gold001, 500)
		Else
			PlayerREF.RemoveItem(Gold001, 1500)
		EndIf

		_00E_FurniturePurchased.SetValue(2)
		self.EnableFurniture(2)
		ShareFurniture(2)
		
	elseIf iButton == 2
	
		If PlayerREF.GetParentCell() == CapitalCityPlayerhouse
			PlayerREF.RemoveItem(Gold001, 700)
		Else
			PlayerREF.RemoveItem(Gold001, 1750)
		EndIf

		_00E_FurniturePurchased.SetValue(3)
		self.EnableFurniture(3)
		ShareFurniture(3)
		
	elseif iButton == 4
	
		int iButton02 = _00E_Game_PlayerHouse_RemoveFurniture.Show()
		
		if iButton02 == 0
		
			ReturnAndRefund()
		
		Else

			Activate(PlayerREF)
			
		EndIf
	
	elseif iButton == 5
	
		if EnderalFunctions.TextInputEnabled()
			Cell cCurrentCell = Self.GetParentCell()
			String sHouseName = NQ24.ChooseHouseName()
			cCurrentCell.SetName(sHouseName)
				
			If cCurrentCell == CapitalCityPlayerhouse
				Player.sHouseMarketQuarterName = sHouseName
			ElseIf cCurrentCell == CapitalCityPlayerHouseUpper
				Player.sHouseNobleQuarterName = sHouseName
			EndIf
		else
			Debug.Notification("Renaming requires SKSE and keyboard")
		endif
	
	elseif iButton == 6

		_00E_PlayerhousingMaster.GetMaster().ShowExpansionBoardTutorial()
	
	endIf
	
endFunction

;=====================================================================================
;              							FUNCTIONS                 					 
;=====================================================================================

Function ReturnAndRefund()

	DisableFurniture()
	ShareFurniture(0)
	
	If PlayerREF.GetParentCell() == CapitalCityPlayerhouse

		If _00E_FurniturePurchased.GetValue() == 1
			PlayerREF.AddItem(Gold001, 150)
			_00E_FurniturePurchased.SetValue(0)
		ElseIf _00E_FurniturePurchased.GetValue() == 2
			PlayerREF.AddItem(Gold001, 250)
			_00E_FurniturePurchased.SetValue(0)
		ElseIf _00E_FurniturePurchased.GetValue() == 3
			PlayerREF.AddItem(Gold001, 350)
			_00E_FurniturePurchased.SetValue(0)
		EndIf
		
	ElseIf PlayerREF.GetParentCell() == CapitalCityPlayerhouseUpper
		
		If _00E_FurniturePurchased.GetValue() == 1
			PlayerREF.AddItem(Gold001, 625)
			_00E_FurniturePurchased.SetValue(0)
		ElseIf _00E_FurniturePurchased.GetValue() == 2
			PlayerREF.AddItem(Gold001, 750)
			_00E_FurniturePurchased.SetValue(0)
		ElseIf _00E_FurniturePurchased.GetValue() == 3
			PlayerREF.AddItem(Gold001, 875)
			_00E_FurniturePurchased.SetValue(0)		
		EndIf
	
	EndIf
	
EndFunction


;=====================================================================================
;              Enderal AllTogether: shared house furniture
;=====================================================================================
; Skyrim Together doesn't sync which furniture a house has. Purchases are shared with the party through the
; Enderal AllTogether plugin, and every player's board applies the shared level when the house loads (or live,
; if it is loaded). Without the plugin nothing here does anything.

String Function FurnitureKey()
	Cell kCell = Self.GetParentCell()
	If !kCell
		return ""
	EndIf
	return "furniture:" + kCell.GetFormID()
EndFunction

Function ShareFurniture(Int aiLevel)
	If EnderalAllTogether.IsLoaded() && FurnitureKey() != ""
		EnderalAllTogether.ShareValue(FurnitureKey(), aiLevel)
	EndIf
EndFunction

Int Function CurrentFurnitureLevel()
	If _00E_Game_Playerhouse_ArkMarket_Level03Linker && _00E_Game_Playerhouse_ArkMarket_Level03Linker.IsEnabled()
		return 3
	ElseIf _00E_Game_Playerhouse_ArkMarket_Level02Linker && _00E_Game_Playerhouse_ArkMarket_Level02Linker.IsEnabled()
		return 2
	ElseIf _00E_Game_Playerhouse_ArkMarket_Level01Linker && _00E_Game_Playerhouse_ArkMarket_Level01Linker.IsEnabled()
		return 1
	EndIf
	return 0
EndFunction

; Shows exactly the furniture of the shared level (no purchase fade: this happens in the background).
Function ApplySharedFurniture()
	If !EnderalAllTogether.IsLoaded() || FurnitureKey() == ""
		return
	EndIf
	Int iLevel = EnderalAllTogether.GetSharedValue(FurnitureKey(), -1)
	If iLevel < 0 || iLevel == CurrentFurnitureLevel()
		return
	EndIf
	SetLinker(_00E_Game_Playerhouse_ArkMarket_Level01Linker, iLevel >= 1)
	SetLinker(_00E_Game_Playerhouse_ArkMarket_Level02Linker, iLevel >= 2)
	SetLinker(_00E_Game_Playerhouse_ArkMarket_Level03Linker, iLevel >= 3)
EndFunction

Function SetLinker(ObjectReference akLinker, Bool abEnabled)
	If !akLinker
		return
	EndIf
	If abEnabled && akLinker.IsDisabled()
		akLinker.Enable()
	ElseIf !abEnabled && !akLinker.IsDisabled()
		akLinker.Disable()
	EndIf
EndFunction

Event OnCellAttach()
	RegisterForModEvent("EnderalAllTogether_Shared", "OnEnderalAllTogetherShared")
	ApplySharedFurniture()
EndEvent

Event OnCellDetach()
	UnregisterForModEvent("EnderalAllTogether_Shared")
EndEvent

; Mod event callback (registered in OnCellAttach). A function rather than an Event: it is called by name either way,
; and Caprica only accepts custom Event names in native scripts.
Function OnEnderalAllTogetherShared(String asEventName, String asKey, Float afValue, Form akSender)
	If asKey == FurnitureKey()
		ApplySharedFurniture()
	EndIf
EndFunction

;=====================================================================================
;              							PROPERTIES                 					 
;=====================================================================================

Actor Property PlayerREF Auto

Cell Property CapitalCityPlayerhouse Auto
Cell Property CapitalCityPlayerHouseUpper Auto

GlobalVariable Property _00E_FurniturePurchased Auto

bool Property bLevel01FurniturePurchased Auto Conditional Hidden
bool Property bLevel02FurniturePurchased Auto Conditional Hidden
bool Property bLevel03FurniturePurchased Auto Conditional Hidden

imagespacemodifier property FadeToBlackBackIMOD auto
ObjectReference property _00E_Game_Playerhouse_ArkMarket_Level01Linker auto
message property _00E_Game_PlayerHouse_ArkMarket_Board auto
imagespacemodifier property FadeToBlackIMOD auto
Bool property __Config_bHouseHasLevel02 auto conditional
{Check this if this house has level 02 furniture designed.}
ObjectReference property _00E_Game_Playerhouse_ArkMarket_Level02Linker auto
imagespacemodifier property FadeToBlackHoldIMOD auto
Bool property __Config_bHouseHasLevel01 auto conditional
{Check this if this house has level 01 furniture designed.}
ObjectReference property _00E_Game_Playerhouse_ArkMarket_Level03Linker auto
Bool property __Config_bHouseHasLevel03 auto conditional
{Check this if this house has level 03 furniture designed.}

MiscObject Property Gold001 Auto

Message Property _00E_Game_PlayerHouse_RemoveFurniture Auto

_00E_NQ24_Playerhousing_Functions Property NQ24 Auto
_00E_PlayerHousing_CellNameSC Property Player Auto

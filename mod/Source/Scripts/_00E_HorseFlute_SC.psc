Scriptname _00E_HorseFlute_SC extends ReferenceAlias

;=====================================================================================
;              							EVENTS                  					 
;=====================================================================================

; this event registers for the key as soon as the player receives the horseflute in any way
; due to being a questobject, it can't be dropped or lost by the player, it also stays in the menu when marked as a favorite
Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	If (akNewContainer == PlayerREF) && SKSE.GetVersion()
		RegisterForKey(iMountHotkey)
	EndIf
EndEvent

; If gets used from the inventory instead of the hotkey, it gets equipped in an otherwise unused equipment slot, 
; therefore it doesn't interfere with the other gear
Event OnEquipped(Actor akActor)
	
	PlayerREF.UnequipItemSlot(60)
	; forces the inventory menu to close
	Game.DisablePlayerControls(abMenu = true)
	Game.EnablePlayerControls(abMenu = true)
	
	; check if the player is already on a mount and if so in the worldspace Vyn (= not in interior or anywhere else quest related)
	If PlayerRef.IsOnMount() == False
		IsTeleportAllowed()
	EndIf
	
EndEvent

Event OnKeyDown(Int KeyCode)
	
	; this does basically the same as above, however we need an extensive check when the player is acutally allowed to use the hotkey
	; checks if the keycode is the code for which we registere, the keycode is changed in _00E_EnderalMCM
	; further checks are if the player is certain menus or currently typing in a search bar, Utility.IsInMenuMode() does not catch the dialogue menu, hence it needs to be checked as well. 
	; also the player shouldn't be dead
	If KeyCode == iMountHotkey && Utility.IsInMenuMode() == False && UI.IsTextInputEnabled() == False && PlayerRef.IsOnMount() == False && Game.IsFightingControlsEnabled() == true && UI.IsMenuOpen("Dialogue Menu") == False && !PlayerREF.IsDead()
		IsTeleportAllowed()
	EndIf
	
EndEvent

;=====================================================================================
;              							FUNCTIONS                  					 
;=====================================================================================

Function IsTeleportAllowed()

	If PlayerREF.GetWorldSpace() == Vyn
		PrepareTeleport()
	Else
		MAGFail.Play(PlayerREF)
		_00E_Horseflute_sMountOnlyInExterior.Show()
	EndIf

EndFunction

Function PrepareTeleport()

	; if the player only has one mount, summon it immediately
	; if the player has multiple mounts, show as prompt on which one to summon
	If _00E_MountGlobal.GetValueInt() == 1

		If _00E_MuleOwned.GetValueInt() == 1
			TeleportMount(PlayerEsel)
		ElseIf _00E_HorseOwned.GetValueInt() == 1
			TeleportMount(PlayerHorse)
		ElseIf _00E_FathersShadowOwned.GetValueInt() == 1
			TeleportMount(FS_NQR05_FatherShadowREF)
		EndIf

	ElseIf _00E_MountGlobal.GetValueInt() > 1

		iButton = SelectionMenu.show()
		If iButton == 0
			TeleportMount(PlayerEsel)
		ElseIf iButton == 1
			TeleportMount(PlayerHorse)
		ElseIf iButton == 2
			TeleportMount(FS_NQR05_FatherShadowREF)
		ElseIf iButton == 3
			NQ06_Freda.RenameMount(true)
		EndIf

	EndIf

EndFunction


Function TeleportMount(Actor MountRef, float minDistance = 250.0, float maxDistance = 500.0)

	; Enderal AllTogether: each mount exists once in the world, and the flute pulled it away from whoever had it (or did
	; nothing for players whose game doesn't control it). In co-op every player rides their own: the flute brings your
	; personal copy, made the first time from the same horse, mule or Father's Shadow and kept in your save. Skyrim
	; Together shows it to the others like any other creature.
	If EnderalAllTogether.IsLoaded() && EnderalAllTogether.InCoop()
		Actor kMine = GetPersonalMount(MountRef)
		If kMine
			MountRef = kMine
		EndIf
	EndIf
	
	; the mount is now teleported to the player
	; However, it's not only placed directly on the player but "immersively" next to the player but outside of the FOV
	float playerAngle = playerRef.GetAngleZ()
	float arcStart = playerAngle + 180 - (90 / 2)
	float angleStart = Utility.RandomFloat(arcStart, arcStart + 90)
	float moveDistance = Utility.RandomFloat(minDistance, maxDistance)
	float horseX = moveDistance * Math.Sin(angleStart)
	float horseY = moveDistance * Math.Cos(angleStart)
	MountRef.Disable(abFadeOut = false)
	MountRef.MoveTo(playerRef, horseX, horseY, 0)
	MountRef.Enable(abFadeIn = false)
	_00E_HorseFlute_SoundM.Play(PlayerREF)
	_00E_HorseFlute_sMountPorted.Show()

EndFunction

Actor kMyEsel
Actor kMyHorse
Actor kMyShadow

Actor Function GetPersonalMount(Actor akShared)
	Actor kMine
	If akShared == PlayerEsel
		kMine = kMyEsel
	ElseIf akShared == PlayerHorse
		kMine = kMyHorse
	ElseIf akShared == FS_NQR05_FatherShadowREF
		kMine = kMyShadow
	Else
		Return None
	EndIf
	If kMine && !kMine.IsDead()
		Return kMine
	EndIf
	If !akShared
		Return None
	EndIf
	kMine = PlayerREF.PlaceActorAtMe(akShared.GetActorBase())
	If !kMine
		Return None
	EndIf
	kMine.SetActorOwner(PlayerREF.GetActorBase())
	If akShared == PlayerEsel
		kMyEsel = kMine
	ElseIf akShared == PlayerHorse
		kMyHorse = kMine
	Else
		kMyShadow = kMine
	EndIf
	Return kMine
EndFunction

Function SetMountTeleportKey(int iKeyCode)
	
	; changes the registered key, gets called from _00E_EnderalMCM
	UnregisterForKey(iMountHotkey)
	iMountHotkey = iKeyCode
	RegisterForKey(iMountHotkey)
	
EndFunction

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

Int iButton
Int Property iMountHotkey = 38 Auto Hidden ; defaults to the key L

GlobalVariable Property _00E_MountGlobal Auto
GlobalVariable Property _00E_HorseOwned Auto
GlobalVariable Property _00E_MuleOwned Auto
GlobalVariable Property _00E_FathersShadowOwned Auto

Message Property _00E_Horseflute_sMountOnlyInExterior Auto
Message Property _00E_Horseflute_sMountPorted Auto

Message Property SelectionMenu Auto

_00E_NQ06_Functions Property NQ06_Freda Auto

Sound Property _00E_HorseFlute_SoundM Auto
Sound Property MAGFail Auto

Actor Property PlayerHorse Auto
Actor Property PlayerEsel Auto
Actor Property FS_NQR05_FatherShadowREF Auto
Actor Property PlayerREF Auto

Faction Property PlayerFaction Auto

Worldspace Property Vyn Auto
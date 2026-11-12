Scriptname _00E_MQ03_Functions extends Quest  

Import Utility

int function _GetScriptVersion() Global
    return 1
endFunction

;=====================================================================================
;              							FUNCTIONS                  					 
;=====================================================================================

Function StartEscortScene()

	_00E_MC_YuslanRef.Disable()
	PlayerREF.UnequipItem(PlayerREF.GetEquippedWeapon())
	PlayerREF.UnequipItem(PlayerREF.GetEquippedWeapon(true))
	PlayerREF.UnequipItem(PlayerREF.GetEquippedShield())
	PlayerREF.EquipItem(_00E_ClothesFarmClothesVariant04Kilean, false, false)
	PlayerREF.EquipItem(ClothesJarlShoes, false, false)
	PlayerREF.EquipItem(ClothesFineHat02, false, false)
	PlayerREF.EquipItem(ClothesJarlGloves, false, false)
	PlayerREF.EquipItem(DummyArrow, false, true)
	PlayerREF.UnequipItem(DummyArrow, false, true)
	; fixes http://sureai.net:9898/browse/ERB-2028
	PlayerREF.RemoveItem(DummyArrow, 1, true)
	MQ03_SC01_JesparTalksToTempleguard.ForceStart()
    SetObjectiveCompleted(10)
	
EndFunction

Function StartKonstantinScene()

	_00E_MC_KonstantinREF.MoveToMyEditorLocation()
	MQ03_SC2_PlayerMeetsKonstantin.ForceStart()

	AllowIdleChatter.SetValue(0)

EndFunction

Function PlaceExplosion()

	Game.ShakeCamera(afStrength = 0.5)
	_00E_MC_JesparREF.KnockAreaEffect(1, 512)
	MQ03_SC2_ExplosionMarker.PlaceAtMe(_00E_MQ03_HarmlessExplosion, 1)
	MQ03_SC2_Smoke.Enable()
	
EndFunction

Function StartKonstantinScene02()

	MQ03_SC3_DoorKonstantinREF.SetOpen(True)
	MQ03_SC3_PlayerMeetsKonstantin02.ForceStart()
	
EndFunction

Function StartExamineScene()

	Game.DisablePlayerControls(true, true, True, False, true, true, true, false)
	Game.ForceFirstPerson()
	MQ03_SC4_KonstantinExaminesPlayer.ForceStart()
	
EndFunction

Function FadeToBlackAndBack()

	_00E_FadingGlobal.SetValueInt(0)
	FadeToBlackIMOD.Apply()
	Wait(3)
	FadeToBlackIMOD.PopTo(FadeToBlackHoldIMOD)
	PlayerREF.MoveTo(MQ03_SC4_PlayerPortToMarker)
	_00E_MC_JesparREF.MoveTo(MQ03_SC4_JesparSniffleStartMarker)
	MQ03_SC4_BenchPlayer.Activate(PlayerREF)
	Self.SetCurrentStageID(43)

EndFunction

Function SitKonstantinDown()

    ; This is for the end script of scene
    ; MQ03_SC4_KonstantinExaminesPlayer. Sometimes Constantine would
    ; not find his way to the bench (see, e.g.,
    ; http://sureai.net:9898/browse/ERB-736 ). In this case, we move
    ; him to the bench:
    if _00E_MC_KonstantinREF.GetSitState() != 3
        _00E_MC_KonstantinREF.Disable()
        _00E_MC_KonstantinREF.Enable()
        _00E_MC_KonstantinREF.MoveTo(MQ03_SC4_KonstantinBench)
        _00E_MC_KonstantinREF.EvaluatePackage()
    endif
	
EndFunction

Function FadeBack()

	FadeToBlackHoldIMOD.PopTo(FadeToBlackBackIMOD)
	MQ03_SC2_Smoke.Disable()
	Wait(1)
	_00E_FadingGlobal.SetValueInt(1)
	If EnderalAllTogether.IsLoaded()
		EnderalAllTogether.ShareRelease() ; Enderal AllTogether: the partner's game lets go too
	EndIf

EndFunction

Function RemoveFade_Failsave()

	FadeToBlackHoldIMOD.Remove()

EndFunction

Function DispelEffect()

	PlayerREF.DispelSpell(_00E_MQ03_KonstantinRitualSpell)

EndFunction

Function GiveGoldReward()

	Game.EnablePlayerControls()
	Game.SetPlayerAIDriven(False)
	If EnderalAllTogether.IsLoaded()
		EnderalAllTogether.ShareRelease() ; Enderal AllTogether: the partner's game lets go too
	EndIf
	PlayerREF.AddItem(Gold001, __Config_GoldReward)
	PlayerREF.AddItem(_01E_TeleportrolleSonnentempel, 2, false)
	PlayerREF.AddItem(_01E_TeleportrolleArk, 2, false)
	If _00E_DisableOtherTutorials.GetValueInt() == 0
		Utility.Wait(1)
		_00E_Tutorial_Teleport.ShowAsHelpMessage("Teleport", 5, 1, 1)
	EndIf
	
EndFunction

Function GiveRewardEXP()

	_00E_PlayerFunctions.GetSoundControl().RemoveSilence()
	_00E_PlayerFunctions.GetSoundControl().RemoveCombatSoundtracks()
	_00E_EPHandler.GiveEP(__Config_RewardEXP)
	_00E_MC_KonstantinREF.EvaluatePackage()
	_00E_MC_JesparREF.EvaluatePackage()
	MQ04.Start()
	MQ04.SetCurrentStageID(10)
	CQJ01.SetCurrentStageID(5)
	If _00E_DisableQuestTutorials.GetValueInt() == 0
		_00E_Tutorial_Companions.Show()
	EndIf

	AllowIdleChatter.SetValue(1)

EndFunction

;=====================================================================================
;              							PROPERTIES                  					 
;=====================================================================================

int Property __Config_RewardEXP Auto
{How much EXP is given to the player upon completion}
int Property __Config_GoldReward Auto
{How much gold is given to the player by Jespar upon quest completion}

GlobalVariable Property AllowIdleChatter Auto

Scene Property MQ03_SC01_JesparTalksToTempleguard Auto
Scene Property MQ03_SC2_PlayerMeetsKonstantin Auto
Scene Property MQ03_SC3_PlayerMeetsKonstantin02 Auto
Scene Property MQ03_SC4_KonstantinExaminesPlayer Auto

Armor Property _00E_ClothesFarmClothesVariant04Kilean Auto
Armor Property ClothesJarlShoes Auto
Armor Property ClothesFineHat02 Auto
Armor Property ClothesJarlGloves Auto

Ammo Property DummyArrow Auto

Actor Property _00E_MC_YuslanRef Auto

MiscObject Property Gold001 Auto

GlobalVariable Property _00E_FadingGlobal Auto
GlobalVariable Property _00E_DisableOtherTutorials Auto
GlobalVariable Property _00E_DisableQuestTutorials Auto

Quest Property MQ04 Auto
Quest Property CQJ01 Auto

Scroll Property _01E_TeleportrolleArk Auto
Scroll Property _01E_TeleportrolleSonnentempel Auto

ObjectReference Property MQ03_SC2_Smoke Auto
ObjectReference Property MQ03_SC3_DoorKonstantinREF Auto
ObjectReference Property MQ03_SC4_PlayerPortToMarker Auto
ObjectReference Property MQ03_SC4_BenchPlayer Auto
ObjectReference Property MQ03_SC2_ExplosionMarker Auto
ObjectReference Property MQ03_SC4_JesparSniffleStartMarker Auto
ObjectReference Property MQ03_SC4_KonstantinBench Auto

Message Property _00E_Tutorial_Companions Auto

Explosion Property _00E_MQ03_HarmlessExplosion Auto

ImageSpaceModifier Property FadeToBlackIMOD Auto
ImageSpaceModifier Property FadeToBlackHoldIMOD Auto
ImageSpaceModifier Property FadeToBlackBackIMOD Auto

Message Property _00E_Tutorial_Teleport Auto

Actor Property _00E_MC_KonstantinREF Auto
Actor Property _00E_MC_JesparREF Auto
Actor Property PlayerREF Auto

Spell Property _00E_MQ03_KonstantinRitualSpell Auto

Idle Property IdleNoteRead Auto
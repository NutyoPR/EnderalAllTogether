Scriptname _00E_NQ_Bounty01_TargetScript extends ReferenceAlias  

; SCRIPT AUTHOR DENNIS MAY 2014
; Script handles Bandit appearance and checks if bounty job is done
; SCRIPT CHANGE TILL MAY 2018
; Added-in Body Clean-up suggested by gavrant for performance reasons, check out WIDeadBodyCleanupScript for original code
; Eddoursul, January 2024: Made bounty targets protected instead of essential. Protected actors can be killed by apparitions as well.

; ====================================================================================
           							; EVENTS                  					 
; ====================================================================================	

Event OnCellAttach() ;FIRE WHEN PLAYER ENTERS THE CELL THE NEEDED ACTOR IS IN
	If NQ_Bounty01.GetCurrentStageID() == __Config_iEnableAtStage && GetReference().IsDisabled()
		GetReference().Enable() ; Enable the bandit when he is needed in the quest
		
		; Technically, not required since 2.1, adding this in case of overwrite by an outdated mod
		(GetReference() as Actor).GetActorBase().SetEssential(false)
	Endif
EndEvent

Event OnDeath(Actor akKiller)
    Int iStage = __Config_iEnableAtStage

    NQ_Bounty01.SetObjectiveCompleted(iStage)		;MissionObjective: Kill the bandit - Done

    iStage += 5
    NQ_Bounty01.SetCurrentStageID(iStage)					;MissionObjective: Take your bounty - New
    NQ_Bounty01.SetObjectiveDisplayed(iStage)		;Show Objective
    BountyScript._00E_NQ_Bounty01_Status = 2		;Unlock bounty board to receive your gold
    If EnderalAllTogether.IsLoaded()
    	EnderalAllTogether.ShareValue("bounty:" + NQ_Bounty01.GetFormID(), iStage) ; Enderal AllTogether: the party's journals follow
    EndIf
EndEvent

; ====================================================================================
;            							PROPERTIES                  					 
; ====================================================================================

Quest Property NQ_Bounty01 Auto
_00E_NQ_Bounty01_Functions Property BountyScript Auto			;ACCESS TO QUEST SCRIPT
Int Property __Config_iEnableAtStage Auto  
{Type the quest stage number to enable the bandit 10, 30, 50. Enable new enemy every 20th stage }

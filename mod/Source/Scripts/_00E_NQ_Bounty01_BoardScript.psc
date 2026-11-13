Scriptname _00E_NQ_Bounty01_BoardScript extends ObjectReference

int function _GetScriptVersion() Global
    return 1
endFunction

; SCRIPT AUTHOR DENNIS MAY 2014
; Script handles all the bounty board functions
; Script is automated, use the quest NQ_Bounty01 to do the configuration
; ====================================================================================
                                    ; EVENTS                                     
; ====================================================================================  
    
Int iStage = 0
Int iQuestDone = 0

Event OnActivate (ObjectReference akActionRef)
  
    If ( akActionRef == game.GetPlayer() )
        ; Enderal AllTogether: take where the bounties stand from the quest stage, which Skyrim Together shares, so this
        ; board agrees with the party however everyone used theirs (10 = accepted, 15 = target dead, 20 = paid, +20 each).
        If NQ_Bounty01.IsRunning() && BountyScript._00E_NQ_Bounty01_Status != 10
            Int iCurrent = NQ_Bounty01.GetCurrentStageID()
            Int iStep = iCurrent % 20
            iQuestDone = iCurrent / 20
            iStage = iCurrent - (iStep % 10)
            If iStep == 10
                BountyScript._00E_NQ_Bounty01_Status = 1
            ElseIf iStep == 15
                BountyScript._00E_NQ_Bounty01_Status = 2
            Else
                BountyScript._00E_NQ_Bounty01_Status = 0
            EndIf
        EndIf
        Int iAvailableQuests = BountyScript._00E_NQ_Bounty01_Quest01_mb_FormList.GetSize()  
        GotoState("TurnOffActivate")

        If ( iStage == 0 )                                                  ;Do this once when board board is activated the first time
            NQ_Bounty01.Start()
            NQ_Bounty01.SetObjectiveDisplayed(iStage)
        Endif
    

        If ( BountyScript._00E_NQ_Bounty01_Status == 0)                     ;APPEARS WHEN YOU HAVE NO CURRENT BOUNTY MISSION
            M_one (_00E_NQ_Bounty_mainMenu_mb)                  
        elseif ( BountyScript._00E_NQ_Bounty01_Status == 10) 
            _00E_NQ_Bounty_noMissions_mb.Show()
			GotoState("")
            return
        ElseIf ( BountyScript._00E_NQ_Bounty01_Status == 2)                 ;APPEARS WHEN TARGET IS KILLED - REWARD BLOCK
        
            NQ_Bounty01.SetObjectiveDisplayed(iStage, false)                ;Hide Kill objective
        
            iStage += 5                                                     ;Up QuestStage +5
            NQ_Bounty01.SetObjectiveCompleted(iStage)                       ;Complete previous objective = Collect your bounty
            
            BountyScript.GiveGold(BountyScript.__Config_MissionRewards[iQuestDone]) ;Give Player the Gold
        
            iStage += 5                                                     ;Up QuestStage +5
            NQ_Bounty01.SetCurrentStageID(iStage)
            iQuestDone += 1
            If ( iQuestDone == iAvailableQuests )
                BountyScript._00E_NQ_Bounty01_Status = 10
                NQ_Bounty01.Stop()
            else
                BountyScript._00E_NQ_Bounty01_Status = 0                                ;Unlock bounty board again 
            Endif
        
            If EnderalAllTogether.IsLoaded()
            	EnderalAllTogether.ShareValue("bounty:" + NQ_Bounty01.GetFormID(), iStage) ; Enderal AllTogether: the party's journals follow
            EndIf
            _00E_NQ_Bounty_recieveBounty_mb.Show()
            GotoState("")
    
        Else                                                                ;APPEARS WHEN YOU ARE ON A BOUNTY MISSION
            _00E_NQ_Bounty_activeMission_mb.Show()                          ;Bounty active message
            GotoState("")
            Return
        Endif
        
    Endif
  
EndEvent

State TurnOffActivate
    Event OnActivate(ObjectReference akActionRef)
        ; 2.1.4 Eddoursul: If player activated the board after the last mission, the script was sent to this state forever.
		; Fixed to show the _00E_NQ_Bounty_noMissions_mb message every time.
		if BountyScript._00E_NQ_Bounty01_Status == 10
            _00E_NQ_Bounty_noMissions_mb.Show()
			GotoState("")
		endif
    endEvent
endState


; ====================================================================================
;                                       FUNCTIONS                                    
; ====================================================================================


Function M_one (Message chosenMessage)                                      ;CHECK FOR BOUNTY MISSIONS
    
    Int iAvailableQuests = BountyScript._00E_NQ_Bounty01_Quest01_mb_FormList.GetSize()      ;Get the count of Quests available in the FormList
    Int iButton = chosenMessage.Show()              
    
    If ( iButton == 0 )                                                     ;ACCESS BOUNTY MISSION TAB
        ;debug.Notification(iQuestDone + " " + iAvailableQuests)
        If ( iQuestDone < iAvailableQuests )
            Message SelectQuestMessage = BountyScript._00E_NQ_Bounty01_Quest01_mb_FormList.GetAt(iQuestDone) as Message ;SHOW CURRENT BANDIT DESCRIPTION
            M_two (SelectQuestMessage)
        Else
            _00E_NQ_Bounty_noMissions_mb.Show()                             ;SORRY, NO MORE QUESTS
            GotoState("")
        Endif
    
    ElseIf ( iButton == 1 )                                                 ;CLOSE BOUNTY MISSION TAB
        GotoState("")
        Return
    EndIf
    
EndFunction



Function M_two (Message chosenMessage2)                                     ;ACCEPT BOUNTY MISSIONS OR DENY THEM

    Utility.Wait(0.5)

    Int iButton2 = chosenMessage2.Show(BountyScript.__Config_MissionRewards[iQuestDone])    ;Fill mission description with given bounty value                   
    
    If ( iButton2 == 0 )                                                    ;ACCEPT THE SHOWN BOUNTY MISSION

        If ( iStage == 0 )                                                  ;Complete first objective / DO it once
            NQ_Bounty01.SetObjectiveCompleted(iStage)
        Endif

        ; Now comes some trickery. What this function is supposed to
        ; do is raising iStage (a local copy of the quest stage) from
        ; an integer of the form 20k (with k an integer) to 20k+10.
        ; (Indeed, 20k means "no current bounty mission", while 20k+10
        ; means "bounty mission started but target not yet killed".)
        ; However, sometimes this function gets called when iStage is
        ; at a value of the form 20k+10 (this tends to happen when
        ; you activate the bounty board many times in rapid
        ; succession, due to the latency of something in the engine).
        ; To prevent this from incorrectly raising quest stages, we
        ; first check that iStage is divisible by 20:
        ; [NOTE: I'm not sure if this is necessary at all, as I have
        ; troubles reproducing this bug.]
        
        int iStagemod20 = iStage - ((20 * math.floor(iStage / 20)) as int)
        if !(iStagemod20 == 0) && !(iStagemod20 == 20) && !(iStagemod20 == -20)
            ;Debug.Notification("machine-gun clicking detected")
            GotoState("")
            Return
        endif
        
        iStage += 10														;Up QuestStage +10
		NQ_Bounty01.SetCurrentStageID(iStage)
        NQ_Bounty01.SetObjectiveDisplayed(iStage)
        BountyScript._00E_NQ_Bounty01_Status = 1                            ;Bounty quest active
        If EnderalAllTogether.IsLoaded()
        	EnderalAllTogether.ShareValue("bounty:" + NQ_Bounty01.GetFormID(), iStage) ; Enderal AllTogether: the party's journals follow
        EndIf
        GotoState("")

    ElseIf ( iButton2 == 1 )                                                ;DENY THE SHOWN BOUNTY MISSION
        GotoState("")
        return
    EndIf

EndFunction



; ====================================================================================
;                                       PROPERTIES                                       
; ====================================================================================

Quest property NQ_Bounty01 Auto
Message property _00E_NQ_Bounty_mainMenu_mb auto
Message property _00E_NQ_Bounty_activeMission_mb auto
Message property _00E_NQ_Bounty_recieveBounty_mb auto
Message property _00E_NQ_Bounty_noMissions_mb auto

_00E_NQ_Bounty01_Functions Property BountyScript Auto           ;ACCESS TO QUEST SCRIPT


; ====================================================================================
;                                       DESCRIPTIONS                                     
; ====================================================================================

    ; BOUNTY QUEST STATUS BOARD
    ; _00E_NQ_Bounty01_Status (0) - No bounty mission selected
    ; _00E_NQ_Bounty01_Status (1) - Bounty quest active
    ; _00E_NQ_Bounty01_Status (2) - Target killed, time for the reward
    
    
    ; QUEST STAGE PROCEDURE RULES
    ; 10 New Mission
    ; 15 Target Killed
    ; 20 Reward Collected
    ; --- 10 Stage Gap ---
    ; 30 New Mission
    ; 35 Target Killed
    ; 40 Reward Collected
    ; --- 10 Stage Gap ---
    ; 50 New Mission
    ; 55 Target etc. ...


  

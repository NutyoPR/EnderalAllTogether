scriptname _00E_A0_BankSystemQuest extends Quest Conditional

import Game
import Utility


;****************
; How to call:
;****************

; Einzahlen: (BankQuest as _00E_A0_BankSystemQuest).Transfer("start", "Deposit")
;	Abheben: (BankQuest as _00E_A0_BankSystemQuest).Transfer("start", "Withdraw")

;=====================================================================================
;              							 EVENT                   					 
;=====================================================================================

Event OnUpdate()

	if bRestartDeposit
	
		bRestartDeposit = False
		Transfer("start", "Deposit")
		
	Elseif bRestartWithdraw
	
		bRestartWithdraw = False 
		Transfer("start", "Withdraw")
	
	EndIf

EndEvent

;=====================================================================================
;              							 FUNCTIONS                   					 
;=====================================================================================

Function Terminate(String TransferAction)

	Transfer("null", "RecalculateZins")			; < Finger weg!

ENDfunction 

Int CashFlow
Int iMaxAmount 
Bool Registered

function Transfer(string TransferRate, string TransferAction)

	bTransferInAction = True
		EATRestoreBalance()
		Deposited = REFdepositBox.getItemCount(Gold) as int
		GLBcurrent.setValue(Deposited)

;	Zinsformel **********************************************************************************************

		if Deposited < 100
			ZinsPercent = 0.3
		elseif Deposited > 99 && Deposited < 300
			ZinsPercent = 0.5
		elseif Deposited > 299 && Deposited < 400
			ZinsPercent = 0.8
		elseif Deposited > 399 && Deposited < 500
			ZinsPercent = 1.2
		elseif Deposited > 499 && Deposited < 600
			ZinsPercent = 1.6
		elseif Deposited > 599 && Deposited < 700
			ZinsPercent = 1.9
		elseif Deposited > 699 && Deposited < 800
			ZinsPercent = 2.1
		elseif Deposited > 799 && Deposited < 900
			ZinsPercent = 2.4
		elseif Deposited > 899 && Deposited < 1000
			ZinsPercent = 2.6
		elseif Deposited == 1000 || Deposited > 1000 
			ZinsPercent = 2.8
		endif
					
		Zins = REFdepositBox.getItemCount(Gold) /100.0 *ZinsPercent
		if Zins > 250
			Zins = 250
		endif
		
;	********************************************************************************************************

		if TransferAction != "RecalculateZins"
			If Registered == false 
				RegisterForSingleUpdateGameTime(24)
				Registered = true
			endif
			
			if TransferRate == "start"
				if TransferAction == "Deposit"
					iMaxAmount = GetPlayer().GetItemCount(Gold) 
					
					if EnderalFunctions.TextInputEnabled()
						CashFlow = (((Self as QUEST) as FORM) as UILIB_1).ShowTextInput(_00E_BankSystem_Deposit_Comfy.GetName() + iMaxAmount + ")", iMaxAmount) as Int
					else
						int iFallback = _00E_BankSystem_Deposit_FallbackSelect.Show(Deposited)
						
						if iFallback == 0
							CashFlow = 100
						elseif iFallback == 1
							CashFlow = 250
						elseif iFallback == 2
							CashFlow = 500
						elseif iFallback == 3
							CashFlow = 1000
						elseif iFallback == 4
							CashFlow = 1500
						elseif iFallback == 5
							CashFlow = 2000
						else
							bTransferInAction = False
							return
						endif
					endif
				else
					iMaxAmount = iEATBalance ; Enderal AllTogether: your own balance, not whatever the box holds right now
					
					if EnderalFunctions.TextInputEnabled()
						CashFlow = (((Self as QUEST) as FORM) as UILIB_1).ShowTextInput(_00E_BankSystem_Withdraw_Comfy.GetName() + iMaxAmount + ")", iMaxAmount) as Int
					else
						int iFallback = _00E_BankSystem_Withdraw_FallbackSelect.Show(iMaxAmount)
						
						if iFallback == 0
							CashFlow = 100
						elseif iFallback == 1
							CashFlow = 250
						elseif iFallback == 2
							CashFlow = 500
						elseif iFallback == 3
							CashFlow = 1000
						elseif iFallback == 4
							CashFlow = 1500
						elseif iFallback == 5
							CashFlow = 2000
						elseif iFallback == 6
							CashFlow = iMaxAmount
						else
							bTransferInAction = False
							return
						endif
					endif
				endif
				
				if CashFlow <= 0
					bTransferInAction = False
					return
				endif
		
				if CashFlow > iMaxAmount
				
					if TransferAction == "Deposit"
				
						_00E_Bank_NotEnoughMoneyDeposit.Show()
						
						if ! EnderalFunctions.TextInputEnabled()
							bTransferInAction = False
							return
						endif
						
						bRestartDeposit = True
						RegisterForSingleUpdate(1)
					
					Else 
					
						_00E_Bank_NotEnoughMoneyWithdraw.Show()
						
						if ! EnderalFunctions.TextInputEnabled()
							bTransferInAction = False
							return
						endif
						
						bRestartWithdraw = True
						RegisterForSingleUpdate(1)
					
					EndIf
					
				Else
				
					; Enderal AllTogether: the balance in your save changes by the amount, then the box is put back to it. The
					; box itself can change while you type the amount (a partner entering the vault syncs its contents), so
					; it is never read back as your balance.
					if TransferAction == "Deposit"
					
						getplayer().removeItem(Gold, CashFlow, False)
						iEATBalance += CashFlow
						;SFXgoldDeposit.play(getplayer())
						
					elseif TransferAction == "Withdraw"
					
						getplayer().additem(Gold, CashFlow, False)
						iEATBalance -= CashFlow
						;SFXgoldWithdraw.play(getplayer())
						
					endif
					EATRestoreBalance()
					Deposited = iEATBalance
					GLBcurrent.setValue(Deposited)
							
					If TransferAction == "Deposit"
						Bankier.GetActorReference().Say(BankSystem_D0_PlayerDepositTopic)
					Elseif TransferAction == "Withdraw"
						Bankier.GetActorReference().Say(BankSystem_D0_PlayerWithdrawTopic)
					EndIf

				EndIf
				
			Terminate(TransferAction)
					
			bTransferInAction = False
			
			endif
		endif
ENDfunction 

Function ShowRootMenu()

	EATRestoreBalance()
	Deposited = iEATBalance ; Enderal AllTogether: the interest shown below goes by the current balance

	if Deposited < 100
		ZinsPercent = 0.3
	elseif Deposited > 99 && Deposited < 300
		ZinsPercent = 0.5
	elseif Deposited > 299 && Deposited < 400
		ZinsPercent = 0.8
	elseif Deposited > 399 && Deposited < 500
		ZinsPercent = 1.2
	elseif Deposited > 499 && Deposited < 600
		ZinsPercent = 1.6
	elseif Deposited > 599 && Deposited < 700
		ZinsPercent = 1.9
	elseif Deposited > 699 && Deposited < 800
		ZinsPercent = 2.1
	elseif Deposited > 799 && Deposited < 900
		ZinsPercent = 2.4
	elseif Deposited > 899 && Deposited < 1000
		ZinsPercent = 2.6
	elseif Deposited == 1000 || Deposited > 1000
		ZinsPercent = 2.8
	endif
		
	Zins = REFdepositBox.getItemCount(Gold) /100.0 *ZinsPercent
	
	
	if Zins > 250
		Zins = 250
	endif		

	int iButton = _00E_BankSystem_Root.Show(iEATBalance, Zins, _00E_BankSystem_Beteiligungen.GetValue() as int, getplayer().GetItemCount(gold) as int)
	
	if iButton == 0
		Transfer("start", "Deposit")
	Elseif iButton == 1
		Transfer("start", "Withdraw")
	Else
		Return
	EndIf

EndFunction

int ZinsHistory
Event OnUpdateGameTime()

	EATRestoreBalance()
	ZinsHistory = ZinsHistory +Zins as int 
	iEATBalance += (zins as int) + (_00E_BankSystem_Beteiligungen.GetValue() as int) ; Enderal AllTogether: into your balance
	EATRestoreBalance()
	Transfer("null", "RecalculateZins")
	
	if REFdepositBox.GetItemCount(Gold) != 0
		RegisterForSingleUpdateGameTime(24)
		
		If !bDoneAchievement && REFdepositBox.GetItemCount(Gold) >= 100000
			Steam.UnlockAchievement("END_BANKACCOUNT_01")
			bDoneAchievement = true
		EndIf
	else
		Registered = false
	endif
	
ENDevent 

;=====================================================================================
;              				 ENDERAL ALLTOGETHER: PERSONAL BALANCE
;=====================================================================================

; The bank keeps your gold as items in a deposit box in the Ark bank vault. Skyrim Together syncs container contents
; when a player enters a cell, and whoever enters first decides them for everyone, so the box could be emptied by a
; partner's game (a 2500 gold deposit vanished). Your balance is now kept in your own save, and the box is put back to
; it before the bank reads it. Gold is personal in Skyrim Together, so the bank account is too.
; Deposits, withdrawals and interest change this balance; the box only mirrors it.
int iEATBalance = -1 ; -1: not recorded yet (save from before this fix)

Function EATRestoreBalance()
	int iBox = REFdepositBox.GetItemCount(Gold)
	If iEATBalance < 0
		; A save from before this fix that used the bank: the box is still this save's own, take it as the balance.
		; Never used here: the box may hold a partner's gold (synced when they entered the vault first), so start at 0.
		If Registered || ZinsHistory > 0 || Deposited > 0
			iEATBalance = iBox
		Else
			iEATBalance = 0
		EndIf
	EndIf
	If iEATBalance < 0
		iEATBalance = 0
	EndIf
	If iBox < iEATBalance
		REFdepositBox.AddItem(Gold, iEATBalance - iBox, true)
	ElseIf iBox > iEATBalance
		REFdepositBox.RemoveItem(Gold, iBox - iEATBalance, true)
	EndIf
EndFunction


;=====================================================================================
;              							 PROPERTIES                   					 
;=====================================================================================

bool bRestartDeposit
bool bRestartWithdraw
bool bDoneAchievement = false

bool Property bTransferInAction Auto Conditional Hidden

ObjectReference Property REFdepositBox Auto

Message Property _00E_Bank_NotEnoughMoneyWithdraw Auto
Message Property _00E_Bank_NotEnoughMoneyDeposit Auto

Message Property _00E_BankSystem_Deposit_Comfy Auto
Message Property _00E_BankSystem_Deposit_FallbackSelect  Auto  
Message Property _00E_BankSystem_Withdraw_FallbackSelect  Auto  
Message Property _00E_BankSystem_Withdraw_Comfy Auto
Message Property _00E_BankSystem_Root Auto

Sound Property SFXgoldDeposit Auto 
Sound Property SFXgoldWithdraw Auto 

GlobalVariable Property GLBcurrent Auto 
GlobalVariable Property _00E_BankSystem_Beteiligungen Auto
MiscObject Property Gold Auto 

ReferenceAlias Property Bankier Auto

int Property Created  Auto hidden
int Property Current  Auto hidden
int Property GetInput Auto hidden

Topic Property BankSystem_D0_PlayerDepositTopic Auto
Topic Property BankSystem_D0_PlayerWithdrawTopic Auto

float property Zins auto hidden
float property ZinsPercent auto hidden
float property Deposited auto hidden


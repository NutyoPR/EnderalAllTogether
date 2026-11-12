Scriptname _00E_DungeonLiftScript extends ObjectReference  
{Place this on a lift platform (and follow the tutorial in the comments!) to make a platform move when a trigger is activated.}

; Enderal AllTogether: Skyrim Together doesn't sync a lift's position, so each game kept its own UpDown and a replayed
; lever pull moved the lifts in opposite directions once they had drifted apart. Now only the player who pulls the lever
; moves it, and shares the TARGET position with the party: their games move the lift there (live), or put it there when
; they arrive later. Without the plugin this is the vanilla lift.

String Function LiftKey()
    return "lift:" + Self.GetFormID()
EndFunction

Event OnActivate(ObjectReference akActionRef)
    if akActionRef != Game.GetPlayer()  ; a replayed pull by the other player: their shared target moves it here
        return
    EndIf
    if doubleclick  ; already moving: a second pull mid-ride does nothing
        return
    EndIf
    Int iTarget = 1 - UpDown
    if EnderalAllTogether.IsLoaded()
        EnderalAllTogether.ShareValue(LiftKey(), iTarget)
    EndIf
    MoveLift(iTarget, True)
EndEvent

; aiTarget: 1 = top, 0 = bottom. abRider: this player pulled the lever (only their controls are locked).
Function MoveLift(Int aiTarget, Bool abRider)
    STR_Target = aiTarget
    if abRider && DisablePlayerControlsDuringRide == True
        STR_ControlsLockedHere = True
        Game.DisablePlayerControls()
    EndIf
    if aiTarget == 1
        LiftMarkerTop.SetAngle(self.GetAngleX(), self.GetAngleY(), self.GetAngleZ())
        self.TranslateToRef(LiftMarkerTop, MovementSpeed, 10.0)
    Else
        self.TranslateToRef(LiftMarkerBottom, MovementSpeed, 10.0)
        LiftMarkerBottom.SetAngle(self.GetAngleX(), self.GetAngleY(), self.GetAngleZ())
    EndIf
    if MechanicalLift == True
        MoveSound = _00E_SternenstadtLifeSoundMarker.Play(Self)
    Else
        MoveSound = DRSStoneRotatingDiscLPM.Play(Self)
    EndIf
    doubleclick = True
EndFunction

Event OnTranslationAlmostComplete()
    FinishRide()
    UpDown = STR_Target  ; where it was sent, not a toggle, so both games agree
    ; a party member's pull arrived while it was moving: follow it now
    if STR_Pending >= 0 && STR_Pending != UpDown
        Int iPending = STR_Pending
        STR_Pending = -1
        MoveLift(iPending, False)
    EndIf
    STR_Pending = -1
EndEvent

; The ride was interrupted (e.g. the cell unloaded): clean up without changing where the lift counts as being.
Event OnTranslationFailed()
    FinishRide()
EndEvent

Function FinishRide()
    if DisablePlayerControlsDuringRide == True && STR_ControlsLockedHere
        Game.EnablePlayerControls()
        STR_ControlsLockedHere = False
    EndIf
    Sound.StopInstance(MoveSound) ; Stops the loop Sound
    doubleclick = False
EndFunction

; Arriving in the cell: put the lift where the party left it.
Event OnCellAttach()
    RegisterForModEvent("EnderalAllTogether_Shared", "OnEnderalAllTogetherShared")
    if !EnderalAllTogether.IsLoaded() || doubleclick
        return
    EndIf
    Int iTarget = EnderalAllTogether.GetSharedValue(LiftKey(), -1)
    if iTarget == 1 && UpDown != 1
        LiftMarkerTop.SetAngle(self.GetAngleX(), self.GetAngleY(), self.GetAngleZ())
        self.MoveTo(LiftMarkerTop)
        UpDown = 1
    ElseIf iTarget == 0 && UpDown != 0
        LiftMarkerBottom.SetAngle(self.GetAngleX(), self.GetAngleY(), self.GetAngleZ())
        self.MoveTo(LiftMarkerBottom)
        UpDown = 0
    EndIf
EndEvent

Event OnCellDetach()
    UnregisterForModEvent("EnderalAllTogether_Shared")
EndEvent

; A party member pulled this lift's lever. A function rather than an Event (Caprica only accepts custom Event names in
; native scripts); the mod event calls it by name either way.
Function OnEnderalAllTogetherShared(String asEventName, String asKey, Float afValue, Form akSender)
    if asKey != LiftKey()
        return
    EndIf
    Int iTarget = afValue as Int
    if doubleclick
        STR_Pending = iTarget  ; follow it once the current ride ends
    ElseIf iTarget != UpDown
        MoveLift(iTarget, False)
    EndIf
EndFunction

Int STR_Target = 0
Int STR_Pending = -1
Bool STR_ControlsLockedHere = False

int UpDown ; 1 = Lift is at the top, 0 = Lift is at the bottom
int MoveSound
bool doubleclick = False ; True = player is activating while the lift is in
                         ; motion (hence, don't play sound again)
float Property MovementSpeed = 100.0 Auto
{How fast the platform should move - Start at 100.0 and work your way up! 1 is barely visible to the human eye.}
Bool Property DisablePlayerControlsDuringRide Auto
{Should the player controls be disabled once the switch has been hit?}
Bool Property MechanicalLift = False Auto ; Check this if the lift is mechanical
{Set this to true if the lift should play a mechanical sound instead of a "crumbling stone"-sound}
ObjectReference Property LiftMarkerTop Auto
{The X-Marker Reference where the lift will stop moving at the top}
ObjectReference Property LiftMarkerBottom Auto
{The X-Marker Reference where the lift will stop moving at the bottom (Set this XMarker's coordinates to match the platforms coordinates!}
Sound Property DRSStoneRotatingDiscLPM Auto
Sound Property _00E_SternenstadtLifeSoundMarker Auto


;"WICHTIG!

;- Lifte nirgendwo platzieren, wo es GEGNER gibt!
;- KEIN Navmesh auf der Liftplattform , da sich Navmesh nicht mitbewegt! Ergo keine Litftplattformen in Dungeons für Begleiter!


;TUTORIAL ZUM ERSTELLEN BEWEGBARER PLATTFORMEN!

;1.) Sucht das .nif des Objektes, das ihr als Plattform verwenden wollt
;2.) Öffnet es mit NifSkope
;3.) Ändert in den bhkRigidBody settings des Objektes folgendes:
;	- Layer: OL_STATIC in OL_ANIM_STATIC unändern
;	- Layer Copy: OL_STATIC in OL_ANIM_STATIC umändern
;	- Motion System: MO_SYS_BOX_STAILIZED in MO_SYS_BOX umändern
;4.) Speichert das .nif ab, unter dem Pfad meshes/Enderal/Dungeons/NameEuresObjektes.nif
;5.) Erstellt ein neues MoveableStatic mit dem Objekt als .nif
;6.) Legt dieses Skript auf die Referenz der Plattform, d.h. geht zu eurem Dungeon, platziert die Plattform, doppelklickt sie und geht zum Tab "Scripts" und fügt dieses Skript zu
;7.) Drückt auf Properties, drückt Auto-Fill, die Sound-Properties sollte nun gefüllt sein
;8.) Setzt die "DisablePlayer..." und "MechanicalLift" Properties auf TRUE wenn sie es sein sollen - Das heißt, wenn der Spieler sich während der Liftfahrt nicht bewegen können soll oder der Lift mechanisch ist.
;9.) Weißt dem LiftMarkerTop und dem LiftMarkerBottom jeweils zwei XMarker zu, die ihr an den Start und an den Endpunkten des Liftes platziert. Der Liftmarker Bottom sollte GENAU dieselben Koordinaten wie die Liftplattform
;	im Ursprungszustand haben
;10.) Nun platziert eine Kette, einen Hebel, oder eine Triggerbox (oder sonst etwas), mit dem der Lift aktiviert werden soll. Nun doppelklickt ihr den Lift und geht zum Tab "ActivateParents". Dort doppelklickt ihr
;	und wählt die Kette oder den Hebel aus.
; 11.) Alles sollte klappen. Hurra! :)@"
/*
DragToScroll.ahk

new discussion:
https://autohotkey.com/boards/viewtopic.php?f=6&t=38457

old discussion:
http://www.autohotkey.com/forum/viewtopic.php?t=59726
https://autohotkey.com/board/topic/55289-dragtoscroll-universal-drag-flingflick-scrolling/

Scroll any active window by clicking and dragging with the right mouse button. 
Should not interfere with normal right clicking. 
See the discussion link above for more information.

This script has one dependency, on Tuncay's ini lib, found at:
http://www.autohotkey.com/forum/viewtopic.php?t=46226

*/

#SingleInstance Force
#Persistent
#NoEnv
#NoTrayIcon
#Include %A_ScriptDir%\ini.ahk
GoSub, Init
Return

ApplySettings:
; Settings
;--------------------------------

; Global toggle. Should generally always be false
Setting("ScrollDisabled", false)

; The chosen hotkey button
; Should work with pretty much any button, though 
; mouse or KB special keys (ctrl, alt, etc) are preferred.
Setting("Button", "RButton")                

; Delay time before drag starts
; You must click and release "Button" before this time;
; Increase if you are having trouble getting "normal behavior"
Setting("DragDelay", 150)                     ; in ms. 

; How often to poll for mouse movement & drag
; The major time unit for this script, everything happens on this
; schedule. Affects script responsiveness, scroll speed, etc.
Setting("PollFrequency", 20)                  ; in ms

; Speed
; Affects the overall speed of scrolling before acceleration
; Speed is "normalized" to 1.0 as a default
Setting("DragThreshold", 0)                   ; in pixels
Setting("SpeedX", 0.5)
Setting("SpeedY", 1.0)

; MovementCheck
; if enabled, this check will abort dragging
; if you have not moved the mouse over MovementThreshold
; within the first MovementCheckDelay ms
; This is used for compatibility with other button-hold actions
Setting("UseMovementCheck", true)
Setting("MovementCheckDelay", 500)            ; in ms
Setting("MovementThreshold", 0)               ; in px

; scroll method
; choose one of: mWheelKey, mWheelMessage, mScrollMessage
; WheelMessage & WheelKey are preferred; your results may vary
Setting("ScrollMethodX", mWheelKey)
Setting("ScrollMethodY", mWheelKey)

; invert drag
; by default, you "drag" the document; moving up drags the document up,
; showing more of the document below. This behavior is the inverse of 
; scrolling up, where you see more of the document above.
; The invert flag switches the drag to the "scroll" behavior
Setting("InvertDrag", true)

; Edge Scrolling
; allows you to hover over a window edge
; to continue scrolling, at a fixed rate
Setting("UseEdgeScrolling", false)
Setting("EdgeScrollingThreshold", 15)         ; in px, distance from window edge
Setting("EdgeScrollSpeed", 2.0)               ; in 'speed'; 1.0 is about 5px/sec drag

; Targeting
; if Confine is enabled, drag will be immediately halted
; if the mouse leaves the target window or control
;
; it is advisable to not use BOTH confine and EdgeScrolling
; in that case, edge scrolling will only work if you
; never leave the bounds of the window edge
Setting("UseControlTargeting", true)
Setting("ConfineToWindow", false)
Setting("ConfineToControl", false)


; Acceleration & momentum
Setting("UseAccelerationX", true)
Setting("UseAccelerationY", true)
Setting("MomentumThreshold", 0.7)             ; in 'speed'. Minimum speed to trigger momentum. 1 is always
Setting("MomentumStopSpeed", 0.25)            ; in 'speed'. Scrolling is stopped when momentum slows to this value
Setting("MomentumInertia", .93)               ; (0 < VALUE < 1) Describes how fast the scroll momentum dampens
Setting("UseScrollMomentum", false)

; Acceleration function
; - modify very carefully!!
; - default is a pretty modest curve
;

; Based on the initial speed "arg", accelerate and return the updated value
; Think of this function as a graph of drag-speed v.s. scroll-speed.
;
Accelerate(arg)
{ 
  return .006 * arg **3 + arg
}

; double-click checking
;
; If enabled, a custom action can be performed a double-click is detected.
; Simply set UseDoubleClickCheck := true
; Define ButtonDoubleClick (below) to do anything you want
Setting("DoubleClickThreshold", DllCall("GetDoubleClickTime"))
Setting("UseDoubleClickCheck", false)

; Gesture checking
; 
; If enabled, simple gestures are detected, (only supports flick UDLR)
; and gesture events are called for custom actions, 
; rather than dragging with momentum.
Setting("UseGestureCheck", false)
Setting("GestureThreshold", 30)
Setting("GesturePageSize", 15)
Setting("GestureBrowserNames", "chrome.exe,firefox.exe,iexplore.exe")

; Change Mouse Cursor 
; If enabled, mouse cursor is set to the cursor specified below
Setting("ChangeMouseCursor", true)

; If the above ChangeMouseCursor setting is true, this determines what cursor style
; Choose either:
;       "cursorHand"           -  the original DragToScroll hand icon
;       "cursorScrollPointer"  -  the scrollbar and pointer icon (SYNTPRES.ico)
Setting("ChangedCursorStyle", "cursorScrollPointer")

; If enabled, cursor will stay in its initial position for the duration of the drag
; This can look jittery with the "cursorHand" style because it updates based
; on the PollFrequency setting above
Setting("KeepCursorStationary", true)
Return


; User-Customizable Handlers
;--------------------------------

; double-click handler
; this label is called by DoubleClickCheck
;
ButtonDoubleClick:
  ; change this to whatever you want to happen at Button double-click 
  ; default behavior below toggles "slow mode"
  
  ; close the menu that probably popped up   
  ; the extra "menu" popup is unavoidable. 
  ; You may however attempt to close it automatically 
  ; this may yield unintended results, sending a random {esc}
  Sleep 200
  Send {Esc}

  slowSpeed := .5
  bSlowMode := !bSlowMode
  Tooltip((bSlowMode ? "Slow" : "Fast") . " Mode")

  if (bSlowMode)
  {
    SpeedY *= slowSpeed
    SpeedX *= slowSpeed
  }
  else
  {
    SpeedY /= slowSpeed
    SpeedX /= slowSpeed
  }
Return

; Handlers for gesture actions
; The Up/Down gestures will scroll the page 
;
GestureU:
  if (WinProcessName = "AcroRd32.exe")
    Send, ^{PgDn}
  else if (Get("ScrollMethodY") = mWheelMessage)
    Loop, % GesturePageSize
      Scroll(-1 * (GesturePageSize-A_Index))
  else
    Send, {PgDn}
Return

GestureD:
  if (WinProcessName = "AcroRd32.exe")
    Send, ^{PgUp}
  else if (Get("ScrollMethodY") = mWheelMessage)
    Loop, % GesturePageSize
      Scroll((GesturePageSize-A_Index))
  else
    Send, {PgUp}
Return

GestureL:
  if WinProcessName in %GestureBrowserNames%
  {
    ToolTip("Back", 1)
    Send {Browser_Back}
  }
  else
    Send {Home}
Return

GestureR:
  if WinProcessName in %GestureBrowserNames%
  {
    ToolTip("Forward", 1)
    Send {Browser_Forward}
  }
  else
    Send {End}
Return


;--------------------------------
;--------------------------------
;--------------------------------
; END OF SETTINGS
; MODIFY BELOW CAREFULLY
;--------------------------------
;--------------------------------
;--------------------------------

; Init
;--------------------------------
Init:
  ;// make sure to get the correct coords from MouseGetPos when used on
  ;// a 2nd screen which uses a different scaling % inside Windows
  ;// https://www.autohotkey.com/boards/viewtopic.php?f=14&t=13810
  DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")

  CoordMode, Mouse, Screen
  Gosub, Constants
  Gosub, Reset
  Gosub, LoadLocalSettings
  
  ; initialize non-setting & non-reset vars
  ;ScrollDisabled := false
  DragStatus := DS_NEW
  TimeOfLastButtonDown := 0
  TimeOf2ndLastButtonDown:= 0
  TimeOfLastButtonUp := 0
  
  ; Initialize menus & Hotkeys
  Gosub, MenuInit
  
  ; Initialize icons
  Menu, Tray, Icon
  GoSub, TrayIconInit
  GoSub, UpdateTrayIcon

  ; Initialize GUI for new cursor
  if (ChangeMouseCursor) && (ChangedCursorStyle = "cursorScrollPointer")
  {
     Gui, 98: Add, Pic, x0 y0 vMyIconVar hWndMyIconHwnd 0x3, %A_ScriptDir%\SYNTPRES.ico      ; 0x3 = SS_ICON
     Gui, 98: Color, gray
     Gui, 98: +LastFound -Caption +AlwaysOnTop +ToolWindow
     WinSet, TransColor, gray
  }

Return

; Constants
;--------------------------------
Constants:
  VERSION = 2.5
  DEBUG = 0
  WM_HSCROLL = 0x114
  WM_VSCROLL = 0x115
  WM_MOUSEWHEEL = 0x20A
  WM_MOUSEHWHEEL = 0x20E
  WHEEL_DELTA = 120
  SB_LINEDOWN = 1
  SB_LINEUP = 0
  SB_LINELEFT = 0
  SB_LINERIGHT = 1
  X_ADJUST = .2     ; constant. normalizes user setting Speed to 1.0
  Y_ADJUST = .2     ; constant. normalizes user setting Speed to 1.0
  ;DragStatus
  DS_NEW = 0        ; click has taken place, no action taken yet
  DS_DRAGGING = 1   ; handler has picked up the click, suppressed normal behavior, and started a drag
  DS_HANDLED = 2    ; click is handled; either finished dragging, normal behavior, or double-clicked
  DS_HOLDING = 3    ; drag has been skipped, user is holding down button
  DS_MOMENTUM = 4   ; drag is finished, in the momentum phase
  INI_GENERAL := "General"
  INI_EXCLUDE = ServerSettings
  ; scroll method
  mWheelKey := "WheelKey"              ; simulate mousewheel
  mWheelMessage := "WheelMessage"      ; send WHEEL messages
  mScrollMessage := "ScrollMessage"    ; send SCROLL messages
  URL_DISCUSSION := "https://autohotkey.com/boards/viewtopic.php?f=6&t=38457"
Return


; Cleans up after each drag. 
; Ensures there are no false results from info about the previous drag
;
Reset:
  OldY=
  OldX=
  NewX=
  NewY=
  DiffX=
  DiffY=
  DiffXSpeed=
  DiffYSpeed=
  OriginalX=
  OriginalY=
  CtrlClass=
  WinClass=
  WinProcessName=
  WinHwnd=
  CtrlHwnd=
  NewWinHwnd=
  NewCtrlHwnd=
  Target=
Return


; Implementation
;--------------------------------

; Hotkey Handler for button down
;
ButtonDown:
Critical
; Critical forces a hotkey handler thread to be attended to handling any others.
; If not, a rapid click could cause the Button-Up event to be processed
; before Button-Down, thanks to AHK's pseudo-multithreaded handling of hotkeys.
;
; Thanks to 'Guest' for an update to these hotkey routines.
; This update further cleans up, bigfixes, and simplifies the updates.

   ; Initialize DragStatus, indicating a new click
   DragStatus := DS_NEW
   GoSub, Reset

   ; Keep track of the last two click times.
   ; This allows us to check for double clicks.
   ;
   ; Move the previously recorded time out, for the latest button press event.
   ; Record the current time at the last click
   ; The stack has only 2 spaces; older values are discarded.
   TimeOf2ndLastButtonDown := TimeOfLastButtonDown
   TimeOfLastButtonDown := A_TickCount

    ; Capture the original position mouse position
    ; Window and Control Hwnds being hovered over
    ; for use w/ "Constrain" mode & messaging
    ; Get class names, and process name for per-app settings
    MouseGetPos, OriginalX, OriginalY, WinHwnd, CtrlHwnd, 3
    MouseGetPos, ,,, CtrlClass, 1
    WinGetClass, WinClass, ahk_id %WinHwnd%
    WinGet, WinProcessName, ProcessName, ahk_id %WinHwnd%
    WinGet, WinProcessID, PID, ahk_id %WinHwnd%
    WinProcessPath := GetModuleFileNameEx(WinProcessID)

    ; Figure out the target
    if (UseControlTargeting && CtrlHwnd)
      Target := "Ahk_ID " . CtrlHwnd
    else if (WinHwnd)
      Target := "Ahk_ID " . WinHwnd
    else
      Target := ""
    
    ;ToolTip("Target: " . Target . "    ID-WC:" . WinHwnd . "/" . CtrlHwnd . "     X/Y:" . OriginalX . "/" . OriginalY . "     Class-WC:" . WinClass . "/" CtrlClass . "     Process:" . WinProcessPath)
    ;ToolTip("Process Name:" . WinProcessName . "Process:" . WinProcessPath)
    
    ; if we're using the WheelKey method for this window,
    ; activate the window, so that the wheel key messages get picked up
    if (Get("ScrollMethodY") = mWheelKey && !WinActive("ahk_id " . WinHwnd))
      WinActivate, ahk_id %WinHwnd%  
   
   ; Optionally start a timer to see if 
   ; user is holding but not moving the mouse
   if (Get("UseMovementCheck"))
     SetTimer, MovementCheck, % -1 * Abs(MovementCheckDelay)

   if (!Get("ScrollDisabled"))
   {
     ; if scrolling is enabled,
     ; schedule the drag to start after the delay.
     ; specifying a negative interval forces the timer to run once
     SetTimer, DragStart, % -1 * Abs(DragDelay)
   }
   else
     GoSub, HoldStart
Return

; Hotkey Handler for button up
;
ButtonUp:

  ; Check for a double-click
  ; DoubleClickCheck may mark DragStatus as HANDLED
  if (UseDoubleClickCheck)
    GoSub CheckDoubleClick

  ; abort any pending checks to click/hold mouse
  ; and release any holds already started.
  SetTimer, MovementCheck, Off
  if (DragStatus == DS_HOLDING && GetKeyState(Button))
      GoSub, HoldStop

  ; If status is still NEW (not already dragging, or otherwise handled),
  ; then the user has released before the drag threshold.
  ; Check if the user has performed a gesture.
  if (DragStatus == DS_NEW && UseGestureCheck)
    GoSub, GestureCheck
    
  ; If status is STILL NEW (not a gesture either)
  ; then user has quick press-released, without moving.
  ; Skip dragging, and treat like a normal click.
  if (DragStatus == DS_NEW)
    GoSub, DragSkip

  ; update icons & cursor
  ; done before handling momentum since we've already released the button
  GoSub UpdateTrayIcon
  if (ChangeMouseCursor)
  {
    RestoreSystemCursor()
    if (ChangedCursorStyle = "cursorScrollPointer")
      Gui, 98: Hide
  }

  ; check for and apply momentum
  if (DragStatus == DS_DRAGGING)
    GoSub, DragMomentum

  ; Always stop the drag.
  ; This marks the status as HANDLED,
  ; and cleans up any drag that may have started.
  GoSub, DragStop
Return

DisabledButtonDown:
  Send, {%Button% Down}
Return

DisabledButtonUp:
  Send, {%Button% Up}
Return

; Handler for dragging
; Checking to see if scrolling should take place
; for both horizontal and vertical scrolling.
;
; This handler repeatedly calls itself to continue
; the drag once it has been started. Dragging will continue
; until stopped by calling DragStop, halting the timmer.
;
DragStart:
  ; double check that the click wasn't already handled
  if (DragStatus == DS_HANDLED)
     return

  ; schedule the next run of this handler
  SetTimer, DragStart, % -1 * Abs(PollFrequency)

  ; if status is still NEW
  ; user is starting to drag
  ; initialize scrolling
  if (DragStatus == DS_NEW)
  {
    ; Update the status, we're dragging now
    DragStatus := DS_DRAGGING
    
    ; Update the cursor & trayicon
    SetTrayIcon(hIconDragging)
    if (ChangeMouseCursor)
    {
      if (ChangedCursorStyle = "cursorScrollPointer")
      {
        ;// show GUI with scrolling icon
        Gui, 98: Show, x%OriginalX% y%OriginalY% NoActivate
        Gui, 98: +LastFound
        WinSet, AlwaysOnTop, On
        ;// "hide" cursor by replacing it with blank cursor (from the AHK help file for DllCall command)
        VarSetCapacity(AndMask, 32*4, 0xFF)
        VarSetCapacity(XorMask, 32*4, 0)
        SetSystemCursor(DllCall("CreateCursor", "uint", 0, "int", 0, "int", 0, "int", 32, "int", 32, "uint", &AndMask, "uint", &XorMask))
      } 
      else
        SetSystemCursor(hIconDragging)
    }

    ; set up for next pass
    ; to find the difference (New - Old)
    OldX := OriginalX
    OldY := OriginalY
  }
  Else
  {
    ; DragStatus is now DRAGGING
    ; get the new mouse position and new hovering window
    MouseGetPos, NewX, NewY, NewWinHwnd, NewCtrlHwnd, 3

    ;ToolTip % "@(" . NewX . "X , " . NewY . "Y) ctrl_" . CtrlClass . "   win_" . WinClass . "     " . WinProcessName

    ; If the old and new HWNDs do not match,
    ; We have moved out of the original window.
    ; If "Constrain" mode is on, stop scrolling.
    if (ConfineToControl && CtrlHwnd != NewCtrlHwnd)
      GoSub DragStop
    if (ConfineToWindow && WinHwnd != NewWinHwnd)
      GoSub DragStop


    ; Calculate/Scroll - X
    ; Find the absolute difference in X values
    ; i.e. the amount the mouse moved in _this iteration_ of the DragStart handler
    ; If the distance the mouse moved is over the threshold,
    ; then scroll the window & update the coords for the next pass
    DiffX := NewX - OldX
    if (abs(DiffX) > DragThreshold)
    {
      SetTimer, MovementCheck, Off
      Scroll(DiffX, true)
      if (DragThreshold > 0) && (!KeepCursorStationary)
        OldX := NewX
    }

    ; Calculate/Scroll  - Y
    ; SAME AS X
    DiffY := NewY - OldY
    if (abs(DiffY) > DragThreshold)
    {
      SetTimer, MovementCheck, Off
      Scroll(DiffY)
      if (DragThreshold > 0) && (!KeepCursorStationary)
        OldY := NewY
    }

    if (KeepCursorStationary)
      MouseMove, OriginalX, OriginalY
    else if (ChangedCursorStyle = "cursorScrollPointer")
      Gui, 98: Show, x%NewX% y%NewY% NoActivate

    ; Check for window edge scrolling 
    GoSub CheckEdgeScrolling

    ; a threshold of 0 means we update coords
    ; and attempt to drag every iteration.
    ; whereas with a positive non-zero threshold,
    ; coords are updated only when threshold crossing (above)
    if (DragThreshold <= 0) && (!KeepCursorStationary)
    {
      OldX := NewX
      OldY := NewY
    }
  }
Return

; Handler for stopping and cleaning up after a drag is started
; We should always call this after every click is handled
;
DragStop:
  ; stop drag timer immediately
  SetTimer, DragStart, Off

  ; finish drag
  DragStatus := DS_HANDLED
Return


; Handler for skipping a drag
; This just passes the mouse click.
;
DragSkip:
     DragStatus := DS_HANDLED
     Send {%Button%}
Return

; Entering the HOLDING state
HoldStart:
  ; abort any pending drag, update status, start holding
  SetTimer, DragStart, Off
  DragStatus := DS_HOLDING
  Send, {%Button% Down}
  GoSub UpdateTrayIcon
  if (ChangeMouseCursor)
  {
    RestoreSystemCursor()
    if (ChangedCursorStyle = "cursorScrollPointer")
      Gui, 98: Hide
  }
Return

; Exiting the HOLDING state. 
; Should probably mark DragStatus as handled
HoldStop:
  DragStatus := DS_HANDLED
  Send {%Button% Up}
  GoSub UpdateTrayIcon
Return

; This handler allows a click-hold to abort dragging,
; if the mouse has not moved beyond a threshold
MovementCheck:
  Critical
  ; Calculate the distance moved, pythagorean thm
  MouseGetPos, MoveX, MoveY
  MoveDist := sqrt((OriginalX - MoveX)**2 + (OriginalY - MoveY)**2)

  ; if we havent moved past the threshold start hold
  if (MoveDist <= MovementThreshold)
    GoSub, HoldStart
  Critical, Off
Return

; Handler to apply momentum at DragStop
; This code continues to scroll the window if
; a "fling" action is detected, where the user drags
; and releases the drag while moving at a minimum speed
;
DragMomentum:

  ; Check for abort cases
  ;  momentum disabled
  ;  below threshold to use momentum
  if (abs(DiffYSpeed) <= MomentumThreshold)
    return
  if (!Get("UseScrollMomentum"))
    return

  ; passed checks, now using momentum
  DragStatus := DS_MOMENTUM
  
  ; Immediately stop dragging, 
  ; momentum should not respond to mouse movement
  SetTimer, DragStart, Off
  
  ; capture the speed when mouse released
  ; we want to gradually slow to scroll speed
  ; down to a stop from this initial speed
  mSpeed := DiffYSpeed * (Get("InvertDrag")?-1:1)

  Loop
  {
    ; stop case: status changed, indicating a user abort
    ; another hotkey thread has picked up execution from here
    ; simply exit, do not reset.
    if (DragStatus != DS_MOMENTUM)
      Exit
   
    ; stop case: momentum slowed to minum speed
    if (abs(mSpeed) <= MomentumStopSpeed)
      return
  
    ; for each iteration in the loop,
    ; reduce the momentum speed linearly
    ; scroll the window
    mSpeed *= MomentumInertia
    Scroll(mSpeed, false, "speed")

    Sleep % Abs(PollFrequency)
  }
Return

; Implementation of Scroll
;
; Summary:
;  This is the business end, it simulates input to scroll the window.
;  This handler is called when the mouse cursor has been click-dragged
;  past the drag threshold.
;
;  Arguments:
;  * arg
;   - measured in Pixels, can just pass mouse coords difference
;   - the sign determins direction: positive is down or right
;   - the magnitude determines speed
;  * horizontal
;   - Any non-zero/null/empty value 
;     will scroll horizontally instead of vertically
;  * format
;   - Used in some rare cases where passing in 'speed' instead of px
;
;  The goal is to take the amount dragged (arg), and convert it into
;  an appropriate amount of scroll in the window (Factor).
;  First we scale the drag-ammount, according to speed and acceleration
;  to the final scroll amount.
;  Then we scroll the window, according to the method selected.
;
Scroll(arg, horizontal="", format="px")
{
  global
  local Direction, Factor, Method, wparam

  ; get the speed and direction from arg arg
  Direction := ( arg < 0 ? -1 : 1 ) * ( Get("InvertDrag") ? -1 : 1 )
  Factor := abs( arg )
  
  ; Special "hidden" setting, for edge cases (visual studio 2010)
  if (horizontal && Get("InvertDragX"))
    Direction *= -1

  ; Do the math to convert this raw px measure into scroll speed
  if (format = "px")
  {
    ; Scale by the user-set scroll speed & const adjust
    if (!horizontal)
      Factor *= Get("SpeedY") * Y_ADJUST
    else
      Factor *= Get("SpeedX") * X_ADJUST
  
    ; Scale by the acceleration function, if enabled
    if (!horizontal && Get("UseAccelerationY"))
      Factor := Accelerate(Factor)
    if (horizontal && Get("UseAccelerationX"))
      Factor := Accelerate(Factor)
  }

  ;if (!horizontal) ToolTip, Speed: %arg% -> %Factor%

  ; Capture the current speed
  if (!horizontal)
    DiffYSpeed := Factor * Direction
  else
    DiffXSpeed := Factor * Direction

  ; Get the requested scroll method    
  if (!horizontal)
    Method := Get("ScrollMethodY")
  else
    Method := Get("ScrollMethodX")
    
  ; Do scroll
  ;  According to selected method
  ;  wparam is used in all methods, as the final "message" to send.
  ;  All methods check for direction by comparing (NewY < OldY)
  if (Method = mWheelMessage)
  {
    ; format wparam; one wheel tick scaled by yFactor
    ; format and send the message to the original window, at the original mouse location
    wparam := WHEEL_DELTA * Direction * Factor
    ;ToolTip, %arg% -> %factor% -> %wparam%
    if (!horizontal)
      PostMessage, WM_MOUSEWHEEL, (wparam<<16), (OriginalY<<16)|OriginalX,, %Target%
    else
    {
      wparam *= -1 ; reverse the direction for horizontal
      PostMessage, WM_MOUSEHWHEEL, (wparam<<16), (OriginalY<<16)|OriginalX,, %Target%
    }
  }
  else if (Method = mWheelKey)
  {
    ; format wparam; either WheelUp or WheelDown
    ; send as many messages needed to scroll at the desired speed
    if (!horizontal)
      wparam := Direction < 0 ? "{WheelDown}" : "{WheelUp}"
    else
      wparam := Direction < 0 ? "{WheelRight}" : "{WheelLeft}"
      
    Loop, %Factor%
      Send, %wparam%
  }
  else if (Method = mScrollMessage)
  {
    ; format wparam; either LINEUP, LINEDOWN, LINELEFT, or LINERIGHT
    ; send as many messages needed to scroll at the desired speed
    if (!horizontal)
    {
      wparam := Direction < 0 ? SB_LINEDOWN : SB_LINEUP
      Loop, %Factor%
        PostMessage, WM_VSCROLL, wparam, 0,, Ahk_ID %CtrlHwnd%
    }
    else
    {
      wparam := Direction < 0 ? SB_LINERIGHT : SB_LINELEFT
      Loop, %Factor%
        PostMessage, WM_HSCROLL, wparam, 0,, Ahk_ID %CtrlHwnd%
    }
  }
}

; Handler to check for a double-click of the right mouse button
; (press-release-press-release), quickly.
; This is called every time the button is released.
;
; We assume that if the mouse button was released,
; then it had to be pressed down to begin with (reasonable?);
; this should be handled by AHK's 'Critical' declaration.
;
CheckDoubleClick:
   if (!UseDoubleClickCheck)
     return

   ; Record latest button release time and
   ; Calculate difference between previous click-release and re-click
   ; if the difference is below the threshold, treat it as a double-click
   TimeOfLastButtonUp := A_TickCount
   DClickDiff := TimeOfLastButtonUp - TimeOf2ndLastButtonDown
   if (DClickDiff <= DoubleClickThreshold)
   {
      ; Mark the status as Handled,
      ; so the user-configurable ButtonDoubleClick doesn't have to
      ; Call the user defined function.
      DragStatus := DS_HANDLED
      GoSub ButtonDoubleClick
   }
Return


; Handler to check for edge scrolling
; Activated when the mouse is dragging and stops
; within a set threshold of the window's edge
; Causes the window to keep scrolling at a set rate
;
CheckEdgeScrolling:
  if (!Get("UseEdgeScrolling"))
    return

  ; Get scrolling window position
  WinGetPos, WinX, WinY, WinWidth, WinHeight, ahk_id %WinHwnd%
  ; Find mouse position relative to the window
  WinMouseX := NewX - WinX
  WinMouseY := NewY - WinY

  ; find which edge we're closest to and the distance to it
  InLowerHalf :=  (WinMouseY > WinHeight/2)
  EdgeDistance := (InLowerHalf) ? Abs( WinHeight - WinMouseY ) : Abs( WinMouseY )
  ;atEdge := (EdgeDistance <= EdgeScrollingThreshold ? " @Edge" : "")         ;debug 
  ;ToolTip, %WinHwnd%: %WinMouseY% / %WinHeight% -> %EdgeDistance%  %atEdge%  ;debug

  ; if we're close enough, scroll the window
  if (EdgeDistance <= EdgeScrollingThreshold)
  {
    ; prep and call scrolling
    ; the second arg requests the scroll at the set speed without accel
    arg := (InLowerHalf ? 1 : -1) * (Get("InvertDrag") ? -1 : 1) * Get("EdgeScrollSpeed")
    Scroll(arg, false, "speed")
  }
Return


; Handler to check for gesture actions
; This handler only supports simple "flick" gestures; 
; because the whole gesture needs to be completed before DragThreshold,
; and also makes the logic easy, by a simple threshold
;
GestureCheck:
  MouseGetPos, MoveX, MoveY
  MoveAmount := (abs(OriginalY-MoveY) >= abs(OriginalX-MoveX)) ? OriginalY-MoveY : OriginalX-MoveX
  MoveDirection := (abs(OriginalY-MoveY) >= abs(OriginalX-MoveX)) ? (OriginalY>MoveY ? "U" : "D") : (OriginalX>MoveX ? "L" : "R")

  ; If the move amount is above the threshold,
  ; Immediately stop/cancel dragging and call the correct gesture handler  
  if (abs(MoveAmount) >= GestureThreshold)
  {
    GoSub, DragStop
    GoSub, Gesture%MoveDirection%
  }
Return


; Settings Functions
;--------------------------------

; A wrapper around the GetSetting function.
; Returns the ini GetSetting value, or the
; in-memory global variable of the same name.
;
; Provides and easy and seamless wrapper to 
; overlay user preferences on top of app settings.
;
Get(name, SectionName="")
{
  global
  local temp

  if (DEBUG)
  {
    temp := %name%
    return temp    
  }
  
  temp := GetSetting(name, SectionName)
  if (temp != "")
    return temp
  else
  {
    temp := %name%
    return temp    
  }
}

; Retrieves a named setting from the global ini
; This function operates both as a "search" of
; the ini, as well as a named get. You can optionally
; specify a section name to retrieve a specific value.
;
; By Default, this searches the ini file in any of
; a set of valid SectionNames. The default section 'General'
; is a last resort, if an app specific setting was not found.
; Section names are searched for the target control class,
; window class, and process name. If any of these named sections
; exist in ini, its key value is returned first.
;
GetSetting(name, SectionName="")
{
  global INI_GENERAL
  global CtrlClass, WinClass, WinProcessName, WinProcessPath
  global ini, ConfigSections
  
  ; find the section, using the cached list
  if (!SectionName)
  {
    ; by control class
    IfNotEqual, CtrlClass
      If CtrlClass in %ConfigSections%
        SectionName := CtrlClass
    ; by window class
    IfNotEqual, WinClass
      If WinClass in %ConfigSections%
        SectionName := WinClass
    ; by process name
    IfNotEqual, WinProcessName
      If WinProcessName in %ConfigSections%
        SectionName := WinProcessName
    ; by process path
    IfNotEqual, WinProcessPath, 
      If WinProcessPath in %ConfigSections%
        SectionName := WinProcessPath
    
    ; last chance
    if (!SectionName)
      SectionName := INI_GENERAL
  }

  ;get the value
  temp := ini_getValue(ini, SectionName, name)
  
  ; check for special keywords
  if (temp = "false")
    temp := 0
  if (temp = "true")
    temp := 1

  ;if (SectionName != INI_GENERAL)
  ;  ToolTip, % "Request " . name . ":`n" . ini_getSection(ini, SectionName)
   
  return temp
}

; Saves a setting/variable to the ini file
; in the given section name (default General)
; with the given value, or the current variable value
;
SaveSetting(name, value="", SectionName="General")
{
  ; prep value
  global
  local keyList, temp

  if (SectionName = "")
  {
    MsgBox, 16, DtS, Setting Save Failed `nEmpty SectionName
    return
  }
    
  keyList := ini_getAllKeyNames(ini, SectionName)
  if (!value)
    value := %name%
    
  ; if no section
  if SectionName not in %ConfigSections%
  {
    if (!ini_insertSection(ini, SectionName, name . "=" . value))
    {
      MsgBox, 16, DtS, Setting Save Failed `ninsertSection %ErrorLevel%
      return
    }
    ConfigSections := ini_getAllSectionNames(ini)
  }
  ; if no value
  else if name not in %keyList%
  {
    if (!ini_insertKey(ini, SectionName, name . "=" . value))
    {
      MsgBox, 16, DtS, Setting Save Failed `ninsertKey %ErrorLevel%
      return
    }
  }
  ; value exists, Update
  else
  {
    if (!ini_replaceValue(ini, SectionName, name, value))
    {
      MsgBox, 16, DtS, Setting Save Failed `nreplaceValue %ErrorLevel%
      return
    }
  }
  
  ; finally save the setings
  ini_save(ini)
  if (ErrorLevel)
    MsgBox, 16, DtS, Settings File Write Failed
}

; An initialization function for settings
; The given variable name should be created
; with the value loaded from ini General Section
; or, if not set, the provided default 
;
Setting(variableName, defaultValue)
{
  global
  local value

  %variableName%_d := defaultValue

  if variableName not in %SettingsList%
    SettingsList .= (SettingsList != "" ? "," : "") . variableName

  value := GetSetting(variableName, INI_GENERAL)
  if (value != "")
    %variableName% := value
  else
    %variableName% := defaultValue
}

; check and reload of settings
;
LoadLocalSettings:
  Critical
  ini_load(temp)
  changed := (temp != ini)
  
  if (temp = "" && SettingsList = "")
    GoSub, ApplySettings
  
  if (A_ThisMenuItem != "")
    ToolTip("Reloading Settings..." . (changed ? " Change detected." : ""))

  if (!changed || temp = "")
    return

  ; apply new ini
  ini := temp
  GoSub, LoadLocalSettingSections
  GoSub, ApplySettings
  Critical, Off
Return
 
LoadLocalSettingSections:
    ; apply new config sections
    ConfigSections=
    ConfigProfileSections=
    temp := ini_getAllSectionNames(ini)
    Loop, Parse, temp, `,
    {
      ConfigSections .= (ConfigSections != "" ? "," : "") . A_LoopField
      if A_LoopField not in %INI_EXCLUDE%
        ConfigProfileSections .= (ConfigProfileSections != "" ? "," : "") . A_LoopField
    }
Return

;
; Retrieve the full path of a process with ProcessID
; thanks to HuBa & shimanov
; http://www.autohotkey.com/forum/viewtopic.php?t=18550
;
GetModuleFileNameEx(ProcessID)  ; modified version of shimanov's function
{
  if A_OSVersion in WIN_95, WIN_98, WIN_ME
    Return
 
  ; #define PROCESS_VM_READ           (0x0010)
  ; #define PROCESS_QUERY_INFORMATION (0x0400)
  hProcess := DllCall( "OpenProcess", "UInt", 0x10|0x400, "Int", False, "UInt", ProcessID)
  if (ErrorLevel or hProcess = 0)
    Return
  FileNameSize := 260 * (A_IsUnicode ? 2 : 1)
  VarSetCapacity(ModuleFileName, FileNameSize, 0)
  CallResult := DllCall("Psapi.dll\GetModuleFileNameEx", "Ptr", hProcess, "Ptr", 0, "Str", ModuleFileName, "UInt", FileNameSize)
  DllCall("CloseHandle", "Ptr", hProcess)
  Return ModuleFileName
}

; Settings Gui : App Settings
;--------------------------------

GuiAppSettings:
  if (!GuiAppBuilt)
    GoSub, GuiAppSettingsBuild
  Gui, 2:Show,, DtS App Settings
  GoSub, GuiAppSectionLoad
  Return
  
  GuiAppSettingsBuild:
  GuiAppBuilt := true
  Gui +Delimiter|
  Gui, 2:Default
  Gui, Add, Text, x10 y5, Process name (chrome.exe) or window class:
  Gui, Add, ComboBox, x10 y20 w225 h20 r10 vGuiAppSection gGuiAppSectionChange
  Gui, Add, Button, x240 y20 w20 h20 gGuiAppSectionRemove , -
  Gui, Add, GroupBox, x10 y42 w250 h76 , Scroll Method
  Gui, Add, Text, x20 y63 w10 h10 , Y
  Gui, Add, Text, x20 y93 w10 h10 , X
  Gui, Add, DropDownList, x32 y60 w218 h20 r3 Choose1 vGuiScrollMethodY , WheelMessage|WheelKey|ScrollMessage
  Gui, Add, DropDownList, x32 y90 w218 h20 r3 Choose1 vGuiScrollMethodX , WheelMessage|WheelKey|ScrollMessage
  
  Gui, Add, GroupBox, x10 y120 w250 h80 , Speed && Acceleration
  Gui, Add, Text, x20 y143 w10 h20 , Y
  Gui, Add, Edit, x30 y140 w40 h20 vGuiSpeedY
  Gui, Add, UpDown
  Gui, Add, CheckBox, x75 y140 w50 h20 vGuiUseAccelerationY , Accel
  Gui, Add, Text, x140 y143 w10 h20 , X
  Gui, Add, Edit, x150 y140 w40 h20 vGuiSpeedX
  Gui, Add, UpDown
  Gui, Add, CheckBox, x195 y140 w50 h20 vGuiUseAccelerationX , Accel
  Gui, Add, CheckBox, x20 y165 w100 h20 vGuiUseEdgeScrolling , Edge Scrolling
  Gui, Add, Edit, x150 y170 w40 h20 vGuiEdgeScrollSpeed
  Gui, Add, UpDown
  Gui, Add, Text, x195 y168 w60 r2, Edge Speed
  
  Gui, Add, GroupBox, x10 y200 w250 h110 , Options
  Gui, Add, CheckBox, x20 y220 w170 h20 vGuiScrollDisabled , Scroll Disabled
  Gui, Add, CheckBox, x20 y240 w170 h20 vGuiUseScrollMomentum , Scroll Momentum
  Gui, Add, CheckBox, x20 y260 w170 h20 vGuiInvertDrag , Invert Drag
  Gui, Add, CheckBox, x20 y280 w170 h20 vGuiUseMovementCheck , Movement Check
  Gui, Add, Button, x10 y315 w120 h30 Default gGuiAppApply , Apply
  Gui, Add, Button, x140 y315 w120 h30 gGuiClose , Close
Return

GuiAppSectionLoad:
  Gui, +Delimiter`,
  GuiControlGet, temp,, GuiAppSection
  GuiControl, , GuiAppSection, % "," . ConfigProfileSections
  if temp in %ConfigProfileSections%
    GuiControl, ChooseString, GuiAppSection, %temp%
  else
    GuiControl, Choose, GuiAppSection, 1
  GoSub, GuiAppSectionChange
Return

GuiAppSectionRemove:
  GuiControlGet, GuiAppSection
  if (GuiAppSection = INI_GENERAL)
  {
    Msgbox, 16, DtS Configuration, Cannot delete the general settings section
    Return
  }
  MsgBox, 36, DtS Configuration, Are you sure you want to delete settings for this section?`n  %GuiAppSection%
  IfMsgBox, Yes
  {
    ini_replaceSection(ini, GuiAppSection)
    ini_save(ini)
    GoSub, LoadLocalSettingSections
    GoSub, GuiAppSectionLoad
  } 
Return

GuiAppSectionChange:
  GuiControlGet, GuiAppSection
  if (GuiAppSection not in ConfigProfileSections)
    return
  ;DDLs
  temp=ScrollMethodX,ScrollMethodY
  Loop, Parse, temp, `,
    GuiControl, Choose, Gui%A_LoopField%, % Get(A_LoopField, GuiAppSection)
  ;Checkboxes & Edit boxes
  temp=UseAccelerationX,UseAccelerationY,UseEdgeScrolling,ScrollDisabled,UseScrollMomentum,InvertDrag,UseMovementCheck,SpeedX,SpeedY,EdgeScrollSpeed
  Loop, Parse, temp, `,
    GuiControl,, Gui%A_LoopField%, % Get(A_LoopField, GuiAppSection)
Return

GuiAppApply:
  GuiControlGet, GuiAppSection
  if (GuiAppSection = "")
  {
    MsgBox, Type in an application's process name, or window class, or process path
    GuiControl, Focus, GuiAppSection
    return
  }
  temp=ScrollMethodX,ScrollMethodY,UseAccelerationX,UseAccelerationY,UseEdgeScrolling,ScrollDisabled,UseScrollMomentum,InvertDrag,UseMovementCheck,SpeedX,SpeedY,EdgeScrollSpeed
  Loop, Parse, temp, `,
  {
    GuiControlGet, value,, Gui%A_LoopField%
    SaveSetting(A_LoopField, value, GuiAppSection)
  }
  
  GoSub, LoadLocalSettingSections
  GoSub, GuiAppSectionLoad
Return


; Settings Gui : All Settings
;--------------------------------

GuiAllSettings:
  if (!GuiAllBuilt)
    GoSub, BuildGuiAllSettings
  Gui, 3:Show,, DtS All Settings
  Return
  
  BuildGuiAllSettings:
  GuiAllBuilt := true
  Gui, 3:Default
  wSp := 5, wCH := 20, wCW := 150, wOffset := 60, wCX := wSp*2 + wCW, wCX2 := wSp*4 + wCW*2, wCX3 := wSp*5 + wCW*3
  Gui, Add, Text, x%wSp% y%wSp%, This lists all settings registered with this script. `nChanging values and pressing 'Ok' immediately updates the setting in memory, `nand writes your changes to the ini General section
  Loop, Parse, SettingsList, `,
  {
    if (A_LoopField = "")
      continue

    temp := A_LoopField . "_d"
    color := ( %A_LoopField% == %temp% ? "" : "cBlue")
    temp := %A_LoopField%

    left := !left    
    if (left)
    {
      Gui, Add, Text, x%wSp% y%wOffset% w%wCW% h%wCH% right, %A_LoopField%
      Gui, Add, Edit, x%wCX% y%wOffset% w%wCW% h%wCH% center %color% v%A_LoopField% gGuiAllEvent, %temp%
    }
    else
    {
      Gui, Add, Text, x%wCX2% y%wOffset% w%wCW% h%wCH% right, %A_LoopField%
      Gui, Add, Edit, x%wCX3% y%wOffset% w%wCW% h%wCH% center %color% v%A_LoopField% gGuiAllEvent, %temp%
      wOffset += wCH + wSp
    }
  }
  
  if (left)
    wOffset += wCH + wSp * 3
  else
    wOffset += wSp * 2
    
  Gui, Font, bold
  Gui, Add, Button, x%wCX% y%wOffset% w%wCW% h%wCH% Default gGuiAllOk, Ok
  Gui, Add, Button, x%wCX2% y%wOffset% w%wCW% h%wCH% gGuiClose, Cancel
  wOffset += wCH + wSp
Return

GuiAllEvent:
  GuiControlGet, value,, %A_GuiControl%
  temp := A_GuiControl . "_d"
  temp := %temp%

  if (temp != value)
    GuiControl, +cBlue, %A_GuiControl%
  else
    GuiControl, +cDefault, %A_GuiControl%
Return

GuiAllOk:
  GuiControlGet, temp, ,Button
  Hotkey, %temp%,, UseErrorLevel
  if ErrorLevel in 5,6
  {
    HotKey, %Button%, Off
    HotKey, %Button% Up, Off
    HotKey, ^%Button%, Off
    HotKey, ^%Button% Up, Off
  }
  
  Gui, Submit
  Loop, Parse, SettingsList, `,
  {
    if (A_LoopField = "")
      continue
    SaveSetting(A_LoopField)
  }
  GoSub, mnuEnabledInit
Return

GuiClose:
  Gui, %A_Gui%:Cancel
Return


; Menu
;--------------------------------

; This section builds the menu of system-tray icon for this script
; MenuInit is called in the auto-exec section of this script at the top.
;
MenuInit:

;
; SCRIPT SUBMENU
;

Menu, mnuScript, ADD, Reload, mnuScriptReload
Menu, mnuScript, ADD, Reload Settings, LoadLocalSettings

Menu, mnuScript, ADD, Debug, mnuScriptDebug

Menu, mnuScript, ADD
if (!A_IsCompiled)
  Menu, mnuScript, ADD, Open/Edit Script, mnuScriptEdit
Menu, mnuScript, ADD, Open Directory, mnuScriptOpenDir
Menu, mnuScript, ADD, Open Settings File,  mnuScriptOpenSettingsIni
IfExist, Readme.txt
  Menu, mnuScript, ADD, Open Readme, mnuScriptOpenReadme
Menu, mnuScript, Add, Open Discussion, mnuScriptOpenDiscussion

;
; SETTINGS SUBMENU
;

Menu, mnuSettings, ADD, All Settings, GuiAllSettings
Menu, mnuSettings, ADD, App Specific Settings, GuiAppSettings


  
;
; TRAY MENU
;

; remove standard, and add name (w/ reload)
Menu, Tray, NoStandard
Menu, Tray, ADD, Drag To Scroll v%VERSION%, mnuEnabled
Menu, Tray, Default, Drag To Scroll v%VERSION%
Menu, TRAY, ADD

; Enable/Disable
; Add the menu item and initialize its state
Menu, Tray, ADD, Enabled, mnuEnabled
GoSub, mnuEnabledInit

; submenus
Menu, Tray, ADD, Script, :mnuScript
Menu, TRAY, ADD, Settings, :mnuSettings

; exit
Menu, TRAY, ADD
Menu, TRAY, ADD, Exit, mnuExit


Return


; Menu Handlers
;--------------------------------

; Simple menu handlers for 'standard' replacements
mnuScriptReload:
  Reload
Return

mnuScriptDebug: 
  ListLines
Return

mnuScriptOpenDir: 
  Run, %A_ScriptDir%
Return

mnuScriptEdit:
  Edit
Return

mnuScriptOpenSettingsIni:
  IfExist, DragToScroll.ini
    Run DragToScroll.ini
  Else
    MsgBox, 16, DtS, DragToScroll.ini not found...
Return

mnuScriptOpenReadme:
  IfExist, Readme.txt
    Run, Readme.txt
  Else
    MsgBox, 16, DtS, Readme.txt not found...
Return

mnuScriptOpenDiscussion:
  Run, %URL_DISCUSSION%
Return

mnuExit:
  ExitApp
Return


; This section defines the handlers for these above menu items
; Each handler has an inner 'init' label that allows the handler to
; both to set the initial value and to change the value, keeping the menu in sync.
; Each handler either sets, or toggles the associated property
;

mnuEnabled:
  ScrollDisabled := !ScrollDisabled
  ToolTip("Scrolling " . (ScrollDisabled ? "Disabled" : "Enabled"), 1)
  GoSub, DragStop ; safety measure. force stop all drags
  mnuEnabledInit:
  if (!ScrollDisabled)
  {
    Menu, TRAY, Check, Enabled
    Menu, TRAY, tip, Drag To Scroll v%VERSION%
    HotKey, %Button%, ButtonDown, On
    HotKey, %Button% Up, ButtonUp, On
    HotKey, ^%Button%, DisabledButtonDown, On
    HotKey, ^%Button% Up, DisabledButtonUp, On
    HotKey, ~LButton, ToolTipCancel, On
  }
  else
  {
    Menu, TRAY, Uncheck, Enabled
    Menu, TRAY, tip, Drag To Scroll v%VERSION% (Disabled)
    HotKey, %Button%, Off
    HotKey, %Button% Up, Off
    HotKey, ^%Button%, Off
    HotKey, ^%Button% Up, Off
  }
   
  Gosub, UpdateTrayIcon
Return

; Icons
;--------------------------------
; The following section contains HEX data and code to load+parse data & set tray icons 
; adapted from http://www.autohotkey.com/forum/topic33955.html
;
TrayIconInit:
  ; ENABLED icon data
  IconEnabledHex =
  ( join
00000100010010100000010020006804000016000000280000001000000020000000010020000000000000000000130B000
0130B000000000000000000000000000000000000000000000000000000000000E3E3E30C9999994D4D4D4D9A393939C62E
2E2ED33F3F3FBB53535390A7A7A73E606060070000000000000000000000000000000000000000AEAEAE03B3B3B33E40404
0C75A5A5AFFACACACFFDCDCDCFFE7E7E7FFD5D5D5FFA2A2A2FF494949FF5B5B5BA0EBEBEB12000000000000000000000000
C6C6C6038F8F8F63313131FABABABAFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF717171FF525
252AAC5C5C50500000000000000009797975F333333FFE6E6E6FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFF414141FFB1B1B14700000000ACACAC492C2C2CF9DFDFDFFFFFFFFFFFFDFDFDFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA4A4A4FF4444449ACBCBCB2C333333E6C8C8C8FFFFFF
FFFFC3C3C3FF969696FECCCCCCFDFCFCFCFEFAFAFAFEFFFFFFFFFFFFFFFFEAEAEAFEBDBDBDFDFBFBFBFFD7D7D7FF141414B
B363636A7919191FFFFFFFFFFB4B4B4FF454545D93F3F3FD4B7B7B7FED3D3D3FC848484FC9A9A9AFC989898FD717171FC6B
6B6BFAFFFFFFFEDEDEDEFF111111C122222270656565F88A8A8AFF535353CE5858583F444444B1EAEAEAFFE2E2E2FD95959
5FC838383FB898989FB9B9B9BFDB0B0B0FCDEDEDEFEE0E0E0FF121212C0333333044141415A5151516A7F7F7F2D00000000
0E0E0EC1DFDFDFFFD6D6D6FFC9C9C9FDFFFFFFFE969696FBFFFFFFFF7D7D7DFAA2A2A2FDE7E7E7FF121212BF00000000000
000000000000000000000000000001B1B1BC1E7E7E7FF969696FF6C6C6CFCFFFFFFFD2C2C2CFCFFFFFFFE717171FB9F9F9F
FEE8E8E8FF121212BF00000000000000000000000000000000000000001B1B1BC1E8E8E8FF999999FF717171FCFFFFFFFE3
63636FCFFFFFFFE747474FBA6A6A6FEEEEEEEFF121212C100000000000000000000000000000000000000001E1E1EC1E8E8
E8FF9A9A9AFF727272FCFFFFFFFE373737FCFFFFFFFE757575FB878787FFC3C3C3FF111111C100000000000000000000000
00000000000000000232323C4EEEEEEFFA0A0A0FF727272FCFFFFFFFE383838FCFFFFFFFE808080FE181818E55C5C5CD237
3737510000000000000000000000000000000000000000454545AF808080FF525252FF777777FCFFFFFFFD323232FCFDFDF
DFF6F6F6FFF535353684040401A424242030000000000000000000000000000000000000000D6D6D62766666686393939AE
616161FFE1E1E1FF171717F8454545F42B2B2BC8D4D4D415000000000000000000000000000000000000000000000000000
000000000000069696905E2E2E212535353AA262626DC95959566B4B4B41861616111000000000000000000000000F80700
00F0010000E0010000C00000008000000000000000000000000000000098000000F8000000F8000000F8000000F8000000F
8030000F8030000FE070000
  )
  ; Load above data into a handle, hIconEnabled
  hIconEnabled := CreateIconResource(IconEnabledHex)
  IconEnabledHex := ""
  

  ; DISABLED icon data
  IconDisabledHex =
  ( join
00000100010010100000010020006804000016000000280000001000000020000000010020000000000000000000130B000
0130B000000000000000000000606CA230606CA5C000000000000000000000000E3E3E30C9999994D4D4D4D9A393939C62E
2E2ED33F3F3FBB53535390A7A7A73E6060600700000000000000000606CA5C0606CADA0606CA2B7C7CB405B4B4B33E40404
0C75A5A5AFFACACACFFDCDCDCFFE7E7E7FFD5D5D5FFA2A2A2FF494949FF5B5B5BA0EBEBEB12000000000000C8220000C9C8
0606D0EB6666B476353533FABBBBBBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF717171FF525
252AAC5C5C505000000003D3DD7080909A4E60000B9FFA0A0DBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFF414141FFB1B1B14700000000BFBFAD463A3A3BEB5757D8FF1212D8FFA7A7EDFFFEFEFBFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA4A4A4FF4444449ACBCBCB2C333333E6C9C9C7FFFFFF
FFFF3737ACFF0000C4FF8686DBFEFCFCFAFEFBFBF9FEFFFFFFFFFFFFFFFFEAEAEAFEBDBDBDFDFBFBFBFFD7D7D7FF141414B
B363636A7919191FFFFFFFFFFB7B7B5FF57574FD932329DE00000C6FF7878D8FE939394FC9D9D9AFC989898FD717171FC6B
6B6BFAFFFFFFFEDEDEDEFF111111C122222270656565F88A8A8AFF535353CE5959573F42423DB37C7CD4FF0505CFFF15158
7FD828284FB8A8A86FB9B9B9BFDB0B0B0FCDEDEDEFEE0E0E0FF121212C0333333044141415A5151516A7F7F7F2D00000000
0F0F0DC1EAEAE1FF7070BEFF0D0DD4FF6D6DEAFF939398FCFFFFFFFF7D7D7DFAA2A2A2FDE7E7E7FF121212BF00000000000
000000000000000000000000000001B1B1BC1E9E9E8FFA4A49BFF50508FFD0909CBFF090994FEF2F2FCFE74746FFA9F9F9F
FEE8E8E8FF121212BF00000000000000000000000000000000000000001B1B1BC1E8E8E8FF9A9A99FF77776EFCBDBDF0FE0
707C4FF3D3DD5FF6A6A7CFBA9A9A4FEEEEEEEFF121212C100000000000000000000000000000000000000001E1E1EC1E8E8
E8FF9A9A9AFF727272FCFFFFFFFE2D2D56FC1E1ECFFF1919BBFE717188FFC5C5BFFF111111C100000000000000000000000
00000000000000000232323C4EEEEEEFFA0A0A0FF727272FCFFFFFFFE393933FCDADAF8FE1A1AC1FF1212BBFF4C4C79D13B
3B2D4B0000000000000000000000000000000000000000454545AF808080FF525252FF777777FCFFFFFFFD323232FCFFFFF
EFF616177FF0404C1DB0909BBF91111B6430000000000000000000000000000000000000000D6D6D62766666686393939AE
616161FFE1E1E1FF171717F8454545F42D2D2AC8C9C9DA240505CCBA0505CDA400000000000000000000000000000000000
000000000000069696905E2E2E212535353AA262626DC95959566B4B4B41861616111000000000606CA360606CA3E380700
001001000000010000800000008000000000000000000000000000000098000000F8000000F8000000F8000000F8000000F
8000000F8000000FE040000
  )
  ; Load above data into a handle, hIconDisabled
  hIconDisabled := CreateIconResource(IconDisabledHex)
  IconDisabledHex := ""
  
  
  ; DRAGGING icon data
  IconDraggingHex =
  ( join
00000100010010100000010020006804000016000000280000001000000020000000010020000000000000000000130B000
0130B00000000000000000000000000000000000000000000000000000000000098989804A1A1A15C4D4D4DAB353535D528
2828E03C3C3CCB515151A1A7A7A74A000000000000000000000000000000000000000000000000000000021111117927272
7D8616161FFB0B0B0FFDEDEDEFFEAEAEAFFD6D6D6FFA7A7A7FF494949FF515151B8F2F2F210000000000000000000000000
000000001D1D1D68313131FDD1D1D1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF787878FF4C4
C4CBD0000000000000000000000006262622D161616EFE0E0E0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFF444444FFAEAEAE5800000000B2B2B2160C0C0C9B999999FFFFFFFFFFFFFFFFFFFFFFFFFFF
FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA6A6A6FF484848ACD6D6D60D2626264D1E1E1ECFEDED
EDFFDFDFDFFE7B7B7BFFC7C7C7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD6D6D6FEFFFFFFFFD6D6D6FF151515C
B2E2E2E369F9F9F542F2F2FE8D2D2D2FF1F1F1FFF656565FFBDBDBDFFC7C7C7FD757575FD9A9A9AFD8F8F8FFD555555FC56
5656FCFFFFFFFEDDDDDDFF0F0F0FD032323225505050542F2F2FE6AAAAAAFFB2B2B2FF4E4E4EEEDBDBDBFFF0F0F0FEA5A5A
5FD888888FD969696FDC0C0C0FECACACAFCE1E1E1FEE0E0E0FF101010D0000000004949491A0A0A0ABCD2D2D2FFF7F7F7FF
3B3B3BEBDBDBDBFFD8D8D8FEBDBDBDFDFFFFFFFE909090FCFFFFFFFF6E6E6EFC9A9A9AFEE9E9E9FF101010D000000000000
000000000002F000000B2020202D11B1B1BDDE2E2E2FFA2A2A2FF6D6D6DFEFFFFFFFE303030FEFFFFFFFF6F6F6FFD999999
FEE9E9E9FF101010D100000000000000000000000000000000000000001D1D1DD4E2E2E2FFA3A3A3FF6D6D6DFEFFFFFFFE3
03030FEFFFFFFFF707070FE818181FFC8C8C8FF141414CD0000000000000000000000000000000000000000242424D3E0E0
E0FFA3A3A3FF6D6D6DFEFFFFFFFE303030FDFFFFFFFF7C7C7CFE0E0E0EEC454545DD3838385600000000000000000000000
000000000000000004B4B4BBB838383FF575757FF727272FDFFFFFFFE2A2A2AFEF9F9F9FF696969FF5D5D5D6F0000000000
0000000000000000000000000000000000000000000000E0E0E026616161983B3B3BB95C5C5CFFDADADAFF151515F83E3E3
EF3292929D1DCDCDC1A000000000000000000000000000000000000000000000000000000000000000000000000EEEEEE0C
5E5E5EB1282828DFA4A4A46BBCBCBC106666660900000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000F80700
00E0010000E0010000C00000008000000000000000000000000000000080000000C0000000F8000000F8000000F8030000F
8030000FE070000FFFF0000
  )
  ; Load above data into a handle, hIconDisabled
  hIconDragging := CreateIconResource(IconDraggingHex)
  IconDraggingHex := ""  
Return
  
; Create and returns an icon resource handle 
; from raw (ASCII) hex data
;
;http://www.autohotkey.com/forum/viewtopic.php?p=389135
;http://www.autohotkey.com/forum/viewtopic.php?t=63234
;http://msdn.microsoft.com/en-us/library/ms648061%28VS.85%29.aspx 
;
CreateIconResource(data)
{
  VarSetCapacity( IconData,( nSize:=StrLen(data)//2) )
  Loop %nSize% 
    NumPut( "0x" . SubStr(data,2*A_Index-1,2), IconData, A_Index-1, "Char" )

  Return % DllCall( "CreateIconFromResourceEx", UInt,&IconData+22, UInt,NumGet(IconData,14), Int,1, UInt,0x30000, Int,16, Int,16, UInt,0 )
}

; Update the tray icon for the current script
; to the icon represented by the handle
;
SetTrayIcon(iconHandle)
{
  PID := DllCall("GetCurrentProcessId"), VarSetCapacity( NID,444,0 ), NumPut( 444,NID )
  DetectHiddenWindows, On
  NumPut( WinExist( A_ScriptFullPath " ahk_class AutoHotkey ahk_pid " PID),NID,4 )
  DetectHiddenWindows, Off
  NumPut( 1028,NID,8 ), NumPut( 2,NID,12 ), NumPut( iconHandle,NID,20 )
  DllCall( "shell32\Shell_NotifyIcon", UInt,0x1, UInt,&NID )
}

; Set the mouse cursor
; Thanks go to Serenity -- http://www.autohotkey.com/forum/topic35600.html
;
SetSystemCursor(cursorHandle)
{
  Cursors = 32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651
  Loop, Parse, Cursors, `,
  {
    temp := DllCall( "CopyIcon", UInt,cursorHandle)
    DllCall( "SetSystemCursor", Uint,temp, Int,A_Loopfield )
  }
}

RestoreSystemCursor()
{
   DllCall( "SystemParametersInfo", UInt,0x57, UInt,0, UInt,0, UInt,0 )
}

; Update the tray icon automatically
; to the Enabled or Disabled state
; Called by the menu handler
;
UpdateTrayIcon:
  if (ScrollDisabled)
    SetTrayIcon(hIconDisabled)
  else
    SetTrayIcon(hIconEnabled)
Return

; Function wrapper to set a tooltip with automatic timeout
;
ToolTip(Text, visibleSec=2)
{
  ToolTip, %Text%
  SetTimer, ToolTipCancel, % abs(visibleSec) * -1000
  return 

  ToolTipCancel:
  ToolTip
  Return
}


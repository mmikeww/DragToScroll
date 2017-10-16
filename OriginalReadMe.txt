DragToScroll.ahk
http://www.autohotkey.com/forum/viewtopic.php?t=59726

Scroll any window by clicking and dragging with the right mouse button.
Should not interfere with normal right clicking. 
See the discussion link above for more information.

Installation:
  None required; simply unzip and run DragToScroll.exe
  The executable is stand alone and can be run from any directory.

  To run DtS at startup, Simply drag the .exe onto your Start button,
  and drop it in the 'Startup' folder under 'All Programs'.

  Alternately, you can run the script version, DragToScoll.ahk
  The script version depends on Tuncay's ini lib (ini.ahk) and must be in the same directory
  http://www.autohotkey.com/forum/viewtopic.php?t=46226

  Configuration files will be created on the fly.

History:

  v1.0 Jun.28.2010
  * First release
  * Adds simple scroll acceleration to mirror mouse move speed
  
  v1.1 Jun.30.2010
  * General Cleanup, Efficiency improvements
  * Better scroll implemetations, full choice of method
  * Added scrolling by WM_MOUSEWHEEL
  
  v1.2 Jul.1.2010
  * Updated options menu
  * Increased precision in WM_MOUSEWHEEL
  * Nonlinear acceleration
  
  v1.3 Jul.09.2010
  * Adds separable settings for vertical and horizontal scroll methods
  * New defaults: WheelMessage for Vertical, ScrollMessage for Horizontal
  * Better compatibility for horizontal scrolling
  
  v1.4 Aug.31.2010 (contributed by Guest)
  * Contributions Rolled up into 9.15 release
  
  v1.5 Sept.15.2010
  * Code & docs cleanup, formatting fixes
  * Docs are shorter, less specific, bigger picture. See guest's post for more detailed docs
  * Clean up, and inclusion of recent contributions (thanks all!)
    + Enable/Disable scrolling
    + User-defined double-click action
    + Timer based hotkey activation
    + Tray Icons, if set & they exist
    + Edge Scrolling
  * Usage of 'Critical' hotkeys should finally end unintended drag-sticking
  
  v1.6 Sept.17.2010
  * Bugfixes & Cleanup
  * Edge Scrolling update; works with all windows, not just active
  * Scroll Momentum
    + Woohoo!
    + DOES NOT WORK WELL WITH "Smooth Scrolling" (disable in ffx/ie)
    + Works best with a 0 DragThreshold (new default)
    + Works best with WheelMessage (default)
  
  v1.7 Sep.20.2010
  * Embeded Icons
  * Updated Tray menu
  * Invertable Drag
  
  v1.8 Oct.11.2010
  * Toggle slow mode
  * Minor Bugfixes, changes, helpers
  * Configurable selection of Hotkey
  * Movement Checking
  
  v1.81 Oct.13.2010 (Beta)
  * Lots of cleanup
  * Using a single method to scroll now. Should be simpler.
  * Optional Horizontal Acceleration 
  * Better "full" Disable
  * WM_MOUSEHWHEEL bugfix (x2)
  * Per-app Settings 
    + Speed
    + UseAcceleration
    + Scroll Method (brings compatibility to edge-case apps)
    + Disabled (always starts the holding state)
  
  v1.82 Oct.19.2010 (Beta)
  * Bugfixing on 10.13 release
    + ScollDisabled per-app
    + Mouse Coordmode
    + Get/GetSetting
  * Saved Settings
    + GUI saves settings to ini [General]
    + Settings loaded at startup
    
  v1.9 Oct.20.2010
  * Packaging & Release
  
  v2.0 Oct.21.2010
  * Automatic update check
  * Retroactive version numbers (yay)
  * Menu item for opening settings INI
  * Adds more per-app settings
    + UseMovementCheck
    + UseEdgeScrolling
    + UseScrollMomentum
  
  v2.1 Oct.27.2010
  * Automatic activation of windows for WheelKey method
  * Changes to the handling of momentum and acceleration
    + Simpler more versatile acceleration function
    + Able to "catch" the scrolling window and re-drag
    + Supports infinite momentum (i.e. zero friction)
    + Bugfix around simultaneous momentum & dragging
  * Per-app settings updates
    + Adds InvertDrag
    + Bugfix/update to INI section matching
    + Adds ini section support for full .exe process path (WinXP or later)
  * Tweak of default settings and app polish
    + Slightly Increase DragDelay
    + MaxAcceleration NO LONGER USED
    + More momentum, scrolls longer
    + Showing version in tray
    + Now Includes compiled version

  v2.2 Nov.04.2010
  * New Settings GUIs
    + AppSettings GUI for per-app overrides
    + Simplified All Settings GUI
  * Settings Updates
    + Reload Local/Server Settings
    + Limits ServerSettings trips
    + Allows ScrollDisabled by default
  * Rework of Menus
    + Removal of settings menus, replaced by gui
    + new "Open ..." commands
    
  v2.21 Nov.10.2010
  * Bugfixing and Optimizations
  * Catch bug (Hoffmeyer)
  * Shortcut bug & All Settings Button bug (MainTrane)
  * Misc other fixes
  
  v2.3 Feb.15.2011
  * NEW Gesture support for flicking, scrolls one page
  * NEW Change the cursor while dragging
  * Bugfix in Momentum while using InvertDrag
  * Update to widen All Settings GUI; getting too tall.
  
  v2.4 Apr.08.2011
  * Updated Gesture Defaults - Back/Forward for browsers, Adobe Reader
  * Compatibility fixes - FFX4, VS2010, Apps w/o control IDs
  * Bugfix in mouse cursor changing
  * Highlighting for non-default values in All-Settings

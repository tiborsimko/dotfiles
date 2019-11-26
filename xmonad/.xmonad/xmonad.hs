-- Tibor's xmonad configuration.

import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import System.IO
import XMonad.StackSet as W
import XMonad.ManageHook
import XMonad.Actions.GridSelect
import XMonad.Actions.PhysicalScreens
import XMonad.Layout.ThreeColumns
import XMonad.Layout.Maximize
import XMonad.Layout.Spacing
import XMonad.Layout.ResizableTile
import XMonad.Layout.WindowNavigation
import XMonad.Actions.WindowGo
import XMonad.Util.Dmenu
import System.Exit
import Control.Monad
import XMonad.Layout.NoBorders
import XMonad.Layout.Named
import XMonad.Actions.GroupNavigation
import XMonad.Actions.CopyWindow
import XMonad.Hooks.EwmhDesktops
import XMonad.Util.Paste
import Graphics.X11.ExtraTypes.XF86

quitWithWarning :: X ()
quitWithWarning = do
  let m = "Really quit?"
  s <- dmenu [m]
  when (m == s) (io exitSuccess)

myModMask = mod4Mask

myNormalBorderColor = "#282828"

myFocusedBorderColor = "#928374"

myBorderWidth = 1

myTerminal = "termite"

myManageHook = composeAll [
  -- EVO:
  className =? "sun-awt-X11-XFramePeer" --> doFloat
  , className =? "net-sourceforge-jnlp-runtime-Boot" --> doFloat
  -- Pidgin:
  , className =? "Pidgin" --> doShift "6"
  -- Skype:
  , className =? "Skype" --> doFloat
  ---- Hangouts:
  , appName =? "crx_nckgahadagoaajjgafhacjanaoiihapd" --> doShift "9"
  -- , stringProperty "WM_WINDOW_ROLE"  =? "pop-up" --> doFloat
  -- Iceweasel:
  -- , className =? "Iceweasel" --> doShift "8"
  -- Gimp:
  , className =? "Gimp" --> doShift "Gimp"
  , stringProperty "WM_WINDOW_ROLE"  =? "gimp-scale-tool" --> doFloat
  , stringProperty "WM_WINDOW_ROLE"  =? "gimp-shear-tool" --> doFloat
  , stringProperty "WM_WINDOW_ROLE"  =? "gimp-rotate-tool" --> doFloat
  , stringProperty "WM_WINDOW_ROLE"  =? "gimp-perspective-tool" --> doFloat
  , stringProperty "WM_WINDOW_ROLE"  =? "gimp-flip-tool" --> doFloat
  , stringProperty "WM_WINDOW_ROLE"  =? "gimp-layer-new" --> doFloat
  , className =? "XMind" --> doFloat
  ]

myWorkspaces = ["1","2","3","4","5","6","7","8","9"]

myGSConfig = defaultGSConfig {
  -- make GridSelect boxes wider, so that long remote screen plus
  -- git-prompt generated titles can be seen:
  gs_cellheight = 50
  , gs_cellwidth = 400
  }

myAdditionalKeys = [
  ((myModMask, xK_r), spawn $ "rofi -theme gruvbox-dark -show run -font 'Inconsolata 12'")
  , ((myModMask, xK_w), spawn $ "rofi -theme gruvbox-dark -show window -font 'Inconsolata 12'")
  , ((myModMask, xK_g), spawn $ "rofi -theme gruvbox-dark -show window -font 'Inconsolata 12'")
  , ((myModMask, xK_s), spawn $ "rofi -theme gruvbox-dark -show ssh -font 'Inconsolata 12'")
  , ((myModMask .|. controlMask, xK_l), spawn $ "slock")
  -- , ((myModMask .|. controlMask, xK_l), spawn $ "i3lock -d -k -c 282828 --insidecolor=282828ff --ringcolor=665c54ff --linecolor=1d2021ff --keyhlcolor=fabd2fff --ringvercolor=98971aff --separatorcolor=282828ff --insidevercolor=98971aff --ringwrongcolor=cc241dff --insidewrongcolor=cc241dff --timecolor=a89984ff --datecolor=a89984ff")
  , ((myModMask, xK_e), raise (className =? "Emacs"))
  , ((myModMask, xK_b), raise (className =? "qutebrowser"))
  , ((myModMask, xK_x), raise (className =? "Termite"))
  , ((myModMask .|. shiftMask, xK_c), kill1) -- @@ Close the focused window (useful for apps appearing on multiple tags)
  , ((myModMask, xK_v ), windows copyToAll) -- @@ Make focused window always visible
  , ((myModMask .|. shiftMask, xK_v ),  killAllOtherCopies) -- @@ Toggle window state back
  , ((myModMask, xK_f), withFocused (sendMessage . maximizeRestore))
  , ((myModMask, xK_p), windows W.focusUp)
  , ((myModMask, xK_n), windows W.focusDown)
  , ((myModMask .|. shiftMask, xK_p), windows W.swapUp)
  , ((myModMask .|. shiftMask, xK_n), windows W.swapDown)
  , ((myModMask, xK_y), goToSelected myGSConfig)
  , ((myModMask, xK_c), windows W.focusDown)
  , ((myModMask .|. shiftMask, xK_b), sendMessage ToggleStruts)
  , ((myModMask, xK_Right), sendMessage $ Go R)
  , ((myModMask, xK_Left), sendMessage $ Go L)
  , ((myModMask, xK_Up), sendMessage $ Go U)
  , ((myModMask, xK_Down), sendMessage $ Go D)
  , ((myModMask .|. controlMask, xK_Right), sendMessage $ Swap R)
  , ((myModMask .|. controlMask, xK_Left), sendMessage $ Swap L)
  , ((myModMask .|. controlMask, xK_Up), sendMessage $ Swap U)
  , ((myModMask .|. controlMask, xK_Down), sendMessage $ Swap D)
  , ((myModMask .|. shiftMask, xK_Right), sendMessage $ Swap R)
  , ((myModMask .|. shiftMask, xK_Left), sendMessage $ Swap L)
  , ((myModMask .|. shiftMask, xK_Up), sendMessage $ Swap U)
  , ((myModMask .|. shiftMask, xK_Down), sendMessage $ Swap D)
  , ((myModMask .|. shiftMask, xK_q), quitWithWarning)
  , ((myModMask, xK_h), windows W.focusUp)
  , ((myModMask, xK_l), windows W.focusDown)
  , ((myModMask .|. shiftMask, xK_l), sendMessage $ Expand)
  , ((myModMask .|. shiftMask, xK_h), sendMessage $ Shrink)
  , ((myModMask .|. shiftMask, xK_a), sendMessage $ MirrorExpand)
  , ((myModMask .|. shiftMask, xK_z), sendMessage $ MirrorShrink)
  , ((0, xK_Insert), pasteSelection)
  , ((0, xF86XK_AudioMute), spawn "amixer -q set Master toggle && amixer -q set Speaker unmute")
  , ((0, xF86XK_AudioMicMute), spawn "amixer -q set Capture toggle")
  , ((0, xF86XK_AudioLowerVolume), spawn "amixer -q set Master 2-")
  , ((0, xF86XK_AudioRaiseVolume), spawn "amixer -q set Master 2+")
  , ((0, xF86XK_MonBrightnessDown), spawn "xbacklight -dec 10")
  , ((0, xF86XK_MonBrightnessUp), spawn "xbacklight -inc 10")]
  ++
  [((myModMask .|. mask, key), f sc)
     | (key, sc) <- zip [xK_F1, xK_F2, xK_F3] [0..]
     , (f, mask) <- [(viewScreen def, 0), (sendToScreen def, shiftMask)]
  ] ++
  -- mod-[1..9] @@ Switch to workspace N
  -- mod-shift-[1..9] @@ Move client to workspace N
  -- mod-control-shift-[1..9] @@ Copy client to workspace N
  [((m .|. myModMask, k), windows $ f i)
    | (i, k) <- zip (myWorkspaces) [xK_1 .. xK_9]
    , (f, m) <- [(W.view, 0), (W.shift, shiftMask), (copy, shiftMask .|. controlMask)]]

myLayoutHook = (tall ||| wide ||| full)

  where
    tall = named "T"
           $ avoidStruts $ windowNavigation $ maximize $ smartBorders
           $ ResizableTall 1 (3/100) (1/2) []
    wide = named "W"
           $ avoidStruts $ windowNavigation $ maximize $ smartBorders
           $ Mirror (ResizableTall 1 (3/100) (1/2) [])
    cols = named "C"
           $ avoidStruts $ windowNavigation $ maximize $ smartBorders
           $ ThreeCol 1 (3/100) (1/2)
    full = named "M"
           $ avoidStruts $ windowNavigation $ maximize $ smartBorders
           $ Full

mySpacingHook = spacingRaw True (Border 0 2 2 2) True (Border 2 2 2 2) True

myLogHook h = dynamicLogWithPP $ xmobarPP {
  ppOutput = hPutStrLn h
  , ppCurrent = xmobarColor "#d5c4a1" "" . wrap "" ""
  , ppVisible = xmobarColor "#928374" "" . wrap "" ""
  , ppUrgent = xmobarColor "#928374" "" . wrap "" "" . xmobarStrip
  , ppLayout = wrap "" "" . xmobarColor "#928374" "" . wrap " [" "] "
  , ppTitle = xmobarColor "#928374" "" . shorten 50
  , ppSep = ""
  }

myXmobar = "/usr/bin/xmobar /home/simko/.xmobarrc"

main = do
  xmproc <- spawnPipe myXmobar
  xmonad $ docks $ ewmh defaultConfig {
    manageHook = myManageHook
                 <+> manageDocks
                 <+> manageHook defaultConfig
    , layoutHook = mySpacingHook $ myLayoutHook
    , logHook = myLogHook xmproc
    , modMask = myModMask
    , borderWidth = myBorderWidth
    , normalBorderColor = myNormalBorderColor
    , focusedBorderColor = myFocusedBorderColor
    , terminal = myTerminal
    , handleEventHook = fullscreenEventHook
------------    , workspaces = myWorkspaces
    } `additionalKeys` myAdditionalKeys

-- end of file

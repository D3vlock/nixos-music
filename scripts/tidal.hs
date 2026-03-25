:set -XOverloadedStrings
import Sound.Tidal.Context

let editorTarget = Target {oName = "editor", oAddress = "127.0.0.1", oPort = 6013, oLatency = 0.02, oSchedule = Pre BundleStamp, oWindow = Nothing, oHandshake = False, oBusPort = Nothing }
let editorShape = OSCContext "/editor/highlights"

let vizTarget = Target {oName = "viz", oAddress = "127.0.0.1", oPort = 6014, oLatency = 0.02, oSchedule = Pre BundleStamp, oWindow = Nothing, oHandshake = False, oBusPort = Nothing }

tidal <- startStream (defaultConfig {cFrameTimespan = 1/50}) [(superdirtTarget {oLatency = 0.2}, [superdirtShape]), (editorTarget, [editorShape]), (vizTarget, [superdirtShape])]

:{
let d1 = streamReplace tidal 1
    d2 = streamReplace tidal 2
    hush = streamHush tidal
:}

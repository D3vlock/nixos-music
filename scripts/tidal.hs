:set -XOverloadedStrings
import Sound.Tidal.Context

tidal <- startTidal (superdirtTarget {oLatency = 0.1}) defaultConfig

:{
let d1 = streamReplace tidal 1
    d2 = streamReplace tidal 2
    hush = streamHush tidal
:}

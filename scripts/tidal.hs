:set -XOverloadedStrings
import Sound.Tidal.Context

tidal <- startTidal (superdirtTarget {oLatency = 0.1}) defaultConfig

:{
let d1 = streamReplace tidal 1
    d2 = streamReplace tidal 2
    d3 = streamReplace tidal 3
    d4 = streamReplace tidal 4
    d5 = streamReplace tidal 5
    d6 = streamReplace tidal 6
    d7 = streamReplace tidal 7
    d8 = streamReplace tidal 8
    d9 = streamReplace tidal 9
    hush = streamHush tidal
:}

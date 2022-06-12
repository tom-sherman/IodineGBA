type t

@new @module("../../IodineGBA/core/Emulator") external make: unit => t = "default"

@send external setIntervalRate: (t, int) => unit = "setIntervalRate"
@send
external attachGraphicsFrameHandler: (
  t,
  {"copyBuffer": Js.TypedArray2.Uint8Array.t => unit},
) => unit = "attachGraphicsFrameHandler"
@send external attachBIOS: (t, Js.TypedArray2.Uint8Array.t) => unit = "attachBIOS"
@send external attachROM: (t, Js.TypedArray2.Uint8Array.t) => unit = "attachROM"
@send external play: t => unit = "play"
@send external stop: t => unit = "stop"
@send external attachPlayStatusHandler: (t, int => unit) => unit = "attachPlayStatusHandler"
// TODO: Type this
@send external attachAudioHandler: (t, 'a) => unit = "attachAudioHandler"
@send external timerCallback: (t, int) => unit = "timerCallback"
@send external reinitializeAudio: t => unit = "reinitializeAudio"
@send external enableAudio: t => unit = "enableAudio"

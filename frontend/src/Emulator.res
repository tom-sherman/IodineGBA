let gbaWidth = 240
let gbaHeight = 160
let gbaAspectRatio = gbaHeight->float_of_int /. gbaWidth->float_of_int

@new external makeUint8Array: int => Js.TypedArray2.Uint8Array.t = "Uint8Array"
external castUintArraytoArray: Js.TypedArray2.Uint8Array.t => Js.Array.t<int> = "%identity"

let useEmulatorRom = (~iodine, ~bios, ~rom) => {
  React.useEffect1(() => {
    bios->Belt.Option.map(bios => iodine->Iodine.attachBIOS(bios))->ignore
    None
  }, [bios])

  React.useEffect1(() => {
    rom->Belt.Option.map(rom => iodine->Iodine.attachROM(rom))->ignore
    None
  }, [rom])
}

let useEmulatorClock = (~iodine, ~intervalRate, ~isPlaying) => {
  let (startTime, setStartTime) = React.useState(() => 0.)

  React.useEffect0(() => {
    setStartTime(_ => Js.Date.now())

    None
  })

  React.useEffect2(() => {
    let interval = ref(None)

    {
      if isPlaying {
        interval :=
          Some(
            Js.Global.setInterval(
              _ =>
                iodine->Iodine.timerCallback(Js.Date.now()->int_of_float - startTime->int_of_float),
              intervalRate,
            ),
          )
        ()
      }
    }->ignore

    Some(
      () =>
        switch interval.contents {
        | Some(id) => Js.Global.clearInterval(id)
        | None => ()
        },
    )
  }, (isPlaying, intervalRate))

  React.useEffect2(() => {
    Js.log("setIntervalRate")
    iodine->Iodine.setIntervalRate(intervalRate)
    None
  }, (iodine, intervalRate))
}

// [
//             //Use this to control the GBA key mapping:
//             //A:
//             88,
//             //B:
//             90,
//             //Select:
//             16,
//             //Start:
//             13,
//             //Right:
//             39,
//             //Left:
//             37,
//             //Up:
//             38,
//             //Down:
//             40,
//             //R:
//             83,
//             //L:
//             65
//         ]

type joypadKey = A | B | Select | Start | Right | Left | Up | Down | R | L

let getJoyPadKey = (key: joypadKey) => {
  switch key {
  | A => 0
  | B => 1
  | Select => 2
  | Start => 3
  | Right => 4
  | Left => 5
  | Up => 6
  | Down => 7
  | R => 8
  | L => 9
  }
}

type joypadCallbacks = {
  keyDown: joypadKey => unit,
  keyUp: joypadKey => unit,
}

let useEmulatorJoypad = (~iodine) => React.useMemo1(() => {
    keyDown: key => {
      %debugger
      iodine->Iodine.keyDown(key->getJoyPadKey)
    },
    keyUp: key => iodine->Iodine.keyUp(key->getJoyPadKey),
  }, [iodine])

let useEmulatorDisplay = (~iodine) => {
  let canvasRef = React.useRef(Js.Nullable.null)

  React.useEffect0(() => {
    let rgbCount = gbaWidth * gbaHeight * 3
    let rgbaCount = gbaWidth * gbaHeight * 4

    let canvas = canvasRef.current->Js.Nullable.toOption->Belt.Option.getExn
    let ctx = canvas->Webapi.Canvas.CanvasElement.getContext2d

    let swizzledFrameFree = [makeUint8Array(rgbCount), makeUint8Array(rgbCount)]
    let swizzledFrameReady = []

    let canvasBuffer =
      ctx->Webapi.Canvas.Canvas2d.getImageData(
        ~sx=0.,
        ~sy=0.,
        ~sw=gbaWidth->float_of_int,
        ~sh=gbaHeight->float_of_int,
      )

    {
      let canvasData = canvasBuffer->Webapi.Dom.Image.data
      let length = canvasData->Js.TypedArray2.Uint8ClampedArray.length
      let indexGFXIterate = ref(3)
      while indexGFXIterate.contents < length {
        canvasData->Js.TypedArray2.Uint8ClampedArray.unsafe_set(indexGFXIterate.contents, 0xFF)

        indexGFXIterate := indexGFXIterate.contents + 4
      }
    }

    let draw = () => {
      if swizzledFrameReady->Js.Array2.length > 0 {
        let canvasData = canvasBuffer->Webapi.Dom.Image.data
        let swizzledFrame = swizzledFrameReady->Js.Array2.shift->Belt.Option.getUnsafe

        let canvasIndex = ref(0)
        let bufferIndex = ref(0)
        while canvasIndex.contents < rgbaCount {
          canvasData->Js.TypedArray2.Uint8ClampedArray.unsafe_set(
            canvasIndex.contents,
            swizzledFrame->Js.TypedArray2.Uint8Array.unsafe_get(bufferIndex.contents),
          )
          canvasIndex := canvasIndex.contents + 1
          bufferIndex := bufferIndex.contents + 1
          canvasData->Js.TypedArray2.Uint8ClampedArray.unsafe_set(
            canvasIndex.contents,
            swizzledFrame->Js.TypedArray2.Uint8Array.unsafe_get(bufferIndex.contents),
          )
          canvasIndex := canvasIndex.contents + 1
          bufferIndex := bufferIndex.contents + 1
          canvasData->Js.TypedArray2.Uint8ClampedArray.unsafe_set(
            canvasIndex.contents,
            swizzledFrame->Js.TypedArray2.Uint8Array.unsafe_get(bufferIndex.contents),
          )
          canvasIndex := canvasIndex.contents + 1
          bufferIndex := bufferIndex.contents + 1

          canvasIndex := canvasIndex.contents + 1
        }

        swizzledFrameFree->Js.Array2.push(swizzledFrame)->ignore
        ctx->Webapi__Canvas.Canvas2d.putImageData(~imageData=canvasBuffer, ~dx=0., ~dy=0.)
      }
    }

    iodine->Iodine.attachGraphicsFrameHandler({
      "copyBuffer": buf => {
        if swizzledFrameFree->Js.Array2.length == 0 {
          swizzledFrameFree
          ->Js.Array2.push(swizzledFrameReady->Js.Array2.shift->Belt.Option.getExn)
          ->ignore
        }->ignore

        let swizzledFrame = swizzledFrameFree->Js.Array2.shift->Belt.Option.getExn
        swizzledFrame->Js.TypedArray2.Uint8Array.setArray(buf->castUintArraytoArray)
        swizzledFrameReady->Js.Array2.push(swizzledFrame)->ignore
      },
    })

    let running = ref(true)
    let rec runLoop = () => {
      Webapi.requestAnimationFrame(_ => {
        draw()
        if running.contents {
          runLoop()
        }
      })
    }

    runLoop()

    Some(() => running.contents = false)
  })

  canvasRef
}

let useEmulatorAudio = (~iodine) => {
  module GlueCodeMixer = {
    type t
    @module("./util/Audio") @new external make: Dom.element => t = "GlueCodeMixer"
  }

  module GlueCodeMixerInput = {
    type t
    @module("./util/Audio") @new external make: GlueCodeMixer.t => t = "GlueCodeMixerInput"
  }

  let hasInitialized = React.useRef(false)
  let playButtonRef = React.useRef(Js.Nullable.null)
  React.useEffect1(() =>
    playButtonRef.current
    ->Js.Nullable.toOption
    ->Belt.Option.flatMap(el => {
      if !hasInitialized.current {
        let mixer = GlueCodeMixer.make(el)
        let mixerInput = GlueCodeMixerInput.make(mixer)
        iodine->Iodine.attachAudioHandler(mixerInput)
        iodine->Iodine.enableAudio
        hasInitialized.current = true
      }->ignore
      None
    })
  , [iodine])

  playButtonRef
}

module Wrapper = {
  let context = React.createContext(ElementDimensions.defaultDimensions)

  let provider = React.Context.provider(context)

  @react.component
  let make = (~children) => {
    let (dimensions, ref) = ElementDimensions.useDimensions()

    <div
      ref={ReactDOM.Ref.domRef(ref)}
      style={ReactDOMStyle.make(
        ~maxWidth="100vw",
        ~maxHeight="100vh",
        ~position="relative",
        ~margin="auto",
        (),
      )->ReactDOMStyle.unsafeAddProp(
        "aspectRatio",
        `${gbaWidth->string_of_int} / ${gbaHeight->string_of_int}`,
      )}>
      {React.createElement(
        provider,
        {
          "value": dimensions,
          "children": children,
        },
      )}
    </div>
  }

  let useEmulatorContext = () => React.useContext(context)
}

type playState = [#playing | #paused | #stopped]

type emulatorData = {
  canvasRef: ReactDOM.domRef,
  playButtonRef: ReactDOM.domRef,
  playState: playState,
  keyDown: joypadKey => unit,
  keyUp: joypadKey => unit,
}

let useEmulator = (
  ~intervalRate=16,
  ~bios: option<Js.TypedArray2.Uint8Array.t>,
  ~rom: option<Js.TypedArray2.Uint8Array.t>,
  ~playState: playState,
) => {
  let iodine = LazyRef.use(Iodine.make)

  useEmulatorClock(~iodine, ~intervalRate, ~isPlaying=playState == #playing)
  useEmulatorRom(~iodine, ~rom, ~bios)
  let {keyDown, keyUp} = useEmulatorJoypad(~iodine)

  React.useEffect0(() => {
    iodine->Iodine.attachPlayStatusHandler(state => Js.log(state))

    None
  })

  React.useEffect2(() => {
    switch playState {
    | #playing => iodine->Iodine.play
    | #stopped => iodine->Iodine.stop
    | #paused => iodine->Iodine.pause
    }->ignore

    None
  }, (iodine, playState))

  let canvasRef = useEmulatorDisplay(~iodine)
  let playButtonRef = useEmulatorAudio(~iodine)

  React.useMemo5(() => {
    playButtonRef: playButtonRef->ReactDOM.Ref.domRef,
    canvasRef: canvasRef->ReactDOM.Ref.domRef,
    playState: playState,
    keyDown: keyDown,
    keyUp: keyUp,
  }, (playButtonRef, canvasRef, playState, keyDown, keyUp))
}

@react.component
let make = (~data) => {
  let {width} = Wrapper.useEmulatorContext()

  let scaleFactor = width /. gbaWidth->float_of_int

  <canvas
    ref={data.canvasRef}
    width={gbaWidth->Belt.Int.toString}
    height={gbaHeight->Belt.Int.toString}
    style={ReactDOMStyle.make(
      ~display="block",
      ~transform=`scale(${scaleFactor->Js.Float.toString})`,
      ~transformOrigin="0 0",
      ~imageRendering="pixelated",
      (),
    )}
  />
}

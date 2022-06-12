module EmulatorProvider = {
  let context = React.createContext(ElementDimensions.defaultDimensions)

  let provider = React.Context.provider(context)

  @react.component
  let make = (~children) => {
    let (dimensions, ref) = ElementDimensions.useDimensions()

    <div ref={ReactDOM.Ref.domRef(ref)}>
      {React.createElement(provider, {"value": dimensions, "children": children})}
    </div>
  }

  let useEmulatorContext = () => React.useContext(context)
}

let gbaWidth = 240
let gbaHeight = 160
let gbaAspectRatio = gbaHeight->float_of_int /. gbaWidth->float_of_int

@new external makeUint8Array: int => Js.TypedArray2.Uint8Array.t = "Uint8Array"
external castUintArraytoArray: Js.TypedArray2.Uint8Array.t => Js.Array.t<int> = "%identity"

let useEmulatorDisplay = (~iodine, ~bios, ~rom, ~intervalRate) => {
  let canvasRef = React.useRef(Js.Nullable.null)
  let (isPlaying, setIsPlaying) = React.useState(() => false)
  let (startTime, setStartTime) = React.useState(() => 0.)

  React.useEffect2(() => {
    setStartTime(_ => Js.Date.now())

    None
  }, (bios, rom))

  React.useEffect2(() => {
    let interval = ref(None)

    {
      if isPlaying {
        interval :=
          Some(
            Js.Global.setInterval(
              _ =>
                iodine->Iodine.timerCallback(
                  lsr(Js.Date.now()->int_of_float - startTime->int_of_float, 0),
                ),
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

  React.useEffect0(() => {
    iodine->Iodine.attachPlayStatusHandler(status =>
      switch status {
      | 0 => setIsPlaying(_ => false)
      | 1 => setIsPlaying(_ => true)
      | _ => Js.Exn.raiseError("Unexpected play status" ++ status->string_of_int)
      }
    )

    None
  })

  React.useEffect1(() => {
    iodine->Iodine.attachBIOS(bios)
    None
  }, [bios])

  React.useEffect1(() => {
    iodine->Iodine.attachROM(rom)
    None
  }, [rom])

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
        let swizzle = () => {
          let swizzledFrame = swizzledFrameFree->Js.Array2.shift->Belt.Option.getExn
          swizzledFrame->Js.TypedArray2.Uint8Array.setArray(buf->castUintArraytoArray)
          swizzledFrameReady->Js.Array2.push(swizzledFrame)->ignore
        }

        if swizzledFrameFree->Js.Array2.length == 0 {
          swizzledFrameFree
          ->Js.Array2.push(swizzledFrameReady->Js.Array2.shift->Belt.Option.getExn)
          ->ignore
          swizzle()
        } else {
          swizzle()
        }
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

  React.useEffect2(() => {
    Js.log("setIntervalRate")
    iodine->Iodine.setIntervalRate(intervalRate)
    None
  }, (iodine, intervalRate))

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

@react.component
let make = (
  ~intervalRate=16,
  ~bios: Js.TypedArray2.Uint8Array.t,
  ~rom: Js.TypedArray2.Uint8Array.t,
) => {
  let iodine = LazyRef.use(Iodine.make)
  let canvasRef = useEmulatorDisplay(~iodine, ~bios, ~rom, ~intervalRate)
  let playButtonRef = useEmulatorAudio(~iodine)
  let {width} = EmulatorProvider.useEmulatorContext()

  let scaleFactor = width /. gbaWidth->float_of_int
  let height = width *. gbaAspectRatio

  <>
    <p>
      <button onClick={_ => iodine->Iodine.play} ref={ReactDOM.Ref.domRef(playButtonRef)}>
        {"Play"->React.string}
      </button>
    </p>
    <div style={ReactDOMStyle.make(~height=height->Js.Float.toString ++ "px", ())}>
      <canvas
        ref={ReactDOM.Ref.domRef(canvasRef)}
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
    </div>
  </>
}

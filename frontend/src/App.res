module Storage = {
  let bios = ref(None)
  let rom = ref(None)

  @new
  external makeUnint8ArrayWithArrayBuffer: Webapi.Fetch.arrayBuffer => Js.TypedArray2.Uint8Array.t =
    "Uint8Array"

  let store = data => {
    bios := Some(data["bios"])
    rom := Some(data["rom"])

    Webapi.Fetch.Response.make("OK")->Promise.resolve
  }

  @new
  external makeResponseWithFormData: Webapi.Fetch.FormData.t => Webapi.Fetch.Response.t = "Response"

  let get = () => {
    open Webapi.Fetch

    let decodeRom = res =>
      res->Response.arrayBuffer->Promise.thenResolve(makeUnint8ArrayWithArrayBuffer)

    Promise.all2((
      fetch("/gba_bios.bin")->Promise.then(decodeRom),
      fetch("/earthwormjim2.gba")->Promise.then(decodeRom),
    ))->Promise.thenResolve(((bios, rom)) =>
      {
        "bios": bios,
        "rom": rom,
      }
    )
  }
}

module Joypad = {
  type pointerEventType = DownEvent | EnterEvent | LeaveEvent
  module JoyButton = {
    @react.component
    let make = (~children, ~depressed, ~onPointer) => {
      open Braid

      <Box
        padding={[#all(#small)]->Prop.p}
        background={depressed ? #neutralSoftActive : #neutralSoft}
        borderRadius={[#all(#full)]->Prop.p}
        onPointerEnter={ev => onPointer(EnterEvent, ev)}
        onPointerLeave={ev => onPointer(LeaveEvent, ev)}
        onPointerDown={ev => onPointer(DownEvent, ev)}>
        {children}
      </Box>
    }
  }

  type keyState = KeyDown(Dom.eventPointerId) | KeyUp
  let keyStateGetPointerId = key =>
    switch key {
    | KeyDown(id) => Some(id)
    | KeyUp => None
    }

  // TODO: Probably should use a set to dedupe on joypadKey
  type state = array<(Emulator.joypadKey, keyState)>

  type event =
    | PointerDown(Emulator.joypadKey, Dom.eventPointerId)
    | PointerUp(Dom.eventPointerId)
    | PointerEnter(Emulator.joypadKey, Dom.eventPointerId)
    | PointerLeave(Emulator.joypadKey, Dom.eventPointerId)
    | Handle(Emulator.joypadKey)

  let isButtonDepressed = (state, button) =>
    state->Js.Array2.some(((key, state)) =>
      switch state {
      | KeyDown(id) => key == button
      | KeyUp => false
      }
    )

  // let reducer = (state: state, event) =>
  //   switch event {
  //   | PointerDown(key, id) => state->Js.Array2.concat([(key, KeyDown(id))])
  //   | PointerUp(newId) =>
  //     state->Js.Array2.map(((key, keyState)) =>
  //       switch keyState {
  //       | KeyDown(id) if newId == id => (key, KeyUp)
  //       | _ => (key, keyState)
  //       }
  //     )
  //     |
  //   }

  @react.component
  let make = (~onKeyUp, ~onKeyDown) => {
    let (state, dispatch) = React.useReducer(reducer, [])

    React.useEffect(() => {
      let (downButtons, upButtons) = state->Belt.Array.partition(((_, state)) =>
        switch state {
        | KeyDown(_) => true
        | KeyUp => false
        }
      )

      downButtons->Js.Array2.forEach(((button, _)) => {
        onKeyDown(button)
        dispatch(Handle(button))
      })

      upButtons->Js.Array2.forEach(((button, _)) => {
        onKeyUp(button)
        dispatch(Handle(button))
      })

      None
    })

    React.useEffect(() => {
      open Webapi.Dom
      let handlePointerUp = event => {
        let id = event->PointerEvent.pointerId
        dispatch(PointerUp(id))
      }

      document->Document.addEventListener("pointerup", Obj.magic(handlePointerUp))

      Some(() => document->Document.removeEventListener("pointerup", Obj.magic(handlePointerUp)))
    })

    let handlePointer = (key, pointerType, event) =>
      switch pointerType {
      | DownEvent => dispatch(PointerDown(key, event->ReactEvent.Pointer.pointerId))
      | EnterEvent => dispatch(PointerEnter(key, event->ReactEvent.Pointer.pointerId))
      | LeaveEvent => dispatch(PointerLeave(key, event->ReactEvent.Pointer.pointerId))
      }

    open Braid
    <div>
      <Inline space={[#all(#small)]->Prop.p}>
        <JoyButton
          depressed={isButtonDepressed(state, Emulator.Up)} onPointer={handlePointer(Emulator.Up)}>
          <Icon.Chevron direction=#up />
        </JoyButton>
        <JoyButton
          depressed={isButtonDepressed(state, Emulator.Right)}
          onPointer={handlePointer(Emulator.Right)}>
          <Icon.Chevron direction=#right />
        </JoyButton>
        <JoyButton
          depressed={isButtonDepressed(state, Emulator.Down)}
          onPointer={handlePointer(Emulator.Down)}>
          <Icon.Chevron direction=#down />
        </JoyButton>
        <JoyButton
          depressed={isButtonDepressed(state, Emulator.Left)}
          onPointer={handlePointer(Emulator.Left)}>
          <Icon.Chevron direction=#left />
        </JoyButton>
        <JoyButton
          depressed={isButtonDepressed(state, Emulator.A)} onPointer={handlePointer(Emulator.A)}>
          <Icon.Add />
        </JoyButton>
        <JoyButton
          depressed={isButtonDepressed(state, Emulator.B)} onPointer={handlePointer(Emulator.B)}>
          <div /> <Icon.Minus />
        </JoyButton>
      </Inline>
    </div>
  }
}

module Home = {
  let loader = _ => Storage.get()

  // Currently unused, blocked by https://github.com/remix-run/react-router/issues/8982
  let action = ({ReactRouter.Route.request: request}) => {
    open Webapi.Fetch

    request
    ->Request.formData
    ->Promise.then(fd => {
      let biosEntry =
        fd->FormData.get("bios")->Belt.Option.map(FormData.EntryValue.classify)->Belt.Option.getExn
      let romEntry =
        fd->FormData.get("rom")->Belt.Option.map(FormData.EntryValue.classify)->Belt.Option.getExn

      switch (biosEntry, romEntry) {
      | (#String(_), _)
      | (_, #String(_)) =>
        Js.Exn.raiseError("Expected files")
      | (#File(bios), #File(rom)) =>
        Storage.store({
          "rom": rom,
          "bios": bios,
        })
      }
    })
  }

  @react.component
  let make = () => {
    open ReactRouter
    open Braid
    let data = useLoaderData()
    let maybeRom: option<Js.TypedArray2.Uint8Array.t> = data["rom"]
    let maybeBios: option<Js.TypedArray2.Uint8Array.t> = data["bios"]

    let (playState, setPlayState) = React.useState(() => #stopped)

    let data = Emulator.useEmulator(~bios=maybeBios, ~rom=maybeRom, ~intervalRate=16, ~playState)

    <Stack space={[#all(#none)]->Prop.p}>
      <Emulator.Wrapper>
        <Emulator data />
        <div
          style={ReactDOMStyle.make(
            ~position="absolute",
            ~top="0",
            ~left="0",
            ~width="100%",
            ~height="100%",
            ~display="flex",
            ~justifyContent="center",
            ~alignItems="center",
            ~backgroundColor={playState == #stopped ? "rgba(0,0,0,0.5)" : "transparent"},
            (),
          )}>
          {switch playState {
          | #paused
          | #stopped =>
            <ButtonIcon
              id="play"
              icon={<Icon.Video />}
              size=#large
              label="Play"
              ref={data.playButtonRef}
              onClick={_ => setPlayState(_ => #playing)}
            />
          | #playing => React.null
          }}
        </div>
      </Emulator.Wrapper>
      <Joypad onKeyDown=data.keyDown onKeyUp=data.keyUp />
    </Stack>
  }
}

@react.component
let make = () => {
  open ReactRouter

  <DataBrowserRouter>
    <Route path="/" element={<Home />} loader={Home.loader} />
  </DataBrowserRouter>
}

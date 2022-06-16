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
    let maybeRom = data["rom"]
    let maybeBios = data["bios"]

    let (playState, setPlayState) = React.useState(() => #stopped)

    let data = Emulator.useEmulator(~bios=maybeBios, ~rom=maybeRom, ~intervalRate=16, ~playState)

    <>
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
    </>
  }
}

@react.component
let make = () => {
  open ReactRouter

  <DataBrowserRouter>
    <Route path="/" element={<Home />} loader={Home.loader} />
  </DataBrowserRouter>
}

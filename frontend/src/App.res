module Storage = {
  let bios = ref(None)
  let rom = ref(None)

  let store = data => {
    Js.log(data)
    bios := Some(data["bios"])
    rom := Some(data["rom"])

    Webapi.Fetch.Response.make("OK")->Promise.resolve
  }

  @new
  external makeResponseWithFormData: Webapi.Fetch.FormData.t => Webapi.Fetch.Response.t = "Response"

  let get = () => {
    open Webapi.Fetch
    let fd = FormData.make()
    bios.contents->Belt.Option.map(bios => fd->FormData.appendFile("bios", bios))->ignore
    rom.contents->Belt.Option.map(rom => fd->FormData.appendFile("rom", rom))->ignore

    Promise.resolve(makeResponseWithFormData(fd))
  }
}

module Home = {
  let loader = _ => Storage.get()

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
    let data = useLoaderData()
    let maybeRom = data["rom"]
    let maybeBios = data["bios"]

    <>
      <Form method={#post} encType="multipart/form-data">
        <p> {"BIOS:"->React.string} <input name="bios" type_="file" /> </p>
        <p> {"ROM:"->React.string} <input name="rom" type_="file" /> </p>
        <button type_="submit"> {"Save"->React.string} </button>
      </Form>
      {switch (maybeRom, maybeBios) {
      | (Some(rom), Some(bios)) =>
        <Emulator.EmulatorProvider> <Emulator bios={bios} rom={rom} /> </Emulator.EmulatorProvider>
      | _ => React.null
      }}
    </>
  }
}

@react.component
let make = () => {
  open ReactRouter

  <DataBrowserRouter>
    <Route path="/" element={<Home />} action={Home.action} loader={Home.loader} />
  </DataBrowserRouter>
}

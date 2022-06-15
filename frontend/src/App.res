external castArrayBuffer: Webapi.Fetch.arrayBuffer => Js.TypedArray2.array_buffer = "%identity"

type state =
  | UploadingROMs({
      rom: option<Js.TypedArray2.Uint8Array.t>,
      bios: option<Js.TypedArray2.Uint8Array.t>,
    })
  | Ready({rom: Js.TypedArray2.Uint8Array.t, bios: Js.TypedArray2.Uint8Array.t})

type event = LoadBios(Js.TypedArray2.Uint8Array.t) | LoadRom(Js.TypedArray2.Uint8Array.t)

let reducer = (state, event) =>
  switch state {
  | Ready({bios, rom}) => Ready({bios: bios, rom: rom})
  | UploadingROMs({rom, bios}) =>
    switch (event, rom, bios) {
    | (LoadRom(newRom), _, None) => UploadingROMs({rom: Some(newRom), bios: bios})
    | (LoadRom(newRom), _, Some(bios)) => Ready({rom: newRom, bios: bios})
    | (LoadBios(newBios), None, _) => UploadingROMs({rom: rom, bios: Some(newBios)})
    | (LoadBios(newBios), Some(rom), _) => Ready({rom: rom, bios: newBios})
    }
  }

@react.component
let make = () => {
  open Braid
  open Braid.Prop
  let (state, dipatch) = React.useReducer(reducer, UploadingROMs({rom: None, bios: None}))

  <>
    <Box padding={[#all(#large)]->p}>
      <Card>
        <Stack space={[#all(#large)]->p}>
          <Heading level=#3> {"Heading"->React.string} </Heading>
          <Text> {"lipsum1"->React.string} </Text>
          <Text> {"lipsum2"->React.string} </Text>
        </Stack>
      </Card>
    </Box>
    <p>
      {"BIOS:"->React.string}
      <input
        type_="file"
        onChange={e => {
          let target = e->ReactEvent.Form.target
          switch target["files"]->Webapi.FileList.toArray->Belt.Array.get(0) {
          | None => ()
          | Some(file) =>
            file
            ->Webapi__File.arrayBuffer
            ->Promise.thenResolve(buf =>
              dipatch(LoadBios(buf->Js.TypedArray2.Uint8Array.fromBuffer))
            )
            ->ignore
          }
        }}
      />
    </p>
    <p>
      {"ROM:"->React.string}
      <input
        type_="file"
        onChange={e => {
          let target = e->ReactEvent.Form.target
          switch target["files"]->Webapi.FileList.toArray->Belt.Array.get(0) {
          | None => ()
          | Some(file) =>
            file
            ->Webapi__File.arrayBuffer
            ->Promise.thenResolve(buf =>
              dipatch(LoadRom(buf->Js.TypedArray2.Uint8Array.fromBuffer))
            )
            ->ignore
          }
        }}
      />
    </p>
    {switch state {
    | Ready({rom, bios}) =>
      <Emulator.EmulatorProvider> <Emulator bios={bios} rom={rom} /> </Emulator.EmulatorProvider>
    | _ => React.null
    }}
  </>
}

let name = rom =>
  TextDecoder.make()->TextDecoder.decode(
    rom->Js.TypedArray2.Uint8Array.slice(~start=0xA0, ~end_=0xA0 + 12),
  )

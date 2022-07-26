type t
@new external make: unit => t = "TextDecoder"

@send external decode: (t, 'a) => string = "decode"

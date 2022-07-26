type size = [#xsmall | #small | #standard | #large | #fill]

module Video = {
  @module("braid-design-system") @react.component
  external make: (~size: size=?) => React.element = "IconVideo"
}

module Add = {
  @module("braid-design-system") @react.component
  external make: (~size: size=?) => React.element = "IconAdd"
}
module Minus = {
  @module("braid-design-system") @react.component
  external make: (~size: size=?) => React.element = "IconMinus"
}
module Chevron = {
  @module("braid-design-system") @react.component
  external make: (~size: size=?, ~direction: [#up | #down | #left | #right]=?) => React.element =
    "IconChevron"
}

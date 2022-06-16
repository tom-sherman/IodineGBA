type size = [#xsmall | #small | #standard | #large | #fill]

module Video = {
  @module("braid-design-system") @react.component
  external make: (~size: size=?) => React.element = "IconVideo"
}

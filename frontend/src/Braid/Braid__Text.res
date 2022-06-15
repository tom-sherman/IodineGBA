@module("braid-design-system") @react.component
external make: (
  ~children: React.element=?,
  ~size: [#xsmall | #small | #standard | #large]=?,
  ~tone: [
    | #brandAccent
    | #caution
    | #critical
    | #formAccent
    | #info
    | #neutral
    | #positive
    | #promote
    | #link
    | #secondary
  ]=?,
  ~weight: [#regular | #medium | #strong]=?,
) => React.element = "Text"

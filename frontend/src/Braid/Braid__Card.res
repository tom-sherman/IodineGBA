@module("braid-design-system") @react.component
external make: (
  ~children: React.element=?,
  ~tone: [#formAccent | #promote]=?,
  ~component: [#div | #article | #aside | #details | #main | #section]=?,
  ~rounded: bool=?,
  ~roundedAbove: [#mobile | #tablet | #desktop]=?,
) => React.element = "Card"

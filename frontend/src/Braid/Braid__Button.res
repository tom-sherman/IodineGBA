@module("braid-design-system") @react.component
external make: (
  ~id: string=?,
  ~onClick: ReactEvent.Mouse.t => unit=?,
  ~\"type": [#reset | #button | #submit]=?,
  ~children: React.element=?,
  ~size: [#small | #standard]=?,
  ~tone: [#brandAccent | #critical | #neutral]=?,
  ~variant: [#transparent | #solid | #ghost | #soft]=?,
  ~bleed: bool=?,
  ~loading: bool=?,
  ~icon: React.element=?,
  ~ref: ReactDOM.domRef=?,
) => React.element = "Button"

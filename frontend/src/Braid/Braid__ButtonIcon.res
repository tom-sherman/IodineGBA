@module("braid-design-system") @react.component
external make: (
  ~id: string,
  ~icon: React.element,
  ~label: string,
  ~onClick: ReactEvent.Mouse.t => unit=?,
  ~\"type": [#reset | #button | #submit]=?,
  ~children: React.element=?,
  ~size: [#small | #standard]=?,
  ~tone: [#brandAccent | #critical | #neutral]=?,
  ~variant: [#transparent | #solid | #ghost | #soft]=?,
  ~bleed: bool=?,
  ~loading: bool=?,
) => React.element = "Button"

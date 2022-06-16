@module("braid-design-system") @react.component
external make: (
  ~id: string,
  ~icon: React.element,
  ~label: string,
  ~onClick: ReactEvent.Mouse.t => unit=?,
  ~\"type": [#reset | #button | #submit]=?,
  ~children: React.element=?,
  ~size: [#large | #standard]=?,
  ~tone: [#brandAccent | #critical | #neutral]=?,
  ~variant: [#transparent | #solid | #ghost | #soft]=?,
  ~bleed: bool=?,
  ~loading: bool=?,
  ~ref: ReactDOM.domRef=?,
) => React.element = "ButtonIcon"

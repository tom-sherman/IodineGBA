@module("braid-design-system") @react.component
external make: (
  ~children: React.element,
  ~space: Braid__Prop.space,
  ~component: [#span | #div | #ol | #ul]=?,
  ~align: Braid__Prop.propObject<[#left | #right | #center]>=?,
) => React.element = "Stack"

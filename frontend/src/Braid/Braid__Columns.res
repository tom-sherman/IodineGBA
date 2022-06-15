@module("braid-design-system") @react.component
external make: (
  ~children: React.element,
  ~space: Braid__Prop.space,
  ~collapseBelow: [#tablet | #desktop | #wide]=?,
  ~align: Braid__Prop.propObject<[#left | #right | #center]>=?,
  ~alignY: Braid__Prop.propObject<[#bottom | #top | #center]>=?,
  ~reverse: bool=?,
) => React.element = "Columns"

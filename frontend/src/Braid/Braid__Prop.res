type responsiveProp<'a> = [#all('a) | #mobile('a) | #tablet('a) | #desktop('a) | #wide('a)]

type propObject<'a> = {
  mobile: option<'a>,
  tablet: option<'a>,
  desktop: option<'a>,
  wide: option<'a>,
}

%%private(
  let rec pAux = (prop: array<responsiveProp<'a>>, obj) =>
    if prop->Js.Array2.length === 0 {
      obj
    } else {
      let rest = prop->Belt.Array.sliceToEnd(1)
      switch prop[0] {
      | #all(v) => {
          mobile: Some(v),
          tablet: Some(v),
          desktop: Some(v),
          wide: Some(v),
        }
      | #mobile(v) =>
        pAux(
          rest,
          {
            ...obj,
            mobile: Some(v),
          },
        )
      | #tablet(v) =>
        pAux(
          rest,
          {
            ...obj,
            tablet: Some(v),
          },
        )
      | #desktop(v) =>
        pAux(
          rest,
          {
            ...obj,
            desktop: Some(v),
          },
        )
      | #wide(v) =>
        pAux(
          rest,
          {
            ...obj,
            wide: Some(v),
          },
        )
      }
    }

  let empty = {
    mobile: None,
    tablet: None,
    desktop: None,
    wide: None,
  }
)

let p = (prop: array<responsiveProp<'a>>) => pAux(prop, empty)

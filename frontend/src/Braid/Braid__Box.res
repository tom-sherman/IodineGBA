@module("braid-design-system") @react.component
external make: (
  ~background: [
    | #body
    | #brand
    | #brandAccent
    | #brandAccentActive
    | #brandAccentHover
    | #brandAccentSoft
    | #brandAccentSoftActive
    | #brandAccentSoftHover
    | #caution
    | #cautionLight
    | #critical
    | #criticalActive
    | #criticalHover
    | #criticalLight
    | #criticalSoft
    | #criticalSoftActive
    | #criticalSoftHover
    | #formAccent
    | #formAccentActive
    | #formAccentHover
    | #formAccentSoft
    | #formAccentSoftActive
    | #formAccentSoftHover
    | #info
    | #infoLight
    | #neutral
    | #neutralActive
    | #neutralHover
    | #neutralLight
    | #neutralSoft
    | #neutralSoftActive
    | #neutralSoftHover
    | #positive
    | #positiveLight
    | #promote
    | #promoteLight
    | #surface
    | #customDark
    | #customLight
  ]=?,
  ~padding: Braid__Prop.propObject<
    [#xsmall | #small | #large | #medium | #none | #gutter | #xxsmall | #xlarge | #xxlarge],
  >=?,
) => React.element = "Box"

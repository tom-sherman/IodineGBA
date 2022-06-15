module DataBrowserRouter = {
  @module("react-router-dom") @react.component
  external make: (~fallbackElement: React.element=?, ~children: React.element) => React.element =
    "DataBrowserRouter"
}

module Route = {
  type dataFunctionArgs = {
    params: Js.Dict.t<string>,
    request: Webapi.Fetch.Request.t,
    signal: Webapi.Fetch.AbortController.signal,
  }

  @module("react-router-dom") @react.component
  external make: (
    ~element: React.element,
    ~path: string,
    ~caseSensitive: bool=?,
    ~errorElement: React.element=?,
    ~loader: dataFunctionArgs => Promise.t<'a>=?,
    ~action: dataFunctionArgs => Promise.t<Webapi.Fetch.Response.t>=?,
  ) => React.element = "Route"
}

@module("react-router-dom") external useLoaderData: 'a = "useLoaderData"

module Form = {
  @module("react-router-dom") @react.component
  external make: (
    ~children: React.element=?,
    ~action: string=?,
    ~method: [#get | #put | #patch | #post | #delete]=?,
    ~encType: string=?,
  ) => React.element = "Form"
}

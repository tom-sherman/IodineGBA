import React from "react";
import ReactDOM from "react-dom/client";
import "braid-design-system/reset";
import wireframeTheme from "braid-design-system/themes/wireframe";
import { BraidProvider } from "braid-design-system";
import * as App from "./App.bs";


ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <BraidProvider theme={wireframeTheme}>
      <App.make />
    </BraidProvider>
  </React.StrictMode>
);

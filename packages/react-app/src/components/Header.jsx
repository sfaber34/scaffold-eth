import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <a href="/">
      <div style={{ position: "absolute", left: -20, top: -30 }}>
        <img src="exosTitle.png" width="70" height="70" style={{marginLeft: 38, marginTop:50 }} alt="Exos" />
      </div>
      <PageHeader
        title={<div style={{ marginLeft: 80, fontSize:40, marginTop:20, marginBottom:0}}>Exos</div>}
        // subTitle="Loogies with a smile :-)"
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}

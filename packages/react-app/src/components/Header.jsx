import React  from "react";
import { Link } from "react-router-dom";
import { Typography, PageHeader, Menu, Button } from "antd";

const { Title, Text } = Typography;

// displays a page header

export default function Header({ location, web3Modal, logoutOfWeb3Modal, link, title, subTitle, ...props }) {
  return (
    <div style={{display: "flex", justifyContent: "space-between", alignItems: "flex-start"}}>
    <a href="/" style={{display: "flex", zIndex: 2}}>
      <div >
        <img src="favicon.png" width="50" height="50" style={{marginLeft: 10, marginTop:10 }} alt="Exos" />
      </div>
      <PageHeader
        title={<div>Exos</div>}
        // subTitle="Loogies with a smile :-)"
        style={{ cursor: "pointer" }}
      />
    </a>
    <Menu
    style={{ zIndex: 2, backgroundColor:"#00000000" }}
    selectedKeys={[location.pathname]}
    mode="horizontal"
  >
    <Menu.Item key="/mint">
      <Link to="/mint">Mint</Link>
    </Menu.Item>
    <Menu.Item key="/about">
      <Link to="/about">About</Link>
    </Menu.Item>
    <Menu.Item key="/debug">
      <Link to="/debug">Debug Contracts</Link>
    </Menu.Item>
    { web3Modal?.cachedProvider ? (<Button key="logout" type="primary" style={{marginRight:"16px"}} onClick={logoutOfWeb3Modal}>
      Logout
    </Button>) : ''}
  </Menu>
  </div>
  );
}

Header.defaultProps = {
  link: "https://github.com/austintgriffith/scaffold-eth",
  title: "🏗 scaffold-eth",
  subTitle: "forkable Ethereum dev stack focused on fast product iteration",
};

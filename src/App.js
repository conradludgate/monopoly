import React, { Component } from 'react';
import './App.css';
import Chat from './Chat';

class App extends Component {
	render() {
		let ws_url = new URL("http://localhost:8080");
		//ws_url.protocol = ws_url.protocol.replace("http", "ws");
		ws_url.pathname = "/ws/";

		return (
			<div className="App">
				<Chat ws={ws_url.toString()} />
			</div>
		);
	}
}

export default App;

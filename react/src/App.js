import React, { Component } from 'react';
import './App.css';
import Chat from './Chat';

class App extends Component {
	constructor(props) {
		super(props)

		let ws_url = new URL("http://localhost:8080");
		ws_url.protocol = ws_url.protocol.replace("http", "ws");
		ws_url.pathname = "/ws/";
		this.state = {
			ws: new WebSocket(ws_url)
		}
	}

	render() {
		return (
			<div className="App">
				<Chat ws={this.state.ws} />
			</div>
		);
	}
}

export default App;

import React, { Component } from 'react';
import Fetch from 'react-fetch';
// import './App.css';

class Chat extends Component {
	render() {
		return (
			<Fetch url={this.props.ws}>
				<Message />
			</Fetch>
		);
	}
}

class Message extends Component {
	render() {
		console.log(this.props);
		return (
			<p>This is a message</p>
		);
	}
}

export default Chat;

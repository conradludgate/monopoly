import React, { Component } from 'react';
import Fetch from 'react-fetch';
import io from 'socket.io-client';
// import './App.css';

class Chat extends Component {
	constructor(props) {
		super(props);

		this.state = {
			chatbox: "",
			messages: [],
			socket: io(props.ws)
		};

		this.state.socket.on("message", this.handleData.bind())
	}

	handleData(data) {
		//let result = JSON.parse(data);
		this.setState({
			messages: [...this.state.messages, {msg: data, id: this.state.messages.length}]
		});
	}

	onChange(e) {
		this.setState({
			chat: e.target.value
		});
	}

	onSubmit(e) {
		this.state.socket.send(this.state.chat);
		e.preventDefault();
	}

	render() {
		return (
			<div>
				<div>
					{this.state.messages.map((msg) =>
						<Message key={msg.id} msg={msg.msg} />
					)}
				</div>

				<form onSubmit={this.onSubmit}>
					<input type="text" value={this.state.chatbox} onChange={this.onChange} />
				</form>
			</div>
		);
	}
}

class Message extends Component {
	render() {
		return (
			<p>{this.props.msg}</p>
		);
	}
}

export default Chat;

import React, { Component } from 'react';

class Chat extends Component {
	constructor(props) {
		super(props);

		this.state = {
			chatbox: "",
			messages: [],
			socket: new WebSocket(props.ws)
		};

		this.handleChange = this.handleChange.bind(this);
    	this.handleSubmit = this.handleSubmit.bind(this);
    	this.handleData   = this.handleData.bind(this);
    	this.state.socket.addEventListener('message', this.handleData);
	}

	handleData(event) {
		console.debug(event);
		//let result = JSON.parse(data);
		this.setState({
			messages: [...this.state.messages, {msg: event.data, id: this.state.messages.length}]
		});
	}

	handleChange(event) {
		this.setState({
			chatbox: event.target.value
		});
	}

	handleSubmit(event) {
		this.state.socket.send(this.state.chatbox);
		this.setState({
			chatbox: ""
		})
		event.preventDefault();
	}

	render() {
		return (
			<div>
				<div>
					{this.state.messages.map((msg) =>
						<Message key={msg.id} msg={msg.msg} />
					)}
				</div>

				<form onSubmit={this.handleSubmit}>
					<input type="text" value={this.state.chatbox} onChange={this.handleChange} />
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

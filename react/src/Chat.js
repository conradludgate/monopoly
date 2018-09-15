import React, { Component } from 'react';
import Root, { websocket } from './protobuf.pb.js'

class Chat extends Component {
	constructor(props) {
		super(props);

		this.state = {
			chatbox: "",
			messages: [],
		};

		this.handleChange = this.handleChange.bind(this);
    	this.handleSubmit = this.handleSubmit.bind(this);
    	this.handleData   = this.handleData.bind(this);
    	this.handleClose  = this.handleClose.bind(this);
    	props.ws.addEventListener('message', this.handleData);
    	props.ws.addEventListener('close', this.handleClose);
    	props.ws.addEventListener('error', this.handleClose);
	}

	handleData(event) {
		let message = websocket.Websocket.decode(
			Buffer.from(event.data));

		if (message.type === websocket.Websocket.MessageType.ERROR) {
			console.log(websocket.Websocket.ErrorMessage.ErrorType[message.error.type], message.error.error);
			return
		}

		this.setState({
			messages: [...this.state.messages, {msg: message.chat.message, id: this.state.messages.length}]
		});
	}

	handleChange(event) {
		this.setState({
			chatbox: event.target.value
		});
	}

	handleSubmit(event) {
		let payload = {
			type: websocket.Websocket.MessageType.CHAT,
			chat: {
				user: "Oon",
				time: new Date(),
				message: this.state.chatbox
			}
		}

		let err = websocket.Websocket.verify(payload);
		if (err) throw Error(err);

		let message = websocket.Websocket.create(payload);
		let buffer = websocket.Websocket.encode(message).finish();
		console.debug(buffer.toString());
		// console.debug(Buffer(buffer.toString("ascii")));

		this.props.ws.send(buffer);
		this.setState({
			chatbox: ""
		})
		event.preventDefault();
	}

	handleClose(event) {
		this.setState({
			messages: [...this.state.messages, {msg: "Connection Error", id: this.state.messages.length}]
		});
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

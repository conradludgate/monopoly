import React, { Component } from 'react';
import { websocket } from './protobuf.pb.js'

class Chat extends Component {
	constructor(props) {
		super(props);

		this.state = {
			chatbox: "",
			messages: [],
		};

		this.handleChange  = this.handleChange.bind(this);
		this.handleSubmit  = this.handleSubmit.bind(this);
		this.handleData    = this.handleData.bind(this);
		this.handleMessage = this.handleMessage.bind(this);
		this.handleClose   = this.handleClose.bind(this);
	}

	componentDidMount() {
		this.props.ws.addEventListener('message', this.handleData);
		this.props.ws.addEventListener('close', this.handleClose);
		this.props.ws.addEventListener('error', this.handleClose);
	}

	handleData(event) {
		let fileReader = new FileReader();
		fileReader.onload = this.handleMessage;
		fileReader.readAsArrayBuffer(event.data);
	}

	handleMessage(event) {
		let message = websocket.Websocket.decode(Buffer.from(event.target.result));

		if (message.type === websocket.Websocket.MessageType.ERROR) {
			console.log(websocket.Websocket.ErrorMessage.ErrorType[message.error.type], message.error.error);
			return
		}

		this.setState({
			messages: [...this.state.messages, 
				{msg: message.chat, id: this.state.messages.length}
			]
		});
	}

	handleChange(event) {
		this.setState({
			chatbox: event.target.value
		});
	}

	handleSubmit(event) {
		let now = Date.now();
		let payload = {
			type: websocket.Websocket.MessageType.CHAT,
			chat: {
				user: "Oon",
				// time: {
				// 	seconds: Math.floor(now/1000),
				// 	nanos: 1000000 * now%1000
				// },
				message: this.state.chatbox
			}
		}

		let err = websocket.Websocket.verify(payload);
		if (err) throw Error(err);

		let message = websocket.Websocket.create(payload);
		let buffer = websocket.Websocket.encode(message).finish();

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
			<div>
				<span class="user">{this.props.msg.user}</span>
				<span class="message">{this.props.msg.message}</span>
			</div>
		);
	}
}

export default Chat;

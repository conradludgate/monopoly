package main

import (
	"io/ioutil"
	"log"
	"net/http"

	"github.com/gogo/protobuf/types"
	"github.com/gorilla/websocket"

	pb "github.com/conradludgate/monopoly/proto"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

// const (
// 	// MessageType
// 	ERROR = iota
// 	CHAT

// 	// ErrorType
// 	INVALID      = iota
// 	UNAUTHORIZED = 1
// 	BAD          = 2
// )

func WSWriteError(conn *websocket.Conn, typ pb.Websocket_ErrorMessage_ErrorType, msg string) error {
	_msg := &pb.Websocket{
		Type: pb.Websocket_ERROR,
		Message: &pb.Websocket_Error{&pb.Websocket_ErrorMessage{
			Type:  typ,
			Error: msg,
		}},
	}

	return WSWrite(conn, _msg)
}

func WSWrite(conn *websocket.Conn, wsMsg *pb.Websocket) error {
	b, err := wsMsg.Marshal()
	if err != nil {
		return err
	}

	w, err := conn.NextWriter(websocket.BinaryMessage)
	if err != nil {
		return err
	}

	log.Println("Writing", wsMsg)
	if _, err = w.Write(b); err != nil {
		return err
	}

	if err = w.Close(); err != nil {
		return err
	}
	return nil
}

func WSHandle(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}

	for {
		_, r, err := conn.NextReader()
		if err != nil {
			return
		}

		b, err := ioutil.ReadAll(r)
		if err != nil {
			if err = WSWriteError(conn, pb.Websocket_ErrorMessage_BAD, err.Error()); err != nil {
				log.Println(err.Error())
				return
			}
			continue
		}

		msg := &pb.Websocket{}
		if err := msg.Unmarshal(b); err != nil {
			if err = WSWriteError(conn, pb.Websocket_ErrorMessage_BAD, err.Error()); err != nil {
				log.Println(err.Error())
				return
			}
			continue
		}

		log.Println("Received", msg)

		switch msg.GetType() {

		case pb.Websocket_CHAT:
			chat := msg.GetChat()
			if chat != nil {
				chat.User = "Server"
				chat.Time = types.TimestampNow()

				if err := WSWrite(conn, msg); err != nil {
					log.Println(err.Error())
					return
				}
			}

		case pb.Websocket_ERROR:
			err := msg.GetError()
			if err != nil {
				log.Println(err)
			}

		}
	}
}

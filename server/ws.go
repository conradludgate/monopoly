package main

import (
	"io"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/golang/protobuf/proto"
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

func WriteError(w io.WriteCloser, typ pb.Websocket_ErrorMessage_ErrorType, msg string) error {
	_msg := &pb.Websocket{
		Type: pb.Websocket_ERROR,
		Message: &pb.Websocket_Error{
			&pb.Websocket_ErrorMessage{
				Type:  typ,
				Error: msg,
			},
		},
	}

	b, err := proto.Marshal(_msg)
	if err != nil {
		return err
	}
	log.Println(string(b))
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
		messageType, r, err := conn.NextReader()
		if err != nil {
			return
		}
		w, err := conn.NextWriter(messageType)
		if err != nil {
			return
		}
		b, err := ioutil.ReadAll(r)
		if err != nil {
			if err = WriteError(w, pb.Websocket_ErrorMessage_BAD, err.Error()); err != nil {
				log.Println(err.Error())
				return
			}
			continue
		}

		msg := &pb.Websocket{}
		if err := proto.Unmarshal(b, msg); err != nil {
			if err = WriteError(w, pb.Websocket_ErrorMessage_BAD, err.Error()); err != nil {
				log.Println(err.Error())
				return
			}
			continue
		}

		log.Println(msg)

		if err := w.Close(); err != nil {
			return
		}

	}
}

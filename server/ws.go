package main

import (
	"errors"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/gogo/protobuf/types"
	"github.com/gorilla/websocket"

	pb "github.com/conradludgate/monopoly/server/proto"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

var (
	ErrorBadMessage = errors.New("ws: Client provided a bad websocket message")
	ErrorBadProto   = errors.New("ws: Client provided a bad websocket protobuf")
)

func WSRead(conn *websocket.Conn) (*pb.Websocket, error) {
	_, r, err := conn.NextReader()
	if err != nil {
		return nil, err
	}

	b, err := ioutil.ReadAll(r)
	if err != nil {
		if err := WSWriteError(conn, pb.Websocket_ErrorMessage_BAD, err.Error()); err != nil {
			return nil, err
		}
		return nil, ErrorBadMessage
	}

	msg := &pb.Websocket{}
	if err := msg.Unmarshal(b); err != nil {
		if err := WSWriteError(conn, pb.Websocket_ErrorMessage_BAD, err.Error()); err != nil {
			return nil, err
		}
		return nil, ErrorBadProto
	}

	return msg, nil
}

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

	if _, err = w.Write(b); err != nil {
		return err
	}

	if err = w.Close(); err != nil {
		return err
	}
	return nil
}

func WSWriteAll(wsMsg *pb.Websocket) error {
	b, err := wsMsg.Marshal()
	if err != nil {
		return err
	}

	pm, err := websocket.NewPreparedMessage(websocket.BinaryMessage, b)
	if err != nil {
		return err
	}

	for conn, _ := range conns {
		if err := conn.WritePreparedMessage(pm); err != nil {
			conn.Close()
		}
	}

	return nil
}

var conns = map[*websocket.Conn]bool{}

func WSHandle(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}

	conns[conn] = true
	defer func() {
		delete(conns, conn)
	}()

	for {
		msg, err := WSRead(conn)
		if err == ErrorBadMessage || err == ErrorBadProto {
			continue
		}

		switch msg.GetType() {

		case pb.Websocket_CHAT:
			chat := msg.GetChat()
			if chat != nil {
				chat.Time = types.TimestampNow()

				if err := WSWriteAll(msg); err != nil {
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

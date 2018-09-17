# build react app
FROM node:10.10.0-alpine AS react

RUN npm i -g protobufjs yarn
ADD proto /home/proto
RUN mkdir -p /home/react/src && \
	pbjs -t static-module -w es6 /home/proto/* -o /home/react/src/protobuf.pb.js
WORKDIR /home/react

ADD react/node_modules ./node_modules/
ADD react/package.json react/yarn.lock ./
RUN yarn install && ls -la /home/react/src

ADD react .
RUN ls -la /home/react/src && yarn build

# build server
FROM golang:1.11.0-alpine3.8 AS go

# before-script
RUN mkdir -p src/github.com/conradludgate/monopoly/server && \
	apk add protobuf git && \
	go get -u github.com/golang/protobuf/protoc-gen-go && \
	go get github.com/gogo/protobuf/proto && \
	go get github.com/gogo/protobuf/protoc-gen-gogofaster && \
	go get github.com/gogo/protobuf/gogoproto && \
	go get -u github.com/go-bindata/go-bindata/...

# compile protobufs to go
ADD proto src/github.com/conradludgate/monopoly/proto
WORKDIR src/github.com/conradludgate/monopoly

RUN protoc -I=proto -I=$GOPATH/src -I=$GOPATH/src/github.com/gogo/protobuf/protobuf --gogofaster_out=\
Mgoogle/protobuf/any.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/struct.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/wrappers.proto=github.com/gogo/protobuf/types:proto \
proto/*.proto

WORKDIR server
COPY --from=react /home/react/build src
RUN go-bindata -o bindata.go -prefix src/ src/...

ADD server .
RUN go get && \
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /go/bin/server .

# run the server
FROM scratch

LABEl maintainer="Conrad Ludgate <oon@conradludgate.com>"

EXPOSE 8080
COPY --from=go /go/bin/server /server

ENTRYPOINT ["/server"]
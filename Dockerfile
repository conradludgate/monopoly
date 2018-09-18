# build react app
FROM node:10.10.0-alpine AS react

RUN npm i -g protobufjs yarn
ADD proto /home/proto
RUN mkdir -p /home/react/src && \
	pbjs -t static-module -w es6 /home/proto/* -o /home/react/src/protobuf.pb.js

ADD react/package.json react/yarn.lock /home/react/
RUN cd /home/react && yarn install

ADD react /home/react
RUN cd /home/react && yarn build

# build server
FROM golang:1.11.0-stretch AS go

# before-script
RUN mkdir -p /home/monopoly/server/proto && \
	apt-get update && \
	apt-get install -y --no-install-recommends protobuf-compiler && \
	go get -u github.com/golang/protobuf/protoc-gen-go && \
	go get github.com/gogo/protobuf/proto && \
	go get github.com/gogo/protobuf/protoc-gen-gogofaster && \
	go get github.com/gogo/protobuf/gogoproto && \
	go get -u github.com/go-bindata/go-bindata/...

# compile protobufs to go
ADD proto /home/monopoly/proto

RUN protoc -I=/home/monopoly/proto -I=$GOPATH/src -I=$GOPATH/src/github.com/gogo/protobuf/protobuf --gogofaster_out=\
Mgoogle/protobuf/any.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/struct.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/wrappers.proto=github.com/gogo/protobuf/types:/home/monopoly/server/proto \
/home/monopoly/proto/*.proto

COPY --from=react /home/react/build /home/monopoly/src
RUN go-bindata -o /home/monopoly/server/bindata.go -prefix /home/monopoly/src/ /home/monopoly/src/...

# check and install dependencies
ADD server /home/monopoly/server
RUN cd /home/monopoly/server && \
	go get && \
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /go/bin/server

# run the server
FROM scratch

LABEl maintainer="Conrad Ludgate <oon@conradludgate.com>"

EXPOSE 8080
COPY --from=go /go/bin/server /server

ENTRYPOINT ["/server"]
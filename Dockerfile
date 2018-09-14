# build react app
FROM node:latest AS react

ADD react /home/monopoly
WORKDIR /home/monopoly
RUN npm i && npm run-script build

# build server
FROM golang:latest AS go

RUN mkdir -p src/github.com/conradludgate/monopoly/server
WORKDIR src/github.com/conradludgate/monopoly/server/

COPY --from=react /home/monopoly/build src
RUN go get -u github.com/go-bindata/go-bindata/... && \
	go-bindata -o docker-go-bindata.go -prefix src/ src/...

ADD server .
RUN rm bindata.go && go get && \
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /go/bin/server .

# run the server
FROM scratch

COPY --from=go /go/bin/server /server

ENTRYPOINT ["/server"]
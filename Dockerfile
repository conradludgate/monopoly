# build react app
FROM node:latest AS react

# Add only package.json first
ADD package.json /home/monopoly/

WORKDIR /home/monopoly

# install dependencies
RUN npm i

# Then add src files to avoid installing deps everytime we edit the source
ADD . .

RUN npm run-script build

# build server
FROM golang:latest AS go

COPY server src/github.com/conradludgate/monopoly/server/

WORKDIR src/github.com/conradludgate/monopoly/server/

COPY --from=react /home/monopoly/build src

RUN go get -u github.com/go-bindata/go-bindata/... && \
	go-bindata -prefix src/ src/ && \
	go get && \
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -v -o /bin/server . 

# run the server
FROM scratch

COPY --from=go /bin/server .

ENTRYPOINT server
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

# build and run go server
FROM golang:latest

COPY server src/github.com/conradludgate/monopoly/server/

WORKDIR src/github.com/conradludgate/monopoly/server/
RUN go get && go build .

COPY --from=react /home/monopoly/build src/

ENTRYPOINT server
PROTODIR = proto
PROTOSRC = $(wildcard $(PROTODIR)/*.proto)

REACTDIR = react
REACTSRCDIR = $(REACTDIR)/src
REACTSRCS = $(wildcard $(REACTSRCDIR)/*)
REACTBUILDDIR = $(REACTDIR)/build

GOSRCDIR = server
GOSRCS = $(wildcard $(GOSRCDIR)/*.go) $(PROTOSRC:%.proto=%.pb.go)
GOSRCS += $(GOSRCDIR)/bindata.go
EXE = monopoly

NODESCRIPT ?= build
BINDATADBG ?= 

.PHONY: all release clean superclean remake

all: release

release: $(EXE)

$(EXE): $(GOSRCS)
	cd $(GOSRCDIR) && go get
	go build -o $(EXE) $(GOSRCDIR)/*.go

$(GOSRCDIR)/bindata.go: $(REACTBUILDDIR)
	go-bindata -o $(GOSRCDIR)/bindata.go $(BINDATADBG) -prefix $(REACTBUILDDIR)/ $(REACTBUILDDIR)/...

$(PROTODIR)/%.pb.go: $(PROTODIR)/%.proto
	protoc -I=proto -I=$$GOPATH/src -I=$$GOPATH/src/github.com/gogo/protobuf/protobuf --gogofaster_out=\
	Mgoogle/protobuf/any.proto=github.com/gogo/protobuf/types,\
	Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
	Mgoogle/protobuf/struct.proto=github.com/gogo/protobuf/types,\
	Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
	Mgoogle/protobuf/wrappers.proto=github.com/gogo/protobuf/types:proto proto/*.proto

$(REACTBUILDDIR): $(REACTSRCS) $(REACTDIR)/yarn.lock $(wildcard $(REACTDIR)/config/*) $(wildcard $(REACTDIR)/public/*) $(REACTSRCDIR)/protobuf.pb.js
	cd $(REACTDIR) && yarn $(NODESCRIPT)

$(REACTDIR)/yarn.lock: $(REACTDIR)/package.json
	cd $(REACTDIR) && yarn install

$(REACTSRCDIR)/protobuf.pb.js: $(PROTOSRC)
	pbjs -t static-module -w es6 $(PROTOSRC) -o $@

clean:
	rm -rf $(REACTBUILDDIR) $(EXE) $(GOSRCDIR)/bindata.go $(PROTOSRC:%.proto=%.pb.go) $(REACTSRCDIR)/protobuf.pb.js

superclean: clean
	rm -rf $(NODEMODULES)

remake: clean all
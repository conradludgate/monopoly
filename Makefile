PROTODIR = proto
PROTOSRC = $(wildcard $(PROTODIR)/*.proto)

REACTDIR = react
REACTSRCDIR = $(REACTDIR)/src
REACTSRCS = $(wildcard $(REACTSRCDIR)/*)
REACTBUILDDIR = $(REACTDIR)/build
NODEMODULES = $(REACTDIR)/node_modules

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

$(PROTODIR)/%.go: $(PROTODIR)/%.proto
	protoc -I=$(PROTODIR) --go_out=$(PROTODIR) $<

$(REACTBUILDDIR): $(REACTSRCS) $(NODEMODULES) $(wildcard $(REACTDIR)/config/*) $(wildcard $(REACTDIR)/public/*) 
	cd $(REACTDIR) && \
	npm run-script $(NODESCRIPT)

$(NODEMODULES): $(REACTDIR)/package.json $(REACTDIR)/package-lock.json $(REACTSRCDIR)/protobuf.pb.json
	cd $(REACTDIR) && \
	npm i

$(REACTSRCDIR)/protobuf.pb.js: $(PROTOSRC)
	pbjs -t static-module -w es6 $(PROTOSRC) -o $@

clean:
	rm -rf $(REACTBUILDDIR) $(EXE) $(GOSRCDIR)/bindata.go

superclean: clean
	rm -rf $(NODEMODULES)

remake: clean all
FROM golang:1.23

WORKDIR /go/src/app

COPY *.go .

RUN go mod init dispatch && go get
RUN go install

CMD dispatch
LABEL version="1.0.0"

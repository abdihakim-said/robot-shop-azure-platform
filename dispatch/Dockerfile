FROM golang:1.23

RUN apt-get update && apt-get upgrade -y libsqlite3-0 && rm -rf /var/lib/apt/lists/*

WORKDIR /go/src/app

COPY *.go .

RUN go mod init dispatch && go get
RUN go install

CMD dispatch

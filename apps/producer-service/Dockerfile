FROM golang:latest as build

ENV GO111MODULE=on
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOARCH=amd64

RUN mkdir -p /workdir
ADD . /workdir
WORKDIR /workdir

RUN go mod download
RUN go build -o ./server src/main.go

CMD ["./server"]
EXPOSE 8080
# DUE TO CGO enabled
#FROM scratch

#RUN apk add build-base
#COPY --from=build ./workdir/server ./server

#CMD ["./server"]
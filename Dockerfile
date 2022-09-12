FROM golang:latest as build

WORKDIR /opt
COPY ./main.go /opt
RUN go mod init main && go get -u github.com/gorilla/mux && go mod tidy
RUN CGO_ENABLED=0 go build -o /opt/main .

FROM alpine
WORKDIR /opt
COPY --from=build /opt/main /opt/main
RUN chmod +x main
ENV APP_NAME="Lu Romão"
ENV LISTEN_PORT=8000
expose 8000
CMD ["./main"]
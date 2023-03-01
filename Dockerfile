# Use a Golang base image
FROM golang:1.17-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy the Go modules file and download the dependencies
COPY go.mod .
COPY go.sum .
RUN go mod download

# Copy the application source code
COPY main.go .

# Build the binary with CGO disabled
RUN CGO_ENABLED=0 GOOS=linux go build -a -o my-app .

# Use a minimal Alpine Linux base image
FROM alpine:3.14

# Set the working directory
WORKDIR /app

# Copy the binary from the previous stage
COPY --from=builder /app/my-app .

# Run the binary
CMD ["./my-app"]

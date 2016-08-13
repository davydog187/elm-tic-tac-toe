import express from "express";
import { handleMove } from "./game";
import path from "path";
import { Server as WebSocketServer } from "ws";

const webSocketServer =  WebSocketServer({ port: 8080 });

const { PORT = 4000 } = process.env;

const app = express();

app.get("/", (request, response) => {
    response.sendFile(path.resolve(__dirname + "/../../build/build.html"));
});

webSocketServer.on('connection', function connection(ws) {

    ws.on('message', function incoming(message) {
        console.log("message: ", message);
        const parsedMessage = JSON.parse(message);
        const response = handleMove(parsedMessage);

        if (response) {
            webSocketServer.clients.forEach(client => client.send(JSON.stringify(response)));
        }
    });
});

app.listen(PORT);
console.log(`App started on port ${PORT}`);


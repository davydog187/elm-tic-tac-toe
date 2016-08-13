import { createGame, hasWon } from "./board";

const game = createGame(3, 3);
let turn;

export function handleMove({ player, x, y}) {
    console.log(`${player} is moving to (${x},${y})`);

    if (x >= game.x || y >= game.y || game.board[x][y]) {
        return null;
        /*
        return response.send({
            msgType: "INVALID",
            player,
            x,
            y
        });
        */
    }

    if (turn === player) {
        return null;
    }

    turn = player;
    game.board[x][y] = player;

    const won = hasWon(game);

    if (won) {
        return {
            msgType: "WIN",
            player: won,
            x,
            y
        };
    }

    return {
        msgType: "MOVED",
        player,
        x,
        y
    };
}

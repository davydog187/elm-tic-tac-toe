import { createGame, hasWon } from "./board";

const game = createGame(3, 3);
let turn;

export function handleMove({ player, x, y}) {
    console.log(`${player} is moving to (${x},${y})`);

    // Move is out of bounds, or existing move is at that position
    if (x >= game.x || y >= game.y || game.board[x][y]) {
        return null;
    }

    // Don't move out of turn
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

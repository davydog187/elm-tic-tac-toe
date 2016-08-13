function createBoard(x, y) {
    const board = new Array(y);

    for (var i = 0; i < y; ++i) {
        board[i] = new Array(x);
        board[i].fill(null);
    }

    return board;
}

export function createGame(x, y) {
    return {
        board: createBoard(x, y),
        x,
        y
    };
};

/**
 * Returns the name of who has won, or null
 *
 * @param {board} board
 * @returns {string}
 */
export function hasWon({ board, x, y }) {
    // Check horizontal
    for (var i = 0; i < y; ++i) {
        const first = board[i][0];
        if (first !== null && board[i].every(thing => thing === first)) {
            return first;
        }
    }

    // Check vertical
    for (var i = 0; i < x; ++i) {
        const first = board[0][i];

        if (first === null) {
            continue;
        }

        let same = true;

        for (var j = 0; j < y; ++j) {
            if (board[i][j] !== first) {
                same = false;
            }
        }

        if (same) {
            return first;
        }
    }

    // Check diagonals
    // TODO don't cheat here if we want arbitrary sized board
    const first = board[0][0];
    if (first !== null && first === board[1][1]
        && first === board[2][2]
    ) {
        return first;
    }

    const corner = board[0][2];
    if (corner !== null && corner === board[1][1]
        && corner === board[2][0]
    ) {
        return corner;
    }

    return null;
}

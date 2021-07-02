// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract RockPaperScissors {

    enum Move { Unknown, Rock, Paper, Scissors }
    enum Outcome { Pending, Win, Loose, Tie }
    enum Phase { Hint, Reveal, Finish }

    struct PlayerState {
        bytes32 hint;
        Move move;
        Outcome outcome;
    }

    address public player1;
    address public player2;

    Phase public phase;
    mapping(address => PlayerState) public players;

    // Nonce is a convenience unique number not to be repeated across games
    // It's used for obfuscating player's hint, so they can't be compared with moves from previous games
    uint public immutable nonce;

    modifier onlyPlayers() {
        require(msg.sender == player1 || msg.sender == player2, "Only players can call this function");
        _;
    }

    event PlayerHinted(address player);
    event PlayerRevealed(address player, Move move);
    event GameOutcome(address player, Outcome outcome);

    constructor(address _player1, address _player2, uint _nonce) {
        player1 = _player1;
        player2 = _player2;
        nonce = _nonce;
    }

    function generateHint(Move _move, uint _salt) public view returns (bytes32 _hint) {
        return keccak256(abi.encodePacked(nonce, msg.sender, _move, _salt));
    }

    function hint(bytes32 _hint) public onlyPlayers {
        address me = msg.sender;
        address adversary = (me == player1) ? player2 : player1;

        require(phase == Phase.Hint, "Not at hint phase!");
        require(_hint != 0, "Provide a valid hint!");
        require(players[me].hint == 0, "You already hinted!");

        players[me].hint = _hint;
        emit PlayerHinted(me);

        if (players[adversary].hint != 0) {
            // both players hinted already, move on phase
            phase = Phase.Reveal;
        }
    }

    function reveal(Move _move, uint _salt) public onlyPlayers {
        address me = msg.sender;
        address adversary = (me == player1) ? player2 : player1;

        require(phase == Phase.Reveal, "Not at reveal phase!");
        require(_move != Move.Unknown, "Pick a specific move!");
        require(players[me].move == Move.Unknown, "You already revealed your move!");

        bytes32 expectedHint = generateHint(_move, _salt);
        require(players[me].hint == expectedHint, "These are not the droids you are looking for!");

        players[me].move = _move;
        emit PlayerRevealed(me, _move);

        if (players[adversary].move != Move.Unknown) {
            // both players revealed their move already, finish game
            decideOutcomes();
            phase = Phase.Finish;
        }
    }

    function decideOutcomes() internal {
        Move move1 = players[player1].move;
        Move move2 = players[player2].move;

        if (move1 == move2) {
            players[player1].outcome = Outcome.Tie;
            players[player2].outcome = Outcome.Tie;
        } else if (
            (move1 == Move.Rock && move2 == Move.Scissors) ||
            (move1 == Move.Scissors && move2 == Move.Paper) ||
            (move1 == Move.Paper && move2 == Move.Rock)
        ){
            players[player1].outcome = Outcome.Win;
            players[player2].outcome = Outcome.Loose;
        } else {
            players[player1].outcome = Outcome.Loose;
            players[player2].outcome = Outcome.Win;
        }

        emit GameOutcome(player1, players[player1].outcome);
        emit GameOutcome(player2, players[player2].outcome);
    }

    function endGame() public onlyPlayers {
        selfdestruct(payable(msg.sender));
    }
}
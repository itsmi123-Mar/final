% Activity 10: Tic-Tac-Toe in Prolog (student version B)
% Part A: replace each __B#__ blank.  Part B: find and fix 4 bugs in Task 4.

:- module(tictactoe, [
    winning_line/3,
    win/2,
    board_full/1,
    game_over/2,
    move/4,
    computer_move/2,
    display_board/1
]).

% ==========================================
% TASK 1: Winning Lines Knowledge Base
% ==========================================
winning_line(1, 2, 3).
winning_line(4, 5, 6).
winning_line(7, 8, 9).

winning_line(1, 4, 7).
winning_line(2, 5, 8).
winning_line(3, 6, 9).

winning_line(1, 5, 9).
winning_line(3, 5, 7).


% ==========================================
% TASK 2: Board State Inspection & Conditions
% ==========================================

% Succeeds if Player occupies three squares forming a winning line.
win(Board, Player) :-
    winning_line(A, B, C),
    nth1(A, Board, Player),
    nth1(B, Board, Player),
    nth1(C, Board, Player).

% Succeeds if no empty squares ('e') remain on the board.
board_full(Board) :-
    \+ member(e, Board).

% Binds Winner to x, o, or draw.
game_over(Board, x) :-
    win(Board, x), !.
game_over(Board, o) :-
    win(Board, o), !.
game_over(Board, draw) :-
    board_full(Board), !.


% ==========================================
% TASK 3: Move Execution & Helper Predicates
% ==========================================

% Places Player's mark at Pos (1-9) if that square is empty.
move(Board, Pos, Player, NewBoard) :-
    nth1(Pos, Board, e),
    replace_at(Board, Pos, Player, NewBoard).

% Replaces the element at 1-based Index with Value.
replace_at([_|T], 1, X, [X|T]) :- !.
replace_at([H|T], I, X, [H|R]) :-
    I > 1,
    I1 is I - 1,
    replace_at(T, I1, X, R).


% ==========================================
% TASK 4: AI Strategy (Computer plays 'o')
% ==========================================

% Win immediately if possible
computer_move(Board, NewBoard) :-
    move(Board, _Pos, o, NewBoard),
    win(NewBoard, o), !.

% Block 'x' if x threatens to win on the next turn
computer_move(Board, NewBoard) :-
    move(Board, Pos, x, TempBoard),
    win(TempBoard, x),
    move(Board, Pos, o, NewBoard), !.

% Take the center square if open
computer_move(Board, NewBoard) :-
    move(Board, 5, o, NewBoard), !.

% Take any first available open square
computer_move(Board, NewBoard) :-
    move(Board, _Pos, o, NewBoard), !.


% ==========================================
% Provided code (do not change): Display Board
% ==========================================
display_board([A,B,C, D,E,F, G,H,I]) :-
    format(' ~w | ~w | ~w ~n', [A,B,C]),
    format('---+---+---~n'),
    format(' ~w | ~w | ~w ~n', [D,E,F]),
    format('---+---+---~n'),
    format(' ~w | ~w | ~w ~n~n', [G,H,I]).

"""
西洋棋核心邏輯 v1
作者：嘿美（電競陪玩貓頭鷹）幫主人寫的
"""

# 棋盤表示法：使用 FEN 標準字串最方便，但這裡先用 8x8 二維陣列
# 棋子代號：大寫 = 白方, 小寫 = 黑方
# K=王 Q=后 R=車 B=象 N=馬 P=兵

INITIAL_BOARD = [
    ['r', 'n', 'b', 'q', 'k', 'b', 'n', 'r'],
    ['p', 'p', 'p', 'p', 'p', 'p', 'p', 'p'],
    ['.', '.', '.', '.', '.', '.', '.', '.'],
    ['.', '.', '.', '.', '.', '.', '.', '.'],
    ['.', '.', '.', '.', '.', '.', '.', '.'],
    ['.', '.', '.', '.', '.', '.', '.', '.'],
    ['P', 'P', 'P', 'P', 'P', 'P', 'P', 'P'],
    ['R', 'N', 'B', 'Q', 'K', 'B', 'N', 'R'],
]

class ChessGame:
    def __init__(self):
        self.board = [row[:] for row in INITIAL_BOARD]
        self.current_turn = 'white'  # white 先手
        self.move_history = []

    def in_bounds(self, r, c):
        return 0 <= r < 8 and 0 <= c < 8

    def get_piece(self, r, c):
        if not self.in_bounds(r, c):
            return '.'
        return self.board[r][c]

    def is_white(self, piece):
        return piece.isupper()

    def is_black(self, piece):
        return piece.islower() and piece != '.'

    def is_enemy(self, piece, color):
        if piece == '.':
            return False
        return (color == 'white' and piece.islower()) or (color == 'black' and piece.isupper())

    def get_moves(self, r, c):
        """取得 (r,c) 位置棋子的所有合法走法（暫不處理將軍/王車易位/吃過路兵）"""
        piece = self.get_piece(r, c)
        if piece == '.':
            return []
        color = 'white' if self.is_white(piece) else 'black'
        piece_type = piece.lower()
        moves = []

        if piece_type == 'p':  # 兵
            direction = -1 if color == 'white' else 1
            start_row = 6 if color == 'white' else 1
            # 前進一格
            nr, nc = r + direction, c
            if self.in_bounds(nr, nc) and self.get_piece(nr, nc) == '.':
                moves.append((nr, nc))
                # 起始兩格
                nr2 = r + 2 * direction
                if r == start_row and self.get_piece(nr2, nc) == '.':
                    moves.append((nr2, nc))
            # 斜吃
            for dc in [-1, 1]:
                nr, nc = r + direction, c + dc
                if self.in_bounds(nr, nc) and self.is_enemy(self.get_piece(nr, nc), color):
                    moves.append((nr, nc))

        elif piece_type == 'n':  # 馬
            for dr, dc in [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)]:
                nr, nc = r + dr, c + dc
                if self.in_bounds(nr, nc) and not self._is_friendly(self.get_piece(nr, nc), color):
                    moves.append((nr, nc))

        elif piece_type in ('b', 'r', 'q'):  # 象/車/后
            directions = []
            if piece_type in ('b', 'q'):
                directions += [(-1,-1),(-1,1),(1,-1),(1,1)]
            if piece_type in ('r', 'q'):
                directions += [(-1,0),(1,0),(0,-1),(0,1)]
            for dr, dc in directions:
                nr, nc = r + dr, c + dc
                while self.in_bounds(nr, nc):
                    target = self.get_piece(nr, nc)
                    if target == '.':
                        moves.append((nr, nc))
                    elif self.is_enemy(target, color):
                        moves.append((nr, nc))
                        break
                    else:
                        break
                    nr += dr
                    nc += dc

        elif piece_type == 'k':  # 王（簡化版，不處理將軍判定）
            for dr in [-1, 0, 1]:
                for dc in [-1, 0, 1]:
                    if dr == 0 and dc == 0:
                        continue
                    nr, nc = r + dr, c + dc
                    if self.in_bounds(nr, nc) and not self._is_friendly(self.get_piece(nr, nc), color):
                        moves.append((nr, nc))

        return moves

    def _is_friendly(self, piece, color):
        if piece == '.':
            return False
        return (color == 'white' and piece.isupper()) or (color == 'black' and piece.islower())

    def make_move(self, fr, fc, tr, tc):
        """嘗試移動，回傳是否成功 + 被吃的棋子"""
        piece = self.get_piece(fr, fc)
        if piece == '.':
            return False, None
        color = 'white' if self.is_white(piece) else 'black'
        if color != self.current_turn:
            return False, None
        if (tr, tc) not in self.get_moves(fr, fc):
            return False, None

        captured = self.board[tr][tc]
        self.board[tr][tc] = piece
        self.board[fr][fc] = '.'

        # 兵升變（簡化：到底線自動變后）
        if piece.lower() == 'p' and (tr == 0 or tr == 7):
            self.board[tr][tc] = piece.upper() if piece.isupper() else 'q'

        self.move_history.append(((fr, fc), (tr, tc), captured))
        self.current_turn = 'black' if self.current_turn == 'white' else 'white'
        return True, captured

    def print_board(self):
        print("\n    a   b   c   d   e   f   g   h")
        print("  ┌───┬───┬───┬───┬───┬───┬───┬───┐")
        for i, row in enumerate(self.board):
            cells = " │ ".join(p if p != '.' else ' ' for p in row)
            print(f"{8-i} │ {cells} │ {8-i}")
            if i < 7:
                print("  ├───┼───┼───┼───┼───┼───┼───┼───┤")
        print("  └───┴───┴───┴───┴───┴───┴───┴───┘")
        print("    a   b   c   d   e   f   g   h")
        print(f"  現在輪到：{'♔ 白方' if self.current_turn == 'white' else '♚ 黑方'}\n")


# 快速測試
if __name__ == '__main__':
    game = ChessGame()
    game.print_board()
    print("嘗試移動白兵 e2→e4：")
    ok, cap = game.make_move(6, 4, 4, 4)
    print(f"成功={ok}, 吃到={cap}")
    game.print_board()
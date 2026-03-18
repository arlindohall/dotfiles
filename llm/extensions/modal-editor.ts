/**
 * Modal Editor - vim-like modal editing example
 *
 * Usage: pi --extension ./examples/extensions/modal-editor.ts
 *
 * - Escape: insert → normal mode (in normal mode, aborts agent)
 * - i: normal → insert mode
 * - hjkl: navigation in normal mode
 * - ctrl+c, ctrl+d, etc. work in both modes
 */

import { CustomEditor, type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

// Normal mode key mappings: key -> escape sequence (or null for mode switch, or "custom" for special handling)
const NORMAL_KEYS: Record<string, string | null | "custom"> = {
	h: "\x1b[D", // left
	j: "\x1b[B", // down
	k: "\x1b[A", // up
	l: "\x1b[C", // right
	"0": "\x01", // line start (ctrl+a)
	$: "\x05", // line end (ctrl+e)
	x: "\x1b[3~", // delete char
	i: null, // insert mode
	a: null, // append (insert + right)
	w: "\x1b[1;5C", // word forward (ctrl+right)
	b: "\x1b[1;5D", // word backward (ctrl+left)
	W: "custom", // WORD forward (until whitespace)
	B: "custom", // WORD backward (until whitespace)
	e: "custom", // end of word
	E: "custom", // end of WORD (until whitespace)
	G: "\x1b[F", // end of buffer (end key - moves to end of line, repeated goes to last line)
};

class ModalEditor extends CustomEditor {
	private mode: "normal" | "insert" = "insert";
	private pendingKey: string | null = null;

	// Get flat cursor position in text (handling multi-line)
	private getFlatCursorPos(): number {
		const cursor = this.getCursor();
		const lines = this.getLines();
		let pos = 0;
		for (let i = 0; i < cursor.line && i < lines.length; i++) {
			pos += lines[i]!.length + 1; // +1 for newline
		}
		pos += cursor.col;
		return pos;
	}

	// Move cursor to flat position by calculating delta and sending arrow keys
	private moveCursorToFlatPos(targetPos: number): void {
		const currentPos = this.getFlatCursorPos();
		const delta = targetPos - currentPos;
		if (delta > 0) {
			for (let i = 0; i < delta; i++) super.handleInput("\x1b[C"); // right
		} else if (delta < 0) {
			for (let i = 0; i < -delta; i++) super.handleInput("\x1b[D"); // left
		}
	}

	// Move cursor forward to start of next WORD (whitespace-delimited)
	// W in vim: skip current non-whitespace, then skip whitespace
	private moveWORDForward(): void {
		const text = this.getText();
		let pos = this.getFlatCursorPos();
		// Skip non-whitespace (current WORD)
		while (pos < text.length && !/\s/.test(text[pos]!)) pos++;
		// Skip whitespace
		while (pos < text.length && /\s/.test(text[pos]!)) pos++;
		this.moveCursorToFlatPos(pos);
	}

	// Move cursor backward to start of previous WORD (whitespace-delimited)
	// B in vim: go back one, skip whitespace, then skip non-whitespace to find WORD start
	private moveWORDBackward(): void {
		const text = this.getText();
		let pos = this.getFlatCursorPos();
		// Move back one to get off current position
		if (pos > 0) pos--;
		// Skip whitespace backward
		while (pos > 0 && /\s/.test(text[pos]!)) pos--;
		// Skip non-whitespace backward to find start of WORD
		while (pos > 0 && !/\s/.test(text[pos - 1]!)) pos--;
		this.moveCursorToFlatPos(pos);
	}

	// Move cursor to end of current word (alphanumeric boundaries)
	// e in vim: move forward one, skip whitespace, move to end of word
	private moveToEndOfWord(): void {
		const text = this.getText();
		const isWordChar = (c: string) => /\w/.test(c);
		let pos = this.getFlatCursorPos();
		// Move forward one
		if (pos < text.length) pos++;
		// Skip whitespace
		while (pos < text.length && /\s/.test(text[pos]!)) pos++;
		// Move to end of current word-type sequence
		if (pos < text.length && isWordChar(text[pos]!)) {
			// On word char - skip to end of word
			while (pos < text.length - 1 && isWordChar(text[pos + 1]!)) pos++;
		} else if (pos < text.length) {
			// On punctuation - skip to end of punctuation
			while (pos < text.length - 1 && !isWordChar(text[pos + 1]!) && !/\s/.test(text[pos + 1]!)) pos++;
		}
		this.moveCursorToFlatPos(pos);
	}

	// Move cursor to end of current WORD (whitespace-delimited)
	// E in vim: move forward one, skip whitespace, move to last non-whitespace
	private moveToEndOfWORD(): void {
		const text = this.getText();
		let pos = this.getFlatCursorPos();
		// Move forward one
		if (pos < text.length) pos++;
		// Skip whitespace
		while (pos < text.length && /\s/.test(text[pos]!)) pos++;
		// Move to end of non-whitespace
		while (pos < text.length - 1 && !/\s/.test(text[pos + 1]!)) pos++;
		this.moveCursorToFlatPos(pos);
	}

	handleInput(data: string): void {
		// Escape toggles to normal mode, or passes through for app handling
		if (matchesKey(data, "escape")) {
			if (this.mode === "insert") {
				this.mode = "normal";
			} else {
				super.handleInput(data); // abort agent, etc.
			}
			return;
		}

		// Insert mode: pass everything through
		if (this.mode === "insert") {
			super.handleInput(data);
			return;
		}

		// Handle gg (go to beginning)
		if (this.pendingKey === "g") {
			this.pendingKey = null;
			if (data === "g") {
				// gg: go to beginning of buffer (home key)
				super.handleInput("\x1b[H");
				return;
			}
			// g followed by something else - ignore the g and process this key
		}

		// Start of gg sequence
		if (data === "g") {
			this.pendingKey = "g";
			return;
		}

		// Normal mode: check mapped keys
		if (data in NORMAL_KEYS) {
			const seq = NORMAL_KEYS[data];
			if (data === "i") {
				this.mode = "insert";
			} else if (data === "a") {
				this.mode = "insert";
				super.handleInput("\x1b[C"); // move right first
			} else if (seq === "custom") {
				// Handle custom motions
				if (data === "W") this.moveWORDForward();
				else if (data === "B") this.moveWORDBackward();
				else if (data === "e") this.moveToEndOfWord();
				else if (data === "E") this.moveToEndOfWORD();
			} else if (seq) {
				super.handleInput(seq);
			}
			return;
		}

		// Pass control sequences (ctrl+c, etc.) to super, ignore printable chars
		if (data.length === 1 && data.charCodeAt(0) >= 32) return;
		super.handleInput(data);
	}

	render(width: number): string[] {
		const lines = super.render(width);
		if (lines.length === 0) return lines;

		// Add mode indicator to bottom border
		const label = this.mode === "normal" ? " NORMAL " : " INSERT ";
		const last = lines.length - 1;
		if (visibleWidth(lines[last]!) >= label.length) {
			lines[last] = truncateToWidth(lines[last]!, width - label.length, "") + label;
		}
		return lines;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setEditorComponent((tui, theme, kb) => new ModalEditor(tui, theme, kb));
	});
}

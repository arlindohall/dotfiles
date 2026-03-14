use std::env;
use std::io::{self, BufRead};
use std::process;

const SWEAR_WORDS_URL: &str = "http://www.bannedwordlist.com/lists/swearWords.txt";

fn fetch_swear_words() -> Result<Vec<String>, String> {
    eprintln!("Downloading swear words from {}", SWEAR_WORDS_URL);

    let output = process::Command::new("curl")
        .args(["-fsSL", SWEAR_WORDS_URL])
        .output()
        .map_err(|e| format!("Failed to run curl: {}", e))?;

    if !output.status.success() {
        return Err(format!(
            "curl failed with status {}",
            output.status
        ));
    }

    let body = String::from_utf8(output.stdout)
        .map_err(|e| format!("Invalid UTF-8 from response: {}", e))?;

    let words: Vec<String> = body
        .lines()
        .map(|l| l.trim().to_string())
        .filter(|l| !l.is_empty())
        .collect();

    Ok(words)
}

fn build_pattern(words: &[String]) -> String {
    words
        .iter()
        .map(|w| regex_escape(w))
        .collect::<Vec<_>>()
        .join("|")
}

/// Minimal regex escaping for word-boundary patterns.
fn regex_escape(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '.' | '+' | '*' | '?' | '(' | ')' | '[' | ']' | '{' | '}' | '^' | '$' | '|'
            | '\\' => {
                out.push('\\');
                out.push(c);
            }
            _ => out.push(c),
        }
    }
    out
}

fn search_with_rg(pattern: &str, extra_args: &[&str]) -> bool {
    let status = process::Command::new("rg")
        .arg("-w")
        .arg(pattern)
        .args(extra_args)
        .status()
        .expect("Failed to run rg");
    status.success()
}

fn search_stdin(words: &[String]) -> bool {
    let stdin = io::stdin();
    for (line_number, line) in stdin.lock().lines().enumerate() {
        let line = line.expect("Failed to read line");
        for word in words {
            let pattern = format!(r"(?i)\b{}\b", regex_escape(word));
            // Use a simple case-insensitive whole-word check via regex crate would be
            // cleaner, but to keep zero dependencies we call rg on each line via echo.
            // Instead, do a simple substring word-boundary check inline.
            if line_contains_word(&line, word) {
                eprintln!("Found swear word in line: {}:{}", line_number, 0);
                return false;
            }
        }
    }
    true
}

fn line_contains_word(line: &str, word: &str) -> bool {
    let lower_line = line.to_lowercase();
    let lower_word = word.to_lowercase();

    let mut start = 0;
    while let Some(pos) = lower_line[start..].find(&lower_word) {
        let abs_pos = start + pos;
        let before_ok = abs_pos == 0
            || !lower_line[..abs_pos]
                .chars()
                .last()
                .unwrap_or(' ')
                .is_alphanumeric();
        let end = abs_pos + lower_word.len();
        let after_ok = end >= lower_line.len()
            || !lower_line[end..]
                .chars()
                .next()
                .unwrap_or(' ')
                .is_alphanumeric();
        if before_ok && after_ok {
            return true;
        }
        start = abs_pos + 1;
    }
    false
}

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();

    let words = fetch_swear_words().unwrap_or_else(|e| {
        eprintln!("Error fetching swear words: {}", e);
        process::exit(2);
    });

    let pattern = build_pattern(&words);

    let stdin_is_tty = atty();

    let ok = if !stdin_is_tty {
        eprintln!(
            "Searching for {} swear words in standard in...",
            words.len()
        );
        search_stdin(&words)
    } else if !args.is_empty() {
        eprintln!(
            "Searching for {} swear words in files={:?}...",
            words.len(),
            args
        );
        let file_args: Vec<&str> = args.iter().map(|s| s.as_str()).collect();
        search_with_rg(&pattern, &file_args)
    } else {
        eprintln!(
            "Searching for {} swear words in current directory...",
            words.len()
        );
        search_with_rg(&pattern, &[])
    };

    if !ok {
        process::exit(1);
    }
}

/// Detect whether stdin is a terminal without any external crates.
fn atty() -> bool {
    #[cfg(unix)]
    {
        // SAFETY: isatty is always safe to call with a valid fd number.
        unsafe { libc_isatty(0) }
    }
    #[cfg(not(unix))]
    {
        // On non-unix platforms assume not a tty (conservative).
        false
    }
}

#[cfg(unix)]
fn libc_isatty(fd: i32) -> bool {
    extern "C" {
        fn isatty(fd: i32) -> i32;
    }
    unsafe { isatty(fd) != 0 }
}

use std::io::{BufRead, BufReader, Write};
use std::net::TcpListener;

const SUCCESS_HTML: &str = r#"<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Login successful</title>
  <style>
    body { font-family: sans-serif; display: flex; align-items: center; justify-content: center;
           height: 100vh; margin: 0; background: #1a1a2e; color: #e0e0e0; }
    .box { text-align: center; }
    h1 { color: #7c3aed; }
  </style>
</head>
<body>
  <div class="box">
    <h1>Login successful</h1>
    <p>You can close this tab and return to Rivet.</p>
  </div>
</body>
</html>"#;

const ERROR_HTML: &str = r#"<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Login failed</title>
  <style>
    body { font-family: sans-serif; display: flex; align-items: center; justify-content: center;
           height: 100vh; margin: 0; background: #1a1a2e; color: #e0e0e0; }
    .box { text-align: center; }
    h1 { color: #dc2626; }
  </style>
</head>
<body>
  <div class="box">
    <h1>Login failed</h1>
    <p>The authorization was denied or an error occurred. You can close this tab.</p>
  </div>
</body>
</html>"#;

/// Starts a one-shot TCP loopback OAuth callback server (RFC 8252).
///
/// Immediately emits the Tauri event `oauth://port` with payload `{ "port": N }` so
/// the frontend can construct the auth URL and open the browser. Then blocks until
/// the browser hits the loopback redirect URL, responds with a success/error page,
/// and returns the raw query string (e.g. `"code=abc&state=xyz"`).
#[tauri::command]
pub fn start_oauth_callback_server(app_handle: tauri::AppHandle) -> Result<String, String> {
    let listener = TcpListener::bind("127.0.0.1:0")
        .map_err(|e| format!("Failed to bind OAuth callback server: {e}"))?;

    let port = listener
        .local_addr()
        .map_err(|e| format!("Failed to get local address: {e}"))?
        .port();

    app_handle
        .emit_all("oauth://port", serde_json::json!({ "port": port }))
        .map_err(|e| format!("Failed to emit port event: {e}"))?;

    accept_callback(&listener)
}

fn accept_callback(listener: &TcpListener) -> Result<String, String> {
    let (mut stream, _) = listener
        .accept()
        .map_err(|e| format!("Failed to accept OAuth callback: {e}"))?;

    let request_line = BufReader::new(&stream)
        .lines()
        .next()
        .ok_or("Empty HTTP request")?
        .map_err(|e| format!("Failed to read request line: {e}"))?;

    let query_string = extract_query(&request_line);
    let html = if query_string.contains("error=") { ERROR_HTML } else { SUCCESS_HTML };

    let response = format!(
        "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
        html.len(),
        html
    );
    stream
        .write_all(response.as_bytes())
        .map_err(|e| format!("Failed to write response: {e}"))?;

    Ok(query_string)
}

/// Extracts the query string from an HTTP request line.
/// "GET /?code=abc&state=xyz HTTP/1.1" → "code=abc&state=xyz"
fn extract_query(request_line: &str) -> String {
    let parts: Vec<&str> = request_line.splitn(3, ' ').collect();
    if parts.len() < 2 {
        return String::new();
    }
    match parts[1].find('?') {
        Some(pos) => parts[1][pos + 1..].to_string(),
        None => String::new(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_query() {
        assert_eq!(extract_query("GET /?code=abc&state=xyz HTTP/1.1"), "code=abc&state=xyz");
        assert_eq!(extract_query("GET / HTTP/1.1"), "");
        assert_eq!(extract_query("GET /? HTTP/1.1"), "");
        assert_eq!(extract_query(""), "");
    }
}

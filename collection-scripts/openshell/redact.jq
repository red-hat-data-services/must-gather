# Used for both Kubernetes JSON and individual gateway log lines.
def redact_text:
  gsub("(?i)https?://[^/\\s\"<>]*@"; "https://[REDACTED]@")
  # Query parameters and fragments can carry arbitrary signing credentials.
  # Keep the URL host/path, but do not allowlist any query parameters.
  | gsub("(?i)(?<url>https?://[^?\\s\"<>#]+)[?#][^\\s\"<>]*"; "\(.url)[REDACTED]")
  | gsub("(?i)/bot[0-9]+:[A-Za-z0-9_-]+"; "/bot[REDACTED]")
  | gsub("(?i)(?<prefix>(access_token|token)=)[^&\\s\"<>]+"; "\(.prefix)[REDACTED]")
  | gsub("(?i)(?<prefix>bearer[ \\t]+)[A-Za-z0-9._~+/-]+=*"; "\(.prefix)[REDACTED]")
  | gsub("(?i)(?<prefix>authorization[\"' :\\t=]+)[^,;\\r\\n}]+"; "\(.prefix)[REDACTED]")
  | gsub("eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+"; "[REDACTED]");

def sanitize:
  if type == "object" then
      # ConfigMap entries can contain opaque TOML, JSON, or embedded secrets.
      # Remove payloads before descending into arbitrary user-defined keys.
      (if .kind? == "ConfigMap" then del(.data, .binaryData) else . end)
      | (if (.metadata? | type) == "object" then
           del(.metadata.managedFields, .metadata.annotations)
         else . end)
      | (if (.env? | type) == "array" then
           .env |= map(if type == "object" then del(.value) else . end)
         else . end)
      | map_values(sanitize)
  elif type == "array" then map(sanitize)
  elif type == "string" then redact_text
  else . end;

if $logs then redact_text else sanitize end

# Used for both Kubernetes JSON and individual gateway log lines.
def redact_text:
  gsub("(?i)https?://[^/\\s\"<>]*@"; "https://[REDACTED]@")
  | gsub("(?i)/bot[0-9]+:[A-Za-z0-9_-]+"; "/bot[REDACTED]")
  | gsub("(?i)(?<prefix>(access_token|token)=)[^&\\s\"<>]+"; "\(.prefix)[REDACTED]")
  | gsub("(?i)(?<prefix>bearer[ \\t]+)[A-Za-z0-9._~+/-]+=*"; "\(.prefix)[REDACTED]")
  | gsub("(?i)(?<prefix>authorization[\"' :\\t=]+)[^,;\\r\\n}]+"; "\(.prefix)[REDACTED]")
  | gsub("eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+"; "[REDACTED]");

def sanitize:
  walk(
    if type == "object" then
      del(.metadata.managedFields)
      | (if .metadata.annotations then
           del(.metadata.annotations["kubectl.kubernetes.io/last-applied-configuration"])
         else . end)
      | (if (.env? | type) == "array" then .env |= map(del(.value)) else . end)
      # ConfigMap entries can contain opaque TOML, JSON, or embedded secrets.
      # Omit all values rather than guessing from user-defined key names.
      | (if .kind? == "ConfigMap" then del(.data, .binaryData) else . end)
    elif type == "string" then redact_text
    else . end
  );

if $logs then redact_text else sanitize end

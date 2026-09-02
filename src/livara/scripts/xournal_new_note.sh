#!/usr/bin/env bash
set -Eeuo pipefail

note_dir="${XOURNAL_VAULT_DIR:-$HOME/Vault/04 - Xournal++}"
date_title="$(date '+%Y-%m-%d')"
note="$note_dir/${date_title}.xopp"
settings_file="${XDG_CONFIG_HOME:-$HOME/.config}/xournalpp/settings.xml"

if ! command -v xournalpp >/dev/null 2>&1; then
  notify-send -u critical "Xournal++" "xournalpp is not installed" 2>/dev/null || true
  exit 127
fi

mkdir -p "$note_dir"

if [[ -e "$note" ]]; then
  exec xournalpp "$note"
fi

# Prefer the versioned Vault template when Home Manager provides one.
# Fall back to the live Xournal++ settings when no template asset is configured.
if [[ -n "${XOURNAL_TEMPLATE_PATH:-}" && -r "${XOURNAL_TEMPLATE_PATH}" ]]; then
  cp "${XOURNAL_TEMPLATE_PATH}" "$note"
  exec xournalpp "$note"
fi

# Reproduce the configured Xournal++ page template in a valid new journal.
template_data=""
if [[ -r "$settings_file" ]]; then
  template_data="$(sed -n 's/.*<property[[:space:]]\+name="pageTemplate"[[:space:]]\+value="\([^"]*\)".*/\1/p' "$settings_file" | head -n 1)"
  template_data="$(printf '%s' "$template_data" | sed \
    -e 's/&#10;/\n/g' \
    -e 's/&#13;/\r/g' \
    -e 's/&quot;/"/g' \
    -e 's/&apos;/'"'"'/g' \
    -e 's/&lt;/</g' \
    -e 's/&gt;/>/g' \
    -e 's/&amp;/\&/g')"
fi

template_value() {
  local key="$1" line
  while IFS= read -r line; do
    if [[ "$line" == "$key="* ]]; then
      printf '%s\n' "${line#*=}"
      return
    fi
  done <<< "$template_data"
}

size="$(template_value size || true)"
width="${size%x*}"
height="${size#*x}"
background_color="$(template_value backgroundColor || true)"
background_type="$(template_value backgroundType || true)"
background_config="$(template_value backgroundTypeConfig || true)"

[[ "$width" =~ ^[0-9]+([.][0-9]+)?$ ]] || width="595.275591"
[[ "$height" =~ ^[0-9]+([.][0-9]+)?$ ]] || height="841.889764"
[[ "$background_color" =~ ^#[0-9a-fA-F]{6,8}$ ]] || background_color="#ffffffff"
case "$background_type" in
  plain|ruled|lined|staves|graph|dotted|isodotted|isograph) ;;
  *) background_type="lined" ;;
esac

xml_escape() {
  sed -e 's/&/\&amp;/g' -e 's/"/\&quot;/g' -e "s/'/\&apos;/g" -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

background_config_xml=""
if [[ -n "$background_config" ]]; then
  escaped_config="$(printf '%s' "$background_config" | xml_escape)"
  background_config_xml=" config=\"$escaped_config\""
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
xml_tmp="$tmp_dir/$date_title.xopp.xml"
cat > "$xml_tmp" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<xournal creator="Xournal++" fileversion="4">
<title>Xournal++ journal $date_title</title>
<page width="$width" height="$height">
<background type="solid" color="$background_color" style="$background_type"$background_config_xml/>
<layer/>
</page>
</xournal>
EOF

rm -f "$note"
if ! gzip -n -c "$xml_tmp" > "$note"; then
  notify-send -u critical "Xournal++" "Could not compress today's journal" 2>/dev/null || true
  exit 1
fi

if [[ ! -s "$note" ]]; then
  notify-send -u critical "Xournal++" "Could not create today's journal" 2>/dev/null || true
  exit 1
fi

exec xournalpp "$note"

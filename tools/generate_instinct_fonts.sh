#!/bin/zsh
set -euo pipefail

readonly FONT_SOURCE='/System/Library/Fonts/Supplemental/DIN Condensed Bold.ttf'
readonly OUTPUT_DIR='resources-semioctagon-176x176/fonts'

if [[ ! -f "$FONT_SOURCE" ]]; then
    print -u2 "Missing font source: $FONT_SOURCE"
    exit 1
fi

generate_font() {
    local output_name=$1
    local point_size=$2
    local mode=$3
    local space_advance=$4
    shift 4
    local characters=("$@")
    local temp_dir=''
    temp_dir=$(mktemp -d "/tmp/${output_name}.XXXXXX")
    local glyph_files=()
    local max_height=0

    for character in "${characters[@]}"; do
        if [[ "$character" == ' ' ]]; then
            continue
        fi

        local code=''
        code=$(printf '%d' "'$character")
        local glyph_file="$temp_dir/$code.png"
        magick -background black -fill white +antialias -font "$FONT_SOURCE" \
            -pointsize "$point_size" "label:$character" -trim +repage \
            -threshold 50% -type bilevel -depth 1 "$glyph_file"
        glyph_files+=("$glyph_file")

        local glyph_height=0
        glyph_height=$(identify -format '%h' "$glyph_file")
        if (( glyph_height > max_height )); then
            max_height=$glyph_height
        fi
    done

    local atlas_files=()
    local atlas_width=0
    for glyph_file in "${glyph_files[@]}"; do
        local glyph_width=0
        glyph_width=$(identify -format '%w' "$glyph_file")
        local gravity=south
        local glyph_code=${glyph_file:t:r}
        if [[ ("$mode" == 'time' && "$glyph_code" == '58') || \
              (("$mode" == 'metric' || "$mode" == 'metric-small') && "$glyph_code" == '45') ]]; then
            gravity=center
        fi
        magick "$glyph_file" -background black -gravity "$gravity" \
            -extent "${glyph_width}x${max_height}" -threshold 50% \
            -type bilevel -depth 1 "$glyph_file"
        atlas_files+=("$glyph_file")
        atlas_width=$((atlas_width + glyph_width))
    done

    mkdir -p "$OUTPUT_DIR"
    magick "${atlas_files[@]}" +append -threshold 50% -type bilevel \
        -depth 1 "$OUTPUT_DIR/${output_name}_0.png"

    {
        print "info face=\"DIN Condensed Bold\" size=$point_size bold=1 italic=0 charset=\"\" unicode=1 stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing=0,0 outline=0"
        print "common lineHeight=$max_height base=$max_height scaleW=$atlas_width scaleH=$max_height pages=1 packed=0 alphaChnl=1 redChnl=0 greenChnl=0 blueChnl=0"
        print "page id=0 file=\"${output_name}_0.png\""
        print "chars count=${#characters}"

        local x=0
        for character in "${characters[@]}"; do
            local code=''
            code=$(printf '%d' "'$character")
            if [[ "$character" == ' ' ]]; then
                print "char id=$code x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=$space_advance page=0 chnl=15"
                continue
            fi

            local glyph_file="$temp_dir/$code.png"
            local glyph_width=0
            glyph_width=$(identify -format '%w' "$glyph_file")
            local advance=$((glyph_width + 1))
            if [[ "$mode" == 'time' ]]; then
                if [[ "$character" == ':' ]]; then
                    advance=$(((point_size * 156 + 500) / 1000))
                else
                    advance=$(((point_size * 376 + 500) / 1000))
                fi
            elif [[ "$mode" == 'metric' ]]; then
                advance=$(((point_size * 375 + 500) / 1000))
            elif [[ "$mode" == 'metric-small' ]]; then
                advance=$(((point_size * 390 + 500) / 1000))
            fi

            local x_offset=$(((advance - glyph_width) / 2))
            if (( x_offset < 0 )); then
                x_offset=0
            fi
            print "char id=$code x=$x y=0 width=$glyph_width height=$max_height xoffset=$x_offset yoffset=0 xadvance=$advance page=0 chnl=15"
            x=$((x + glyph_width))
        done
        print 'kernings count=0'
    } > "$OUTPUT_DIR/${output_name}.fnt"

    rm -rf -- "$temp_dir"
}

generate_font din_time 72 time 0 \
    0 1 2 3 4 5 6 7 8 9 ':'
generate_font din_metric 36 metric 0 \
    0 1 2 3 4 5 6 7 8 9 '-'
generate_font din_metric_small 30 metric-small 0 \
    0 1 2 3 4 5 6 7 8 9 '-'
generate_font din_day 28 text 0 \
    A D E F G H I M N O R S T U W
generate_font din_date 22 text 5 \
    ' ' 0 1 2 3 4 5 6 7 8 9 A B C D E F G J L M N O P R S T U V Y
generate_font din_battery 24 text 0 \
    0 1 2 3 4 5 6 7 8 9 '%'

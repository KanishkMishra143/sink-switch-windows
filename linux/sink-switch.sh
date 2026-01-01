#!/bin/bash
# sink-switch - Switch audio output sink dynamically via pactl
# License: MIT
# Copyright (c) 2025 Kanishk Mishra

# ------------- OPTIONS -------------
SHOW_NOTIFY=true
SET_SINK=""
SHOW_CURRENT=false
SHOW_LIST=false
DIRECTION="next"  # can be: next, previous

# ------------- HANDLE ARGS -------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-notify)
            SHOW_NOTIFY=false
            shift
            ;;
        --list)
            SHOW_LIST=true
            shift
            ;;
        --current)
            SHOW_CURRENT=true
            shift
            ;;
        --set)
            shift
            if [[ -n "$1" ]]; then
                SET_SINK="$1"
                shift
            else
                echo "Error: --set requires a sink name argument."
                exit 1
            fi
            ;;
        --next)
            DIRECTION="next"
            shift
            ;;
        --previous)
            DIRECTION="previous"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--no-notify] [--list] [--current] [--set <sink-name>] [--next|--previous]"
            exit 1
            ;;
    esac
done

# ------------- FETCH SINKS -------------
mapfile -t sinks < <(pactl list short sinks | awk '{print $2}')
[[ ${#sinks[@]} -eq 0 ]] && {
    echo "No sinks available."
    exit 1
}

# ------------- HANDLE [--list] -------------
if $SHOW_LIST; then
    echo "Available sinks:"
    for i in "${!sinks[@]}"; do
        echo "$i: ${sinks[$i]}"
    done
    exit 0
fi

# ------------- HANDLE [--current] -------------
if $SHOW_CURRENT; then
    current_sink=$(pactl get-default-sink)
    echo "Current default sink: $current_sink"
    exit 0
fi

# ------------- HANDLE [--set <sink-name>] -------------
if [[ -n "$SET_SINK" ]]; then
    if printf '%s\n' "${sinks[@]}" | grep -Fxq "$SET_SINK"; then
        pactl set-default-sink "$SET_SINK"
        pactl list short sink-inputs | while read -r id _; do
            pactl move-sink-input "$id" "$SET_SINK"
        done

        # Label
        if [[ "$SET_SINK" == *"bluez_output"* ]]; then
            label="Bluetooth Speaker"
        elif [[ "$SET_SINK" == *"usb"* ]]; then
            label="USB Audio"
        elif [[ "$SET_SINK" == *"pci"* ]]; then
            label="Internal Audio"
        else
            label="Audio Sink"
        fi

        $SHOW_NOTIFY && notify-send "Audio Output Set" "$label ($SET_SINK)"
        exit 0
    else
        echo "Error: '$SET_SINK' is not a valid sink name."
        echo "Use --list to view available sinks."
        exit 1
    fi
fi

# ------------- DEFAULT: Cycle to next/previous sink -------------
current_sink=$(pactl get-default-sink)
index=-1
for i in "${!sinks[@]}"; do
    if [[ "${sinks[$i]}" == "$current_sink" ]]; then
        index=$i
        break
    fi
done

# Compute new index
if [[ "$DIRECTION" == "next" ]]; then
    new_index=$(( (index + 1) % ${#sinks[@]} ))
elif [[ "$DIRECTION" == "previous" ]]; then
    new_index=$(( (index - 1 + ${#sinks[@]}) % ${#sinks[@]} ))
else
    new_index=0
fi

next_sink="${sinks[$new_index]}"
pactl set-default-sink "$next_sink"

# Move active streams
pactl list short sink-inputs | while read -r id _; do
    pactl move-sink-input "$id" "$next_sink"
done

# Label
if [[ "$next_sink" == *"bluez_output"* ]]; then
    label="Bluetooth Speaker"
elif [[ "$next_sink" == *"usb"* ]]; then
    label="USB Audio"
elif [[ "$next_sink" == *"pci"* ]]; then
    label="Internal Audio"
else
    label="Audio Sink"
fi

$SHOW_NOTIFY && notify-send "Audio Output Switched" "$label ($next_sink)"

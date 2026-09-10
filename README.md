# SoltaFace

SoltaFace is a minimalist, high-contrast Garmin Connect IQ watch face designed first for the Garmin fēnix 5X.

The goal is simple: show the information that matters most, make the time immediately readable, and use the limited 240×240 MIP display efficiently.

## Features

- Large, high-contrast digital time
- Respects Garmin 12/24-hour time settings
- Seconds shown only while the watch face is active
- Weekday and date
- Notification count
- Battery percentage
- Exact daily step count
- Latest available wrist heart rate
- Graceful `--` fallback when heart-rate data is unavailable
- Dynamic font sizing for 5-digit step counts
- Optimized for the fēnix 5X 240×240 round MIP display
- No unnecessary animations, weather data, or decorative elements

## Battery-friendly seconds

SoltaFace shows seconds only while the watch face is active.

When the watch enters low-power mode:

- seconds are hidden
- the stale seconds area is cleared
- normal minute-based updates continue

When the watch face becomes active again, seconds return and update once per second using Garmin partial updates.

This keeps the face useful when actively viewed without unnecessarily refreshing the seconds continuously in low-power mode.

## Design

SoltaFace uses a simple three-zone layout:

- **Top:** weekday, date, notifications, battery
- **Center:** large HH:MM time with small seconds
- **Bottom:** steps and heart rate with compact icons

The visual hierarchy is intentionally strict:

**Time → day/date/status → activity metrics**

The interface is monochrome and optimized for quick readability on a transflective MIP display.

## Current device support

Tested and tuned for:

- Garmin fēnix 5X
- tactix Charlie
- Connect IQ API 3.1
- 240×240 round display

Support for additional Garmin devices may be added later.

## Development environment

Tested with:

- Connect IQ SDK 9.2.0
- Java 17
- Garmin Monkey C extension for Visual Studio Code

## Build

A Garmin developer signing key is required.

Example release build:

    monkeyc \
      -o bin/SoltaFace.prg \
      -f monkey.jungle \
      -y /path/to/developer_key.der \
      -d fenix5x \
      -r \
      -w

A successful build should end with:

    BUILD SUCCESSFUL

## Run in the simulator

Start the Connect IQ Simulator:

    connectiq

Then run:

    monkeydo bin/SoltaFace.prg fenix5x

## Sideload to a fēnix 5X

Connect the watch over USB.

Copy the release build to:

    GARMIN/APPS/SoltaFace.prg

For example on macOS:

    cp bin/SoltaFace.prg /Volumes/GARMIN/GARMIN/APPS/SoltaFace.prg

Safely unmount the device before disconnecting it.

## Project structure

    SoltaFace/
    ├── manifest.xml
    ├── monkey.jungle
    ├── source/
    │   ├── SoltaFaceApp.mc
    │   └── SoltaFaceView.mc
    └── resources/
        ├── fonts/
        ├── layouts/
        ├── drawables/
        └── strings/

## Status

SoltaFace is currently in active development.

The first version has been tested both in the Garmin Connect IQ Simulator and on a physical Garmin fēnix 5X.

## License

License information will be added before the first public release.
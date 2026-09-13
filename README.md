# SoltaFace

SoltaFace is a minimalist, high-contrast digital watch face for supported Garmin MIP watches. It keeps time immediately readable while presenting useful daily data without turning the display into a dashboard.

SoltaFace is available publicly in the Garmin Connect IQ Store and remains under active development.

## Features

- Large digital HH:MM time that follows the system 12/24-hour format
- Configurable seconds: **Active only** or **Always running**
- Battery-friendly default that freezes the last displayed seconds in low-power mode
- Weekday and date
- Battery percentage with a visual progress indicator
- Exact daily step count, including five-digit values
- Current/latest wrist heart rate with a graceful `--` fallback
- High-contrast typography and native resources for each supported display size
- On-watch settings on supported devices

## Compatibility

SoltaFace supports Garmin MIP displays at 176×176, 240×240, 260×260, and 280×280 resolutions.

Supported device families:

- Instinct 2 and Instinct 2X
- fēnix 5 and 5 Plus families: fēnix 5X, 5S Plus, 5 Plus, and 5X Plus
- fēnix 6 family: 6S, 6S Pro, 6, 6 Pro, and 6X Pro
- fēnix 7 family: 7S, 7S Pro, 7, 7 Pro, 7 Pro No Wi-Fi, 7X, 7X Pro, and 7X Pro No Wi-Fi
- fēnix 8 Solar MIP: 47 mm and 51 mm

Each resolution uses its own native layout and font resources rather than scaling a single design.

## Seconds and settings

The **Always-running seconds** setting is disabled by default:

- **Active only (default):** seconds update while the watch face is active, then remain visible at their last value in low-power mode.
- **Always running:** seconds continue updating in low-power mode on devices that support partial updates. This may reduce battery life.

On supported watches, open the watch-face settings on the device to change this option. The change is applied immediately.

## Build

Requirements:

- Garmin Connect IQ SDK
- Java 17
- A Garmin developer signing key

Build a release for a target product, for example:

```sh
monkeyc -o bin/SoltaFace.prg -f monkey.jungle \
  -y /path/to/developer_key.der -d fenix7 -r -w
```

Replace `fenix7` with any product ID listed in `manifest.xml`.

## Simulator

Start the Connect IQ Simulator:

```sh
connectiq
```

Then build for the chosen target and run the app:

```sh
monkeydo bin/SoltaFace.prg fenix7
```

## Sideload

1. Build `bin/SoltaFace.prg` for the exact watch model.
2. Connect the watch over USB.
3. Copy the file to `GARMIN/APPS/SoltaFace.prg` on the watch.
4. Safely eject the watch before disconnecting it.

Example on macOS:

```sh
cp bin/SoltaFace.prg /Volumes/GARMIN/GARMIN/APPS/SoltaFace.prg
```

## Project structure

```text
SoltaFace/
├── manifest.xml
├── monkey.jungle
├── source/
├── resources/
├── resources-round-260x260/
├── resources-round-280x280/
└── resources-semioctagon-176x176/
```

## Status

SoltaFace is a public Connect IQ Store app in active development. Device support, layouts, and behavior are validated in the Connect IQ Simulator and on compatible hardware.

## License

No license has been published for this repository.

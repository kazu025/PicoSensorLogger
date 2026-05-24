# Raspberry Pi Pico FreeRTOS Sensor Logger

Raspberry Pi Pico上でFreeRTOSを動作させ、ADC入力、AE-ADT7410温度センサ、AE-AQM0802 LCD、UART DMA、外部SPI Flashログ保存を組み合わせたセンサロガー実験プロジェクトです。

AE-ADT7410とAE-AQM0802はそれぞれ独立したC++クラスとして実装し、同一I2Cバス上に複数のI2Cデバイスを接続して動作確認しています。

UART経由のコマンド操作、Flashログ保存、ログ再送信、Pythonによるログ解析にも対応しています。

## Features

- Raspberry Pi Pico / RP2040 対応
- FreeRTOSによるマルチタスク構成
- UART DMAによるログ出力
- 外部SPI Flashへのログ保存
- FlashLogStorageによるリングバッファ型ログ管理
- AE-ADT7410温度センサのクラス化
- AE-AQM0802 LCDのクラス化
- 同一I2Cバス上で複数I2Cデバイスを制御
- I2C Mutexによる共有I2Cバスの排他制御
- I2Cスキャン機能による接続確認
- ADC入力ログ取得
- PythonによるCSVログ解析・グラフ化

## Hardware

使用した主なハードウェアは以下です。

| Device | Description |
|---|---|
| Raspberry Pi Pico | RP2040搭載マイコンボード |
| AE-ADT7410 | I2C接続 温度センサ |
| AE-AQM0802 | I2C接続 8文字×2行 キャラクタLCD |
| SPI Flash | 外部Flashログ保存用 |
| 可変抵抗など | ADC入力確認用 |

## I2C Devices

本プロジェクトでは、AE-ADT7410とAE-AQM0802を同じI2Cバスに接続しています。

| Device | I2C Address |
|---|---|
| AE-AQM0802 | `0x3E` |
| AE-ADT7410 | `0x48` |

Pico SDKのI2C APIでは、7bitアドレスを指定します。  
そのため、AE-AQM0802は `0x3E` を使用します。

## Wiring

I2C接続は以下の構成です。

| Raspberry Pi Pico | I2C Device |
|---|---|
| GPIO4 | SDA |
| GPIO5 | SCL |
| 3V3 | VCC |
| GND | GND |

AE-ADT7410とAE-AQM0802は、同じSDA/SCLラインに接続しています。

## I2C Scan Example

起動時にI2Cスキャンを行い、接続されたデバイスを確認できます。

```text
I2C init: i2c0 SDA=4 SCL=5 baud=100000
I2C scan start
I2C device found: 0x3E ret=1
I2C device found: 0x48 ret=1
I2C scan done
```

この結果により、以下の2つのI2C機器が認識されていることを確認できます。

```text
0x3E : AE-AQM0802 LCD
0x48 : AE-ADT7410 temperature sensor
```

## Software Structure

ディレクトリ構成は以下のようになっています。

```text
.
├── CMakeLists.txt
├── FreeRTOS-Kernel
├── debug
│   ├── logger_viewer.py
│   └── plot_sensor_log.py
├── include
│   ├── AEADT7410.h
│   ├── AQM0802.h
│   ├── AdcLoggerTask.h
│   ├── CommandTask.h
│   ├── Crc32.h
│   ├── EventId.h
│   ├── EventLogger.h
│   ├── FlashDriver.h
│   ├── FlashLogStorage.h
│   ├── FreeRTOSConfig.h
│   ├── LogPayloads.h
│   ├── LogProtocol.h
│   ├── LogTypes.h
│   ├── TemperatureTask.h
│   ├── UartDma.h
│   ├── board_i2c.h
│   ├── freertos_hooks.h
│   ├── led25.h
│   └── utility.h
├── ld.sh
├── mk.sh
└── src
    ├── AEADT7410.cpp
    ├── AQM0802.cpp
    ├── AdcLoggerTask.cpp
    ├── Crc32.cpp
    ├── EventLogger.cpp
    ├── FlashDriver.cpp
    ├── FlashLogStorage.cpp
    ├── LogEvent.cpp
    ├── TemperatureTask.cpp
    ├── UartDma.cpp
    ├── board_i2c.cpp
    ├── freertos_hooks.c
    ├── led25.c
    ├── main.cpp
    ├── task_command.cpp
    └── utility.cpp
```

## Main Components

### AEADT7410

`AEADT7410` は、AE-ADT7410温度センサを制御するためのC++クラスです。

主な役割は以下です。

- I2C経由でADT7410から温度データを読み出す
- センサの生データを摂氏温度へ変換する
- LCDやログ出力には直接依存しない

### AQM0802

`AQM0802` は、AE-AQM0802 LCDを制御するためのC++クラスです。

主な役割は以下です。

- LCD初期化
- コマンド送信
- 文字表示
- カーソル位置指定
- 8文字×2行表示への対応

### TemperatureTask

`TemperatureTask` は、FreeRTOS上で動作する温度取得・表示用タスクです。

主な処理は以下です。

- AE-ADT7410から温度を取得
- UARTログへ温度を出力
- AE-AQM0802 LCDへ温度を表示

### board_i2c

`board_i2c` は、I2C初期化処理をまとめたモジュールです。

```cpp
board_i2c_init(i2c0, 4, 5, 100 * 1000);
```

このように呼び出すことで、I2Cポート、SDA/SCLピン、通信速度をまとめて設定します。

### UartDma

`UartDma` は、UART DMAによるログ出力を担当します。

ログ出力やFlashログ再送信時に使用します。

### EventLogger

`EventLogger` は、システム内のイベントやセンサ値をログ形式で出力するためのクラスです。

UART出力とFlash保存の両方に対応しています。

### FlashLogStorage

`FlashLogStorage` は、外部SPI Flash上にログを保存するためのクラスです。

リングバッファ方式でログを管理し、古いログから順番に読み出すことができます。

## FreeRTOS Tasks

本プロジェクトでは、主に以下のFreeRTOSタスクを使用しています。

| Task | Description |
|---|---|
| Logger task | EventLoggerの送信処理 |
| ADconverter task | ADC入力の取得とログ出力 |
| Command task | UARTコマンド受付 |
| Temperature task | ADT7410温度取得とLCD表示 |

起動時には、各タスク生成後のFreeRTOSヒープ残量も表示します。

```text
Logger task : 25856
ADconverter task : 23704
Command task : 19504
Temperature task : 16328
```

## UART Commands

UART経由でFlashログ操作用のコマンドを実行できます。

```text
=== Flash Log Command ===
h       : help
s       : show status
p       : pause log generation
r       : resume log generation
a       : send all frames oldest-first
lN      : send latest N frames. example: l10, l100
e       : erase log area
=========================
```

### Command List

| Command | Description |
|---|---|
| `h` | ヘルプ表示 |
| `s` | FlashLogStorageの状態表示 |
| `p` | ログ生成を一時停止 |
| `r` | ログ生成を再開 |
| `a` | 保存済みログを古い順にすべて送信 |
| `lN` | 最新N件のログを送信 |
| `e` | Flashログ領域を消去 |

## Build

ビルドにはPico SDKとCMakeを使用します。

このプロジェクトでは、ビルド用スクリプトとして `mk.sh` を用意しています。

```bash
./mk.sh
```

ビルドが成功すると、`build` ディレクトリ内にUF2ファイルなどが生成されます。

## Flash to Raspberry Pi Pico

PicoをBOOTSELモードで接続し、生成されたUF2ファイルをPicoへコピーします。

```bash
cp build/*.uf2 /media/$USER/RPI-RP2/
```

環境によってマウント先は異なる場合があります。

## Debug Tools

`debug` ディレクトリには、UARTログ確認やCSVログ解析用のPythonスクリプトを配置しています。

| File | Description |
|---|---|
| `logger_viewer.py` | UARTログ受信・CSV保存用 |
| `plot_sensor_log.py` | センサログのグラフ化用 |

実行ログファイル `log.csv` は、環境依存・実行結果依存のため、GitHubには含めていません。

## Notes

### I2C Address Range

I2Cスキャンでは、通常の7bitアドレス範囲として `0x08` 〜 `0x77` を確認しています。

`0x00` 〜 `0x07` および `0x78` 〜 `0x7F` は予約アドレスのため、通常のスキャン対象から外しています。

### AQM0802 Initialization

AE-AQM0802は、電源投入直後やI2C初期化直後にすぐアクセスすると応答しない場合があります。

そのため、LCD初期化前に短い待ち時間を入れることで安定しやすくなります。

### FreeRTOS-Kernel

本リポジトリでは、ビルドしやすくするため `FreeRTOS-Kernel` をリポジトリ内に含めています。

Git submodule化はしていません。

## Future Work

今後の拡張候補です。

- AE-BME280への対応
- MPU-6050への対応
- LCD表示内容の切り替え
- UARTコマンドの追加
- Flashログ形式の拡張
- Python解析ツールの強化
- READMEへの波形・グラフ画像追加

## License

MIT License

外部ライブラリであるFreeRTOS-Kernel、Pico SDKなどについては、それぞれのライセンスに従ってください。

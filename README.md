# Raspberry Pi Pico FreeRTOS Sensor Logger

Raspberry Pi Pico上でFreeRTOSを動作させ、ADC入力、AE-ADT7410温度センサ、AE-AQM0802 LCD、UART DMA、外部SPI Flashログ保存を組み合わせたセンサロガー実験プロジェクトです。

AE-ADT7410とAE-AQM0802はそれぞれ独立したC++クラスとして実装し、同一I2Cバス上に複数のI2Cデバイスを接続して動作確認しています。

また、タクトスイッチによるLCD表示モード切り替えにも対応しています。  
一部の表示モードは今後の拡張用として仮表示になっています。

## 概要

このプロジェクトでは、Raspberry Pi Pico上で以下の機能を組み合わせています。

- FreeRTOSによるマルチタスク制御
- UART DMAによるログ出力
- 外部SPI Flashへのログ保存
- AE-ADT7410温度センサのI2C制御
- AE-AQM0802 LCDのI2C制御
- 複数I2Cデバイスの同一バス接続
- タクトスイッチによるLCD表示モード切り替え
- UARTコマンドによるFlashログ操作
- Pythonによるログ確認・解析

## Features

- Raspberry Pi Pico / RP2040 対応
- FreeRTOSによるタスク分離
- AE-ADT7410温度センサのクラス化
- AE-AQM0802 LCDのクラス化
- 同一I2Cバス上で複数I2Cデバイスを制御
- I2Cスキャンによるデバイス検出
- I2C Mutexによる共有バスの排他制御
- UART DMAによるログ出力
- 外部SPI Flashへのログ保存
- FlashLogStorageによるリングバッファ型ログ管理
- UARTコマンドによるログ操作
- タクトスイッチ入力によるLCD表示切り替え
- Pythonスクリプトによるログ確認・グラフ化

## Hardware

使用した主なハードウェアは以下です。

| Device | Description |
|---|---|
| Raspberry Pi Pico | RP2040搭載マイコンボード |
| AE-ADT7410 | I2C接続 温度センサ |
| AE-AQM0802 | I2C接続 8文字×2行 キャラクタLCD |
| SPI Flash | 外部Flashログ保存用 |
| Tact Switch | LCD表示モード切り替え用 |
| 可変抵抗など | ADC入力確認用 |

## I2C Devices

AE-ADT7410とAE-AQM0802を同じI2Cバスに接続しています。

| Device | I2C Address |
|---|---|
| AE-AQM0802 | `0x3E` |
| AE-ADT7410 | `0x48` |

Pico SDKのI2C APIでは、7bitアドレスを指定します。  
そのため、AE-AQM0802は `0x3E` を使用します。

資料によっては `0x7C` と表記される場合がありますが、これは8bit表記です。  
Pico SDKでは7bitアドレスの `0x3E` を指定します。

## Wiring

### I2C

I2C接続は以下の構成です。

| Raspberry Pi Pico | I2C Device |
|---|---|
| GPIO4 | SDA |
| GPIO5 | SCL |
| 3V3 | VCC |
| GND | GND |

AE-ADT7410とAE-AQM0802は、同じSDA/SCLラインに接続しています。

### Tact Switch

タクトスイッチは、LCD表示モード切り替え用に使用しています。

| Raspberry Pi Pico | Tact Switch |
|---|---|
| GPIO15 | Switch input |
| GND | Switch GND |

GPIO15は内部プルアップを有効にしています。

```text
GPIO15 ---- Tact Switch ---- GND
```

このため、入力状態は以下になります。

```text
押していない : High
押している   : Low
```

## I2C Scan Example

起動時にI2Cスキャンを行い、接続されているデバイスを確認できます。

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
│   ├── ButtonTask.h
│   ├── CommandTask.h
│   ├── Crc32.h
│   ├── DisplayMode.h
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
    ├── ButtonTask.cpp
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

- I2C経由で温度データを読み出す
- センサの生データを摂氏温度へ変換する
- LCD表示処理には直接依存しない
- ログ出力処理には直接依存しない

センサ制御のみを担当することで、他の表示器やログ出力方式にも流用しやすい構成にしています。

### AQM0802

`AQM0802` は、AE-AQM0802 LCDを制御するためのC++クラスです。

主な役割は以下です。

- LCD初期化
- コマンド送信
- データ送信
- カーソル位置指定
- 文字列表示
- 8文字×2行表示への対応

LCDクラスは、温度センサの存在を知りません。  
渡された文字列をLCDに表示することだけを担当します。

### board_i2c

`board_i2c` は、I2C初期化処理をまとめたモジュールです。

```cpp
board_i2c_init(i2c0, 4, 5, 100 * 1000);
```

このように呼び出すことで、I2Cポート、SDA/SCLピン、通信速度をまとめて設定します。

### TemperatureTask

`TemperatureTask` は、FreeRTOS上で動作する温度取得・LCD表示用タスクです。

主な処理は以下です。

- AE-ADT7410から温度を取得
- UARTログへ温度を出力
- AE-AQM0802 LCDへ温度を表示
- ButtonTaskから受け取った表示モードに応じてLCD表示を切り替える

### ButtonTask

`ButtonTask` は、タクトスイッチ入力を監視するFreeRTOSタスクです。

GPIO15に接続したタクトスイッチの押下を検出し、表示モードを切り替えます。  
切り替えた表示モードは、FreeRTOS Queueを使って `TemperatureTask` へ通知します。

```text
ButtonTask
    ↓ Queue
TemperatureTask
    ↓
AQM0802 LCD
```

### DisplayMode

`DisplayMode` は、LCD表示モードを表す列挙型です。

現在は以下のような表示モードを想定しています。

| Mode | Description |
|---|---|
| Temperature | AE-ADT7410の温度表示 |
| AdcVoltage | ADC表示モード |
| LogStatus | ログ状態表示 |
| I2cInfo | I2C機器情報表示 |

一部のモードは、今後の拡張用として仮表示です。

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
| Button task | タクトスイッチ入力監視と表示モード切り替え |

起動時には、各タスク生成後のFreeRTOSヒープ残量も表示します。

```text
Logger task : 25856
ADconverter task : 23704
Command task : 19504
Temperature task : 16328
Button task : xxxx
```

## LCD Display Mode Switching

GPIO15に接続したタクトスイッチを押すことで、LCDの表示モードを切り替えます。

現在の構成では、`ButtonTask` がタクトスイッチの押下を検出し、`DisplayMode` をQueue経由で `TemperatureTask` へ送信します。

```text
Tact Switch
    ↓ GPIO15
ButtonTask
    ↓ DisplayMode Queue
TemperatureTask
    ↓
AQM0802 LCD
```

現在の表示モード例は以下です。

| Mode | LCD Line 1 | LCD Line 2 | Status |
|---|---|---|---|
| Temperature | `TEMP` | 温度値 | 実装済み |
| AdcVoltage | `ADC` | `MODE` | 仮表示 |
| LogStatus | `LOG` | `ACTIVE` | 仮表示 |
| I2cInfo | `I2C` | `2 DEV` | 仮表示 |

`AdcVoltage`、`LogStatus`、`I2cInfo` は、今後の機能拡張を想定した仮表示です。

## BME280 LCD Display Modes

AE-BME280をI2Cバスに追加し、温度・湿度・気圧をAE-AQM0802 LCDに表示できるようにしました。

BME280は既存のI2Cバスに接続しています。

```text
I2C0 SDA : GPIO4
I2C0 SCL : GPIO5
```

現在のI2Cデバイス構成は以下です。

| Device     | I2C Address | Description                              |
| ---------- | ----------: | ---------------------------------------- |
| AE-AQM0802 |      `0x3E` | 8x2 character LCD                        |
| AE-ADT7410 |      `0x48` | Temperature sensor                       |
| AE-BME280  |      `0x76` | Temperature / Humidity / Pressure sensor |

起動時のI2Cスキャン例です。

```text
I2C scan start
I2C device found: 0x3E ret=1
I2C device found: 0x48 ret=1
I2C device found: 0x76 ret=1
I2C scan done
```

BME280のChip IDは `0x60` で確認しています。

```text
BME280 id=0x60 expect=0x60
BME280::init OK
```

測定値の出力例です。

```text
BME280 T=25.37 C H=65.66 % P=998.65 hPa
```

### LCD Display Modes

タクトスイッチを押すことで、LCD表示モードを切り替えます。

BME280用に以下の表示モードを追加しました。

| Mode            | LCD Line 1 | LCD Line 2 | Description |
| --------------- | ---------- | ---------- | ----------- |
| BME Temperature | `BME T`    | `25.37C`   | BME280の温度表示 |
| BME Humidity    | `BME H`    | `65.7%`    | BME280の湿度表示 |
| BME Pressure    | `BME P`    | `999hPa`   | BME280の気圧表示 |

既存の表示モードと合わせると、現在のLCD表示は以下のようになります。

| Mode           | Description     |
| -------------- | --------------- |
| Temperature    | AE-ADT7410の温度表示 |
| AdcVoltage     | ADC電圧表示         |
| LogStatus      | Flashログ件数表示     |
| I2cInfo        | I2Cデバイス情報表示     |
| BmeTemperature | AE-BME280の温度表示  |
| BmeHumidity    | AE-BME280の湿度表示  |
| BmePressure    | AE-BME280の気圧表示  |

### Implementation

BME280は `BME280` クラスとして実装しています。

主な役割は以下です。

* BME280のChip ID確認
* 補正係数の読み出し
* 温度・湿度・気圧のraw値取得
* 補正計算
* I2C MutexによるI2Cバス排他制御

LCD表示は `TemperatureTask` 側で行っています。
`ButtonTask` がタクトスイッチ押下を検出し、`DisplayMode` をQueue経由で `TemperatureTask` に通知します。

```text
Tact Switch
    ↓
ButtonTask
    ↓ DisplayMode Queue
TemperatureTask
    ↓
AQM0802 LCD
```

BME280もAE-AQM0802やAE-ADT7410と同じI2Cバスを共有しているため、I2Cアクセス時にはMutexを使用しています。

### Initial Measurement Wait

BME280は初期化直後にすぐ値を読むと、気圧値が不自然になる場合がありました。

そのため、BME280の測定設定後に初回測定完了待ちを入れています。

```cpp
sleep_ms(1000);
```

この待ち時間を入れることで、気圧値が自然な値になりました。

```text
Before:
BME280 T=22.04 C H=74.51 % P=713.70 hPa

After:
BME280 T=25.37 C H=65.66 % P=998.65 hPa
```

### Current Status

現在のBME280対応状況は以下です。

| Feature           | Status |
| ----------------- | ------ |
| I2C scanでBME280検出 | Done   |
| Chip ID `0x60` 確認 | Done   |
| 温度取得              | Done   |
| 湿度取得              | Done   |
| 気圧取得              | Done   |
| LCDへの温度表示         | Done   |
| LCDへの湿度表示         | Done   |
| LCDへの気圧表示         | Done   |
| タクトスイッチによる表示切り替え  | Done   |

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

### I2C Mutex

AE-ADT7410とAE-AQM0802は同じI2Cバスを共有しています。

FreeRTOS環境では、複数タスクから同時にI2Cへアクセスする可能性があるため、I2CアクセスにはMutexを使用しています。

```text
AEADT7410
AQM0802
    ↓
I2C Mutex
    ↓
I2C Bus
```

### FreeRTOS-Kernel

本リポジトリでは、ビルドしやすくするため `FreeRTOS-Kernel` をリポジトリ内に含めています。

Git submodule化はしていません。

## Current Status

現在の実装状況は以下です。

| Feature | Status |
|---|---|
| FreeRTOS起動 | 実装済み |
| UART DMAログ出力 | 実装済み |
| Flashログ保存 | 実装済み |
| UARTコマンド | 実装済み |
| AE-ADT7410温度取得 | 実装済み |
| AE-AQM0802 LCD表示 | 実装済み |
| 複数I2Cデバイス接続 | 動作確認済み |
| I2Cスキャン | 実装済み |
| タクトスイッチ入力 | 実装済み |
| LCD表示モード切り替え | 実装済み |
| ADC値のLCD表示 | 仮表示 |
| LogStatusの詳細表示 | 仮表示 |
| I2C機器情報の詳細表示 | 仮表示 |

### Future Work

今後の改善候補です。

* BME280の値を周期的にログ保存する
* BME280専用のEnvironmentTaskを作る
* LCD表示処理をDisplayTaskとして分離する
* 温度・湿度・気圧を1画面で順番に自動表示する
* Pico Wを使ってBME280の測定値をWi-Fi送信する
## License

MIT License

外部ライブラリであるFreeRTOS-Kernel、Pico SDKなどについては、それぞれのライセンスに従ってください。
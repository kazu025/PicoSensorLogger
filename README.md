# Pico FreeRTOS I2C Environment Logger

Raspberry Pi Pico と FreeRTOS を使用した、I2Cセンサ・LCD・Flashログ保存の実験プロジェクトです。

複数のI2Cデバイスをクラス化して扱い、ADC値、温度、湿度、気圧を周期的に取得し、Flash領域にログとして保存します。

## 概要

本プロジェクトでは、Raspberry Pi Pico 上で以下の機能を実装しています。

* FreeRTOSによるマルチタスク動作
* I2Cデバイスのクラス化
* ADT7410による温度取得
* BME280による温度・湿度・気圧取得
* AQM0802 LCDへの表示
* ADC値の周期取得
* Flash領域へのログ保存
* UARTコマンドによるログ操作
* Flash書き込みとI2C通信の排他制御

## 使用ハードウェア

| デバイス              | 用途          | I2Cアドレス |
| ----------------- | ----------- | ------: |
| Raspberry Pi Pico | メインMCU      |       - |
| AE-ADT7410        | 温度センサ       |  `0x48` |
| AE-BME280         | 温度・湿度・気圧センサ |  `0x76` |
| AE-AQM0802        | 8文字×2行 LCD  |  `0x3E` |

## I2C接続

本プロジェクトでは Pico の `i2c0` を使用しています。

| 信号  | Pico GPIO |
| --- | --------: |
| SDA |     GPIO4 |
| SCL |     GPIO5 |

I2C通信速度は、安定性を重視して `50kHz` に設定しています。

## 主な機能

### 1. センサデータ取得

以下のデータを周期的に取得します。

* ADC値
* ADT7410温度
* BME280温度
* BME280湿度
* BME280気圧

ログ例：

```text
ADC,3816247,1776,1768,1.425
TEMP,3816248,30.398438,OK
ENV,3820246,29.72,55.15,1007.71
```

### 2. LCD表示

AQM0802 LCDにセンサ値やログ状態を表示します。

表示モードはタクトスイッチで切り替えます。

主な表示モード：

* ADT7410温度
* ADC値
* ログ状態
* I2C情報
* BME280温度
* BME280湿度
* BME280気圧

### 3. Flashログ保存

PicoのFlash領域の一部をログ保存領域として使用します。

ログ領域：

```text
start = 0x00001000
end   = 0x00101000
size  = 1MB
```

ログは独自フレーム形式で保存し、CRCによる整合性確認を行います。

### 4. UARTコマンド

UART経由でログ操作を行えます。

```text
h       : help
s       : show status
p       : pause log generation
r       : resume log generation
a       : send all frames oldest-first
lN      : send latest N frames. example: l10, l100
e       : erase log area
```

使用例：

```text
cmd >s

=== FlashLogStorage Status ===
start   = 0x00001000
end     = 0x00101000
write   = 0x0005F5AE
oldest  = 0x00001000
newest  = 0x0005F582
count   = 8574
remain  = 662098
Paused  = yes
==============================
```

## タスク構成

本プロジェクトでは、FreeRTOSタスクを分けて処理しています。

| タスク              | 役割                  |
| ---------------- | ------------------- |
| ADC Task         | ADC値取得              |
| Temperature Task | ADT7410温度取得、LCD表示更新 |
| Environment Task | BME280温度・湿度・気圧取得    |
| Logger Task      | Flashログ保存           |
| Command Task     | UARTコマンド処理          |
| Button Task      | 表示モード切り替え           |

## I2CとFlashの排他制御

当初、Flash書き込み中にI2C通信が発生すると、I2C read timeout が発生することがありました。

そのため、以下の処理で同じ mutex を共有する設計にしました。

* `FlashLogStorage`
* `AEADT7410`
* `AQM0802`
* `BME280`

これにより、以下の排他制御を行っています。

```text
Flash書き込み中はI2C通信しない
I2C通信中はFlash書き込みしない
```

### 対象処理

Flash側：

* `sectorErase()`
* `pageProgram()`

I2C側：

* `AEADT7410::readTempRaw()`
* `AQM0802::write()`
* `BME280::readRegisters()`

## BME280の安定化

BME280では、一時的に低レベルI2C read timeoutが発生することがありました。

対策として以下を行いました。

* BME280のI2C timeoutを `50ms` に延長
* 低レベルの一時的なread失敗ログを抑制
* Environment Task側でリトライ処理
* リトライ全敗時のみエラー扱い

これにより、一時的なI2C timeoutをログ上のノイズとして扱わず、最終的に取得失敗した場合のみ検出する構成にしています。

## 動作確認結果

約1時間の連続テストを実施し、以下を確認しました。

| 項目      |   結果 |
| ------- | ---: |
| 総フレーム数  | 8574 |
| CRC NG  |    0 |
| seq gap |    0 |
| late    |    0 |
| dup     |    0 |
| ENV,ERR |    0 |
| TEMP,NG |    0 |

ログ種別の内訳：

| 種別            |   件数 |
| ------------- | ---: |
| ADC           | 3868 |
| TEMP          | 3868 |
| ENV           |  774 |
| TEMP_TASK_HWM |   64 |

確認結果：

```text
ok=8574
crc_ng=0
gap=0
late=0
dup=0
sync=8574
```

この結果から、Flashログ保存、I2C排他制御、BME280取得処理が安定して動作していることを確認しました。

## ビルド方法

Pico SDK と FreeRTOS-Kernel を使用します。

環境に合わせて `PICO_SDK_PATH` を設定してください。

```bash
export PICO_SDK_PATH=/path/to/pico-sdk
```

ビルド：

```bash
mkdir -p build
cd build
cmake ..
make -j4
```

または、プロジェクト付属のビルドスクリプトを使用します。

```bash
./mk.sh
```

## 実行方法

ビルド後に生成された `.uf2` ファイルを Pico に書き込みます。

```text
build/i2c_class.uf2
```

PicoをBOOTSELモードで接続し、UF2ファイルをコピーします。

## ログ取得

UART経由でコマンドを入力します。

全ログ送信：

```text
cmd >a
send all frames oldest-first...
send all done.
```

ログをPC側で保存し、CSV化やグラフ化に利用できます。

## 今後の課題

* ログCSV変換ツールの整理
* Pythonによるグラフ生成スクリプトの整備
* README用の構成図追加
* Note記事化
* Pico WでのWi-Fi送信対応
* LCD表示内容の改善
* Flashログ領域の管理機能強化

## 学習ポイント

このプロジェクトでは、以下を実践的に確認しました。

* FreeRTOSタスク設計
* I2Cデバイスのクラス化
* 複数I2Cデバイスの排他制御
* Flash書き込みとI2C通信の干渉対策
* センサログのFlash保存
* UARTコマンド処理
* 長時間動作試験による安定性確認

## License

This project is licensed under the MIT License.

See the [LICENSE](LICENSE) file for details.


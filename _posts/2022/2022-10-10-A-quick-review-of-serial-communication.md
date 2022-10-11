---
comments: true
date: 2022-10-10
layout: post
tags: [Tech]
title: A quick review of serial communication
---

## 1. What is serial communication?

Serial communication is a communication method that uses **one or two** transmission lines to send and receive data, **one bit at a time**.

## 2. Serial communication standards

RS-232C/RS-422A/RS-485 are EIA (Electronic Industries Association) communication standards (where "RS" means "Recommended Standard").

| Standard | Alias    | Purpose of signal lines | Timing of signal lines | Connectors |
|:--------:|:--------:|:-----------------------:|:----------------------:|:----------:|
| RS-232C  | EIA-232  | Defined                 | Defined                | **Defined** <br/>(D-sub 25-pin or D-sub 9-pin connectors) |
| RS-422A  | EIA-422A | Defined                 | Defined                | Not defined <br/>(adopt D-sub 25-pin and D-sub 9-pin) |
| RS-485   | EIA-485  | Defined                 | Defined                | Not defined <br/>(adopt D-sub 25-pin and D-sub 9-pin) |

Other notes:
- RS-422A fixes problems in RS-232C such as a short transmission distance and a slow transmission speed.
- RS-485 fixes the problem of few connected devices in RS-422A.

| Parameter              | RS-232C | RS-422A | RS-485 |
|-----------------------:|:-------:|:-------:|:------:|
| Transmission mode      | Simplex | Multi-point **simplex** | Multi-point **multiplex** |
| Max. connected devices | 1 driver<br/>1 receiver | 1 driver<br/>10 receivers | 32 drivers<br/>32 receivers |
| Max. transmission rate | 20Kbps | 10Mbps | 10Mbps |
| Max. cable length      | 15m | 1200m | 1200m |
| Operation mode         | Single-ended<br/>(unbalanced type) | Differential<br/>(balanced type) | Differential<br/>(balanced type) |
| Features               | Short distance<br/>Full-duplex<br/>1:1 connection | Long distance<br/>Full-duplex, half-duplex<br/>1:N connection | Long distance<br/>Full-duplex, half-duplex<br/>N:N connection |

## 3. Signal assignments and connectors

The figure from [1] describes the D-sub 9-pin signal assignments and signal lines that are defined in RS-232C.

![D-sub 9-pin connector](https://www.contec.com/support/basic-knowledge/daq-control/serial-communicatin/-/media/Contec/support/basic-knowledge/daq-control/serial-communicatin/images/img_serial-communicatin_05.gif)

| Pin No. | Signal Name | Description |
|:-------:|:-----------:|:------------|
| 1       | DCD | Data Carrier Detect |
| 2       | RxD | Received Data |
| 3       | TxD | Transmitted Data |
| 4       | DTR | Data Terminal Ready |
| 5       | SG | Signal Ground |
| 6       | DSR | Data Set Ready |
| 7       | RTS | Request To Send |
| 8       | CTS | Clear To Send |
| 9       | RI | Ring Indicator |
| CASE    | FG | Frame Ground |

## 4. Equipment types & connection methods

There are two types of equipment:
- **Data communication equipment (DCE)**: Equipment that passively operates such as modems, printers, and plotters.
- **Data terminal equipment (DTE)**: Equipment that actively operates such as computers.

When connecting two devices of different types together, one needs to use a **straight through** cable. When connecting two devices of the same type together, one needs to use a **crossover** cable:

| Device 1 | Device 2 | Connection        |
|:--------:|:--------:|:-----------------:|
| DCE      | DCE      | crossover         |
| DCE      | DTE      | straight through  |
| DTE      | DCE      | straight through  |
| DTE      | DTE      | crossover         |

## 5. Transmission modes

There are three transmission modes:
- Simplex
- Half Duplex
- Full Duplex

Suppose we have two devices `A` and `B` that are connected via a serial cable, then:
- **Simplex**: Only `A` can send data to `B` but `B` cannot send to `A`.
  - Examples: radio, television, printer.
- **Half Duplex**: `A` and `B` can send data to each other but **not at the same time**. When one is sending data, the other one can only receive.
  - Examples: Walkie-Talkie
- **Full Duplex**: `A` and `B` can send and receive data **at the same time**.
  - Examples: Telephone

## 6. Data transmission

In one particular transmission mode, the data transmission can be done in two ways:
- **Serial communication**: data is sent **bit by bit** using one wire.

```
A -- 11001010 --> B
```

- **Parallel communication**: data is sent by 8, 16, or 32 bits at a time.

```
   |-- 1 --> |
   |-- 1 --> |
   |-- 0 --> |
A -|-- 0 --> |-> B
   |-- 1 --> |
   |-- 0 --> |
   |-- 1 --> |
   |-- 0 --> |
```

The two ways of data transmission can be compared as follows:

| Parameter | Serial Communication | Parallel Communication |
|----------:|:--------------------:|:-----------------------|
| Transmission | One bit at one clock pulse | A chunk of data at a time |
| Number of lines | 1 | N lines for transmitting N bits |
| Communication speed | low | fast |
| Cost | Low | High |
| Situation | Preferred for long distance | Preferred for short distance |

## 7. Synchronous vs asynchronous

In synchronous transmission:
- The sender and the receiver share the same clock signal. This is usually done by accompanying the data lines with at least one additional clock line between the two devices.
- Supports high data transfer rate because data can be sent in chunks.
- Requires master/slave configuration (because the master device needs to provide the clock signal to all the receivers).

The following figure from [4] shows synchronous transmission:

![Synchronous transmission](https://circuitdigest.com/sites/default/files/inlineimages/u/Serial-communication.png)

In asynchronous transmission:
- The sender and the receiver do not use a clock to synchronize data.
- Data is sent in character or byte, so the speed is low.
- Each character or byte starts with a start bit and ends with a stop bit in order to tell the receiver where data start and end.
- There is a time delay between the communication of two bytes.
- The sender and the receiver may work at different clock frequencies.
- The timing errors can accumulate on the sender and the receiver, so synchronization bits can be inserted into the data flow in order to correct the timing errors.

The following figure from [4] shows asynchronous transmission:

![Asynchronous transmission](https://circuitdigest.com/sites/default/files/inlineimages/u/Parallel-communication.png)

## 8. Baud rate

Baud rate is the rate at which information is transferred. Its unit is **bits per second (bps)**. The user needs to set the baud rate on both the sender and the receiver.

## 9. Parity bit

[Parity bit](https://en.wikipedia.org/wiki/Parity_bit) is used to find errors in data transfer. Three different configurations are available:
- even parity check (EVEN)
- odd parity check (ODD)
- no parity check (NONE)

## References

- [1] [Serial communication Basic Knowledge -RS-232C/RS-422/RS-485](https://www.contec.com/support/basic-knowledge/daq-control/serial-communicatin/)
- [2] [What is Serial Communication? How does it work?](https://instrumentationblog.com/what-is-serial-communication/)
- [3] [The difference between straight through cable, crossover, and rollover cables](https://www.comparitech.com/net-admin/difference-between-straight-through-crossover-rollover-cables/)
- [4] [RS232 Serial Communication Protocol: Basics, Working & Specifications](https://circuitdigest.com/article/rs232-serial-communication-protocol-basics-specifications)

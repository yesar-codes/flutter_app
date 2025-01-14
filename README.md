# ESense Balance Ball

Control a ball using ESense earphones to collect targets in this fun and interactive game!

---

## Table of Contents
1. [Introduction](#introduction)
2. [Features](#features)
3. [Technologies Used](#technologies-used)
4. [Setup and Installation](#setup-and-installation)
5. [How to Play](#how-to-play)
6. [Screenshots](#screenshots)
7. [License](#license)

---

## Introduction
The ESense Balance Ball game uses ESense earphones to control a virtual ball via gyroscope data. Tilt the earphones to navigate the ball, collect green targets, and score points within a 9--seconds timer. It combines wearable technology with an engaging gameplay experience.

---

## Features
- **Gyroscope-Controlled Movement**: Utilize ESense earphones for real-time ball movement.
- **Dynamic Gameplay**: Score points by collecting green targets while avoiding boundaries.
- **1.5-Minute Timer**: Time-bound gameplay for added challenge.
- **Connection Status Indicator**: Visual feedback on Bluetooth connection to the earphones.
- **Responsive UI**: Sleek and intuitive design.

---

## Technologies Used
- **Framework**: Flutter
- **Hardware Integration**: ESense earphones
- **Libraries**:
  - `esense_flutter`: For accessing gyroscope data.
  - `permission_handler`: For Bluetooth permissions.
  - `dart:async`: For managing timers and asynchronous tasks.

---

## Setup and Installation

1. **Prerequisites**:
   - [Flutter SDK](https://flutter.dev/docs/get-started/install) installed on your machine.
   - A pair of ESense earphones.
   - Mobile device with Bluetooth support.

2. **Clone the Repository**:
   ```bash
   git clone <repository_url>
   cd <repository_directory>

